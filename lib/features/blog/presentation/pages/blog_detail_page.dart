// Blog read screen with comment CRUD and profile navigation shortcuts.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/ink_card.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../comment/data/supabase_comment_repository.dart';
import '../../../comment/domain/comment_item.dart';
import '../../../profile/data/supabase_profile_repository.dart';
import '../../data/supabase_blog_repository.dart';
import '../../domain/blog.dart';

class BlogDetailPage extends StatefulWidget {
  const BlogDetailPage({super.key});

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  final _repository = SupabaseBlogRepository();
  final _commentRepository = SupabaseCommentRepository();
  final _profileRepository = SupabaseProfileRepository();
  final _picker = ImagePicker();
  final _commentController = TextEditingController();

  bool _isLoading = true;
  bool _hasChanges = false;

  bool _isLoadingComments = false;
  bool _isCommentComposerOpen = false;
  bool _isSubmittingComment = false;
  bool _isUploadingCommentImage = false;

  Blog? _blog;
  String _blogOwnerName = 'InkFrame Writer';
  String? _blogId;
  List<CommentItem> _comments = const [];
  Map<String, String> _commentUsernames = const {};
  Map<String, String?> _commentAvatarUrls = const {};
  String? _editingCommentId;
  String? _commentImageUrl;
  Uint8List? _commentImageBytes;

  static const _monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Route argument carries the blog id chosen from list/detail navigation.
    _blogId ??= ModalRoute.of(context)?.settings.arguments as String?;

    if (_blogId == null) {
      setState(() => _isLoading = false);
      return;
    }

    if (_blog == null) {
      _loadBlog();
      _loadComments();
    }
  }

  Future<void> _loadBlog() async {
    if (_blogId == null) return;

    setState(() => _isLoading = true);

    try {
      final blog = await _repository.fetchBlogById(_blogId!);
      if (blog == null) {
        if (!mounted) return;
        setState(() => _blog = null);
        return;
      }
      final ownerName = await _profileRepository.fetchDisplayNameByUserId(
        blog.authorId,
      );
      if (!mounted) return;
      setState(() {
        _blog = blog;
        _blogOwnerName = ownerName;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load blog: $error')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadComments() async {
    if (_blogId == null) return;

    setState(() => _isLoadingComments = true);

    try {
      final comments = await _commentRepository.fetchCommentsByBlog(_blogId!);
      final usernames = <String, String>{};
      final avatarUrls = <String, String?>{};
      final uniqueUserIds = comments.map((e) => e.userId).toSet();
      for (final uid in uniqueUserIds) {
        final profile = await _profileRepository.fetchProfileById(uid);
        final username = profile?.username.trim();
        usernames[uid] = (username == null || username.isEmpty)
            ? 'InkFrame Writer'
            : username;
        avatarUrls[uid] = profile?.avatarUrl;
      }
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _commentUsernames = usernames;
        _commentAvatarUrls = avatarUrls;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load comments: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  Future<void> _pickAndUploadCommentImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isUploadingCommentImage = true);

    try {
      final bytes = await picked.readAsBytes();
      final url = await _commentRepository.uploadCommentImage(
        bytes: bytes,
        fileName: picked.name,
      );

      if (!mounted) return;
      setState(() {
        _commentImageBytes = bytes;
        _commentImageUrl = url;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment image upload failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingCommentImage = false);
      }
    }
  }

  void _openCommentComposer() {
    setState(() {
      _isCommentComposerOpen = true;
      _editingCommentId = null;
      _commentController.clear();
      _commentImageUrl = null;
      _commentImageBytes = null;
    });
  }

  void _collapseCommentComposer() {
    setState(() {
      _isCommentComposerOpen = false;
      _editingCommentId = null;
      _commentController.clear();
      _commentImageUrl = null;
      _commentImageBytes = null;
      _isSubmittingComment = false;
      _isUploadingCommentImage = false;
    });
  }

  void _startInlineCommentEdit(CommentItem comment) {
    setState(() {
      _isCommentComposerOpen = false;
      _editingCommentId = comment.id;
      _commentController.text = comment.body;
      _commentImageUrl = comment.imageUrl;
      _commentImageBytes = null;
    });
  }

  void _cancelInlineCommentEdit() {
    setState(() {
      _editingCommentId = null;
      _commentController.clear();
      _commentImageUrl = null;
      _commentImageBytes = null;
      _isSubmittingComment = false;
      _isUploadingCommentImage = false;
    });
  }

  Future<void> _submitComment() async {
    if (_blogId == null) return;
    final content = _commentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment cannot be empty.')));
      return;
    }

    setState(() => _isSubmittingComment = true);

    try {
      final isEdit = _editingCommentId != null;

      // One submit button handles both create and update comment flows.
      if (_editingCommentId != null) {
        await _commentRepository.updateComment(
          commentId: _editingCommentId!,
          content: content,
          imageUrl: _commentImageUrl,
        );
      } else {
        await _commentRepository.createComment(
          blogId: _blogId!,
          content: content,
          imageUrl: _commentImageUrl,
        );
      }

      if (!mounted) return;
      if (isEdit) {
        _cancelInlineCommentEdit();
      } else {
        _collapseCommentComposer();
      }
      _loadComments();
      showAppToast(isEdit ? 'Comment updated.' : 'Comment added.');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Comment action failed: $error')));
      setState(() => _isSubmittingComment = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
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

    try {
      await _commentRepository.deleteComment(commentId);
      if (!mounted) return;
      _loadComments();
      showAppToast('Comment deleted.');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete comment failed: $error')));
    }
  }

  Future<void> _openProfileByUserId(String userId) async {
    final currentUserId = supabase.auth.currentUser?.id;
    await Navigator.pushNamed(
      context,
      userId == currentUserId ? AppRoutes.profile : AppRoutes.profileView,
      arguments: userId,
    );
    if (mounted) {
      _loadBlog();
      _loadComments();
    }
  }

  void _clearCommentImageSelection() {
    setState(() {
      _commentImageBytes = null;
      _commentImageUrl = null;
    });
  }

  String _commentImageButtonLabel() {
    if (_isUploadingCommentImage) return 'Uploading image...';
    final hasImage =
        _commentImageBytes != null ||
        (_commentImageUrl != null && _commentImageUrl!.isNotEmpty);
    return hasImage ? 'Change Image' : 'Attach Image';
  }

  void _handlePopInvoked(bool didPop) {
    if (didPop) return;
    Navigator.pop(context, _hasChanges ? true : null);
  }

  List<Widget> _buildCommentImagePickerSection({required double imageHeight}) {
    return [
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: _isUploadingCommentImage ? null : _pickAndUploadCommentImage,
        child: Text(_commentImageButtonLabel()),
      ),
      ..._buildCommentImagePreview(imageHeight: imageHeight),
    ];
  }

  List<Widget> _buildCommentImagePreview({required double imageHeight}) {
    final hasImage =
        _commentImageBytes != null ||
        (_commentImageUrl != null && _commentImageUrl!.isNotEmpty);

    if (!hasImage) return const [];

    return [
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _commentImageBytes != null
            ? Image.memory(
                _commentImageBytes!,
                height: imageHeight,
                fit: BoxFit.cover,
              )
            : Image.network(
                _commentImageUrl!,
                height: imageHeight,
                fit: BoxFit.cover,
              ),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _clearCommentImageSelection,
        child: const Text('Remove Photo'),
      ),
    ];
  }

  Future<void> _openBlogEdit() async {
    final updated = await Navigator.pushNamed(
      context,
      AppRoutes.blogCreate,
      arguments: _blog!.id,
    );
    if (updated == true) {
      _hasChanges = true;
      _loadBlog();
    }
  }

  String _formatMiniDateTime(DateTime value) {
    final localValue = value.toLocal();
    final hour = localValue.hour % 12 == 0 ? 12 : localValue.hour % 12;
    final minute = localValue.minute.toString().padLeft(2, '0');
    final suffix = localValue.hour >= 12 ? 'PM' : 'AM';
    final month = _monthNames[localValue.month - 1];
    return '$month ${localValue.day}, ${localValue.year} $hour:$minute $suffix';
  }

  Widget _buildMiniTimestampDetails({
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    final wasEdited =
        updatedAt.toLocal().difference(createdAt.toLocal()).inSeconds.abs() >=
        1;
    final text = wasEdited
        ? 'Posted at: ${_formatMiniDateTime(createdAt)} • Edited at: ${_formatMiniDateTime(updatedAt)}'
        : 'Posted at: ${_formatMiniDateTime(createdAt)}';

    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF8A817C),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildStorySection({
    required double storyTitleSize,
    required double blogTitleSize,
    required double heroImageHeight,
  }) {
    final blog = _blog!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('Story', fontSize: storyTitleSize),
        const SizedBox(height: 10),
        InkCard(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (blog.imageUrl != null && blog.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        blog.imageUrl!,
                        height: heroImageHeight,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Text(
                  blog.title,
                  style: TextStyle(
                    fontSize: blogTitleSize,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMiniTimestampDetails(
                  createdAt: blog.createdAt,
                  updatedAt: blog.updatedAt,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'By ',
                          style: TextStyle(
                            color: Color(0xFF6B6360),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        InkWell(
                          onTap: () => _openProfileByUserId(blog.authorId),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 2,
                            ),
                            child: Text(
                              _blogOwnerName,
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B6360),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Category: ${blog.category}',
                      style: const TextStyle(
                        color: Color(0xFF6B6360),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SelectableText(
                  blog.content,
                  style: const TextStyle(height: 1.75),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentComposerCard({required double commentImageHeight}) {
    return InkCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          firstChild: ElevatedButton(
            onPressed: _openCommentComposer,
            child: const Text('Write a Comment'),
          ),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Write a Comment',
                      style: GoogleFonts.bebasNeue(fontSize: 26),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: _collapseCommentComposer,
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Your Comment'),
              ),
              ..._buildCommentImagePickerSection(
                imageHeight: commentImageHeight,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmittingComment ? null : _submitComment,
                      child: Text(
                        _isSubmittingComment
                            ? 'Saving...'
                            : (_editingCommentId == null
                                  ? 'Post Comment'
                                  : 'Update Comment'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          crossFadeState: _isCommentComposerOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
        ),
      ),
    );
  }

  Widget _buildCommentsSection({
    required String? userId,
    required double commentImageHeight,
  }) {
    if (_isLoadingComments) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_comments.isEmpty) {
      return const Text('No comments yet.');
    }

    return Column(
      children: _comments.map((comment) {
        final isCommentOwner = comment.userId == userId;
        final commenterName =
            _commentUsernames[comment.userId] ?? 'InkFrame Writer';
        return _buildCommentItem(
          comment: comment,
          isCommentOwner: isCommentOwner,
          commenterName: commenterName,
          commentImageHeight: commentImageHeight,
        );
      }).toList(),
    );
  }

  Widget _buildCommentItem({
    required CommentItem comment,
    required bool isCommentOwner,
    required String commenterName,
    required double commentImageHeight,
  }) {
    final commenterAvatarUrl = _commentAvatarUrls[comment.userId];

    return InkCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _openProfileByUserId(comment.userId),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundImage:
                          (commenterAvatarUrl != null &&
                              commenterAvatarUrl.isNotEmpty)
                          ? NetworkImage(commenterAvatarUrl)
                          : null,
                      child:
                          (commenterAvatarUrl == null ||
                              commenterAvatarUrl.isEmpty)
                          ? const Icon(Icons.person, size: 12)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCommentOwner ? '$commenterName (You)' : commenterName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B6360),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            _buildMiniTimestampDetails(
              createdAt: comment.createdAt,
              updatedAt: comment.updatedAt,
            ),
            const SizedBox(height: 8),
            if (_editingCommentId == comment.id) ...[
              TextField(
                controller: _commentController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Edit Comment'),
              ),
              ..._buildCommentImagePickerSection(
                imageHeight: commentImageHeight,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmittingComment ? null : _submitComment,
                      child: Text(
                        _isSubmittingComment ? 'Saving...' : 'Update Comment',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: _cancelInlineCommentEdit,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Text(comment.body),
              if (comment.imageUrl != null && comment.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      comment.imageUrl!,
                      height: commentImageHeight,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
            if (isCommentOwner)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_editingCommentId != comment.id)
                    InkWell(
                      onTap: () => _startInlineCommentEdit(comment),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  InkWell(
                    onTap: () => _deleteComment(comment.id),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w700,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_blogId == null) {
      return const AppScaffold(
        title: 'Blog Detail',
        child: Center(child: Text('Missing blog ID.')),
      );
    }

    if (_isLoading) {
      return const AppScaffold(
        title: 'Blog Detail',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_blog == null) {
      return const AppScaffold(
        title: 'Blog Detail',
        child: Center(child: Text('Blog not found.')),
      );
    }

    final userId = supabase.auth.currentUser?.id;
    final isOwner = _blog!.authorId == userId;
    final storyTitleSize = Responsive.value(
      context,
      compact: 34,
      medium: 42,
      expanded: 46,
    );
    final blogTitleSize = Responsive.value(
      context,
      compact: 26,
      medium: 30,
      expanded: 34,
    );
    final heroImageHeight = Responsive.adaptiveImageHeight(
      context,
      compact: 180,
      compactLandscape: 130,
      medium: 240,
      expanded: 300,
    );
    final commentImageHeight = Responsive.adaptiveImageHeight(
      context,
      compact: 120,
      compactLandscape: 90,
      medium: 140,
      expanded: 160,
    );

    return AppScaffold(
      title: 'Blog Detail',
      maxContentWidth: 900,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) => _handlePopInvoked(didPop),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStorySection(
              storyTitleSize: storyTitleSize,
              blogTitleSize: blogTitleSize,
              heroImageHeight: heroImageHeight,
            ),
            const SizedBox(height: 20),
            if (isOwner)
              ElevatedButton(
                onPressed: _openBlogEdit,
                child: const Text('Edit Blog'),
              ),
            const SizedBox(height: 14),
            SectionTitle('Comments (${_comments.length})'),
            const SizedBox(height: 10),
            _buildCommentComposerCard(commentImageHeight: commentImageHeight),
            const SizedBox(height: 12),
            _buildCommentsSection(
              userId: userId,
              commentImageHeight: commentImageHeight,
            ),
          ],
        ),
      ),
    );
  }
}
