// Signed-in user's profile screen with own-blog management actions.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/ink_card.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../auth/data/supabase_auth_repository.dart';
import '../../../blog/data/supabase_blog_repository.dart';
import '../../../blog/domain/blog.dart';
import '../../../blog/presentation/widgets/blog_preview_card.dart';
import '../../data/supabase_profile_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _repository = SupabaseProfileRepository();
  final _authRepository = SupabaseAuthRepository();
  final _blogRepository = SupabaseBlogRepository();

  bool _isLoading = true;
  bool _isLoggingOut = false;
  bool _isDeletingProfile = false;

  String _username = '';
  String _email = '-';
  String _createdAtText = '-';
  int _blogsCreated = 0;
  String? _avatarUrl;
  List<Blog> _myBlogs = const [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _repository.fetchMyProfile();
      final currentUser = supabase.auth.currentUser;
      final blogs = currentUser == null
          ? <Blog>[]
          : await _blogRepository.fetchBlogsByUserId(currentUser.id);

      setState(() {
        _username =
            profile?.username ??
            (currentUser?.userMetadata?['username'] as String? ?? '');
        _avatarUrl = profile?.avatarUrl;
        _email = currentUser?.email ?? '-';
        _createdAtText = _formatDate(currentUser?.createdAt);
        _blogsCreated = blogs.length;
        _myBlogs = blogs;
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

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final date = DateTime.tryParse(raw);
    if (date == null) return '-';

    const months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _goToEditProfile() async {
    final updated = await Navigator.pushNamed(context, AppRoutes.profileEdit);
    if (updated == true && mounted) {
      _loadProfile();
    }
  }

  Future<void> _openBlogDetail(String blogId) async {
    await Navigator.pushNamed(context, AppRoutes.blogDetail, arguments: blogId);
  }

  Future<void> _openBlogEdit(String blogId) async {
    final updated = await Navigator.pushNamed(
      context,
      AppRoutes.blogCreate,
      arguments: blogId,
    );
    if (updated == true && mounted) {
      _loadProfile();
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);

    try {
      await _authRepository.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  Future<void> _deleteProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: const Text(
          'Delete your profile record? You can still sign up/login again.',
        ),
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

    setState(() => _isDeletingProfile = true);

    try {
      await _repository.deleteMyProfile();
      await _authRepository.signOut();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete profile failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _isDeletingProfile = false);
      }
    }
  }

  Widget _buildProfileHeaderCard({
    required double avatarRadius,
    required double profileTitleSize,
  }) {
    return InkCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundImage: _avatarUrl != null
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: _avatarUrl == null
                    ? Icon(Icons.person, size: avatarRadius)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _username.isEmpty ? 'INKFRAME WRITER' : _username.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.bebasNeue(
                fontSize: profileTitleSize,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            _buildProfileStatsCard(),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _goToEditProfile,
              child: const Text('Edit Profile'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _isLoggingOut ? null : _logout,
              child: Text(_isLoggingOut ? 'Logging out...' : 'Logout'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isDeletingProfile ? null : _deleteProfile,
              child: Text(
                _isDeletingProfile ? 'Deleting profile...' : 'Delete Profile',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStatsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1F231F20), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Email', _email),
          const SizedBox(height: 8),
          _detailRow('Created', _createdAtText),
          const SizedBox(height: 8),
          _detailRow('Blogs', _blogsCreated.toString()),
        ],
      ),
    );
  }

  Widget _buildMyBlogsSection({required double blogImageHeight}) {
    if (_myBlogs.isEmpty) {
      return const Text('You have not posted any blogs yet.');
    }

    return Column(
      children: _myBlogs.map((blog) {
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
                ElevatedButton.icon(
                  onPressed: () => _openBlogEdit(blog.id),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit Blog'),
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

    if (_isLoading) {
      return const AppScaffold(
        title: 'Profile',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      title: 'Profile',
      maxContentWidth: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Profile'),
          const SizedBox(height: 12),
          _buildProfileHeaderCard(
            avatarRadius: avatarRadius,
            profileTitleSize: profileTitleSize,
          ),
          const SizedBox(height: 14),
          const SectionTitle('Your Blogs'),
          const SizedBox(height: 8),
          _buildMyBlogsSection(blogImageHeight: blogImageHeight),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 340;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6B6360),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(value),
            ],
          );
        }

        return Row(
          children: [
            SizedBox(
              width: 84,
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6B6360),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(child: Text(value)),
          ],
        );
      },
    );
  }
}
