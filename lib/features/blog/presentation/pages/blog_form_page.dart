// Create/edit blog form with category selection and optional cover image.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/routes.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/ink_card.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/utils/responsive.dart';
import '../../data/supabase_blog_repository.dart';

class BlogFormPage extends StatefulWidget {
  const BlogFormPage({super.key});

  @override
  State<BlogFormPage> createState() => _BlogFormPageState();
}

class _BlogFormPageState extends State<BlogFormPage> {
  static const _categories = ['school', 'travel', 'food', 'others'];
  static const _maxImages = 6;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _blogRepository = SupabaseBlogRepository();
  final _picker = ImagePicker();

  String _selectedCategory = 'school';
  bool _isSubmitting = false;
  bool _isUploading = false;
  bool _isLoading = false;
  bool _isDeleting = false;
  bool _isEditing = false;
  String? _blogId;
  List<String> _imageUrls = const [];
  final Map<String, Uint8List> _previewBytesByUrl = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeBlogId = ModalRoute.of(context)?.settings.arguments as String?;

    // Edit mode is triggered when a blog id is passed through route arguments.
    if (routeBlogId != null && _blogId == null) {
      setState(() {
        _isEditing = true;
        _blogId = routeBlogId;
        _isLoading = true;
      });
      _loadForEdit();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadForEdit() async {
    if (_blogId == null) return;

    try {
      final blog = await _blogRepository.fetchBlogById(_blogId!);
      final userId = supabase.auth.currentUser?.id;

      if (!mounted) return;

      if (blog == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Blog not found.')));
        Navigator.pop(context);
        return;
      }

      if (blog.authorId != userId) {
        // Defensive client-side check; server policies must still enforce ownership.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only edit your own blog.')),
        );
        Navigator.pop(context);
        return;
      }

      setState(() {
        _titleController.text = blog.title;
        _contentController.text = blog.content;
        _selectedCategory = _categories.contains(blog.category)
            ? blog.category
            : 'others';
        _imageUrls = List<String>.from(blog.imageUrls);
        _previewBytesByUrl.clear();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load blog: $error')));
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadImages() async {
    final remainingSlots = _maxImages - _imageUrls.length;
    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can upload up to 6 photos only.')),
      );
      return;
    }

    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;

    // Max 6 images.
    final selected = picked.take(remainingSlots).toList();
    if (picked.length > remainingSlots && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only $remainingSlots image(s) were added. Max is $_maxImages.',
          ),
        ),
      );
    }

    setState(() => _isUploading = true);

    try {
      final uploadedUrls = <String>[];
      final previewMap = <String, Uint8List>{};
      for (final file in selected) {
        final bytes = await file.readAsBytes();
        final publicUrl = await _blogRepository.uploadBlogImage(
          bytes: bytes,
          fileName: file.name,
        );
        uploadedUrls.add(publicUrl);
        previewMap[publicUrl] = bytes;
      }

      if (!mounted) return;
      setState(() {
        _imageUrls = [..._imageUrls, ...uploadedUrls];
        _previewBytesByUrl.addAll(previewMap);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image upload failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _submit() async {
    // Wait for uploads.
    if (_isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for image upload to finish.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (_isEditing && _blogId != null) {
        await _blogRepository.updateBlog(
          blogId: _blogId!,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          imageUrls: _imageUrls,
        );

        if (!mounted) return;
        showAppToast('Blog updated successfully.');
        Navigator.pop(context, true);
      } else {
        final createdBlogId = await _blogRepository.createBlog(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          imageUrls: _imageUrls,
        );

        if (!mounted) return;
        showAppToast('Blog created successfully.');
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.blogDetail,
          arguments: createdBlogId,
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Failed to update blog: $error'
                : 'Failed to create blog: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteBlog() async {
    if (!_isEditing || _blogId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Blog'),
        content: const Text('Are you sure you want to delete this blog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await _blogRepository.deleteBlog(_blogId!);
      if (!mounted) return;
      showAppToast('Blog deleted.');
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete blog: $error')));
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  String _imageButtonLabel() {
    if (_isUploading) return 'Uploading...';
    if (_imageUrls.isEmpty) return 'Attach Photos';
    return 'Add More Photos (${_imageUrls.length}/$_maxImages)';
  }

  bool get _hasImage => _imageUrls.isNotEmpty;

  String _submitButtonLabel() {
    if (_isSubmitting) {
      return _isEditing ? 'Updating...' : 'Creating...';
    }
    return _isEditing ? 'Update Blog' : 'Create Blog';
  }

  void _clearAllImages() {
    setState(() {
      _imageUrls = const [];
      _previewBytesByUrl.clear();
    });
  }

  void _removeImageAt(int index) {
    final selectedUrl = _imageUrls[index];
    setState(() {
      _imageUrls = List<String>.from(_imageUrls)..removeAt(index);
      _previewBytesByUrl.remove(selectedUrl);
    });
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories
          .map(
            (category) => ChoiceChip(
              label: Text(category),
              selected: _selectedCategory == category,
              onSelected: (_) => setState(() => _selectedCategory = category),
              selectedColor: const Color(0xFF00BFA6),
              backgroundColor: const Color(0xFFFFFAF2),
              side: const BorderSide(color: Color(0x1F231F20), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          )
          .toList(),
    );
  }

  List<Widget> _buildImageSection({required double previewHeight}) {
    return [
      OutlinedButton(
        onPressed: _isUploading ? null : _pickAndUploadImages,
        child: Text(_imageButtonLabel()),
      ),
      const SizedBox(height: 8),
      Text(
        'Selected: ${_imageUrls.length}/$_maxImages',
        style: const TextStyle(color: Color(0xFF6B6360)),
      ),
      if (_imageUrls.isNotEmpty) ...[
        const SizedBox(height: 10),
        if (_imageUrls.length == 1)
          SizedBox(
            height: previewHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (_previewBytesByUrl[_imageUrls.first] != null)
                      ? Image.memory(
                          _previewBytesByUrl[_imageUrls.first]!,
                          fit: BoxFit.cover,
                        )
                      : Image.network(_imageUrls.first, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    onTap: () => _removeImageAt(0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(3),
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_imageUrls.length, (index) {
              final url = _imageUrls[index];
              final previewBytes = _previewBytesByUrl[url];
              return SizedBox(
                width: previewHeight / 2,
                height: previewHeight / 2,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: previewBytes != null
                          ? Image.memory(previewBytes, fit: BoxFit.cover)
                          : Image.network(url, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => _removeImageAt(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
      ],
      if (_hasImage) ...[
        const SizedBox(height: 8),
        TextButton(
          onPressed: _clearAllImages,
          child: const Text('Remove All Photos'),
        ),
      ],
    ];
  }

  Widget _buildFormCard({required double previewHeight}) {
    return InkCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(_isEditing ? 'Edit Story' : 'Write Story'),
            const SizedBox(height: 14),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _buildCategoryChips(),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              maxLines: 10,
              decoration: const InputDecoration(labelText: 'Content'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Content is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            ..._buildImageSection(previewHeight: previewHeight),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_isSubmitting || _isDeleting || _isUploading)
                  ? null
                  : _submit,
              child: Text(_submitButtonLabel()),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: (_isSubmitting || _isDeleting || _isUploading)
                    ? null
                    : _deleteBlog,
                child: Text(
                  _isDeleting ? 'Deleting...' : 'Delete Blog',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewHeight = Responsive.adaptiveImageHeight(
      context,
      compact: 180,
      compactLandscape: 130,
      medium: 220,
      expanded: 260,
    );

    if (_isLoading) {
      return const AppScaffold(
        title: 'Edit Blog',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      title: _isEditing ? 'Edit Blog' : 'Create Blog',
      child: Form(
        key: _formKey,
        child: _buildFormCard(previewHeight: previewHeight),
      ),
    );
  }
}
