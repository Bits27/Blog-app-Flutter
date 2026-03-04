// Public writer profile screen for viewing another user's details and blogs.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/ink_card.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../blog/data/supabase_blog_repository.dart';
import '../../../blog/domain/blog.dart';
import '../../../blog/presentation/widgets/blog_preview_card.dart';
import '../../data/supabase_profile_repository.dart';

class ProfileViewPage extends StatefulWidget {
  const ProfileViewPage({super.key});

  @override
  State<ProfileViewPage> createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends State<ProfileViewPage> {
  final _blogRepository = SupabaseBlogRepository();
  final _profileRepository = SupabaseProfileRepository();

  bool _isLoading = true;
  String? _userId;
  String _username = 'Guest';
  String? _avatarUrl;
  List<Blog> _blogs = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userId ??= ModalRoute.of(context)?.settings.arguments as String?;

    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    if (_blogs.isEmpty) {
      _load();
    }
  }

  Future<void> _load() async {
    if (_userId == null) return;
    setState(() => _isLoading = true);

    try {
      final profile = await _profileRepository.fetchProfileById(_userId!);
      final blogs = await _blogRepository.fetchBlogsByUserId(_userId!);

      if (!mounted) return;
      setState(() {
        _username = profile?.username.trim().isNotEmpty == true
            ? profile!.username
            : 'Guest';
        _avatarUrl = profile?.avatarUrl;
        _blogs = blogs;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $error')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openBlogDetail(String blogId) async {
    await Navigator.pushNamed(context, AppRoutes.blogDetail, arguments: blogId);
  }

  Widget _buildWriterHeaderCard({
    required double avatarRadius,
    required double profileTitleSize,
  }) {
    return InkCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            CircleAvatar(
              radius: avatarRadius,
              backgroundImage: _avatarUrl != null
                  ? NetworkImage(_avatarUrl!)
                  : null,
              child: _avatarUrl == null
                  ? Icon(Icons.person, size: avatarRadius)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              _username.toUpperCase(),
              style: GoogleFonts.bebasNeue(
                fontSize: profileTitleSize,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_blogs.length} blogs created',
              style: const TextStyle(color: Color(0xFF6B6360)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishedBlogs({required double blogImageHeight}) {
    if (_blogs.isEmpty) {
      return const Text('This writer has not posted any blogs yet.');
    }

    return Column(
      children: _blogs.map((blog) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            child: BlogPreviewCard(
              blog: blog,
              imageHeight: blogImageHeight,
              actions: [
                OutlinedButton.icon(
                  onPressed: () => _openBlogDetail(blog.id),
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: const Text('Read Blog'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarRadius = Responsive.value(
      context,
      compact: Responsive.isLandscape(context) ? 34 : 42,
      medium: 48,
      expanded: 54,
    );
    final profileTitleSize = Responsive.value(
      context,
      compact: 28,
      medium: 34,
      expanded: 38,
    );
    final blogImageHeight = Responsive.adaptiveImageHeight(
      context,
      compact: 120,
      compactLandscape: 92,
      medium: 140,
      expanded: 160,
    );

    if (_userId == null) {
      return const AppScaffold(
        title: 'Profile',
        child: Center(child: Text('Missing user ID.')),
      );
    }

    if (_isLoading) {
      return const AppScaffold(
        title: 'Profile',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      title: 'Profile',
      maxContentWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Writer Profile'),
          const SizedBox(height: 12),
          _buildWriterHeaderCard(
            avatarRadius: avatarRadius,
            profileTitleSize: profileTitleSize,
          ),
          const SizedBox(height: 14),
          const SectionTitle('Published Blogs'),
          const SizedBox(height: 8),
          _buildPublishedBlogs(blogImageHeight: blogImageHeight),
        ],
      ),
    );
  }
}
