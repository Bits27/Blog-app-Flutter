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
  String? _imageUrl;
  Uint8List? _pickedBytes;

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
        _imageUrl = blog.imageUrl;
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

  Future<void> _pickAndUploadImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await picked.readAsBytes();
      final publicUrl = await _blogRepository.uploadBlogImage(
        bytes: bytes,
        fileName: picked.name,
      );

      if (!mounted) return;
      setState(() {
        _pickedBytes = bytes;
        _imageUrl = publicUrl;
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (_isEditing && _blogId != null) {
        await _blogRepository.updateBlog(
          blogId: _blogId!,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          imageUrl: _imageUrl,
        );

        if (!mounted) return;
        showAppToast('Blog updated successfully.');
        Navigator.pop(context, true);
      } else {
        final createdBlogId = await _blogRepository.createBlog(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          imageUrl: _imageUrl,
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
    final hasImage =
        _pickedBytes != null || (_imageUrl != null && _imageUrl!.isNotEmpty);
    return hasImage ? 'Change Photo' : 'Attach Photo';
  }

  bool get _hasImage =>
      _pickedBytes != null || (_imageUrl != null && _imageUrl!.isNotEmpty);

  String _submitButtonLabel() {
    if (_isSubmitting) {
      return _isEditing ? 'Updating...' : 'Creating...';
    }
    return _isEditing ? 'Update Blog' : 'Create Blog';
  }

  void _clearImage() {
    setState(() {
      _pickedBytes = null;
      _imageUrl = null;
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
        onPressed: _isUploading ? null : _pickAndUploadImage,
        child: Text(_imageButtonLabel()),
      ),
      if (_pickedBytes != null) ...[
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            _pickedBytes!,
            height: previewHeight,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ] else if (_imageUrl != null && _imageUrl!.isNotEmpty) ...[
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _imageUrl!,
            height: previewHeight,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ],
      if (_hasImage) ...[
        const SizedBox(height: 8),
        TextButton(onPressed: _clearImage, child: const Text('Remove Photo')),
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
              onPressed: (_isSubmitting || _isDeleting) ? null : _submit,
              child: Text(_submitButtonLabel()),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: (_isSubmitting || _isDeleting) ? null : _deleteBlog,
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
