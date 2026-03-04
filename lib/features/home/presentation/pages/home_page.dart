// Main feed screen with blog listing, filters, pagination, and quick actions.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../blog/data/supabase_blog_repository.dart';
import '../../../blog/domain/blog.dart';
import '../../../blog/presentation/widgets/blog_preview_card.dart';
import '../../../profile/data/supabase_profile_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _categories = ['all', 'school', 'travel', 'food', 'others'];
  static const _pageSize = 4;

  final _blogRepository = SupabaseBlogRepository();
  final _profileRepository = SupabaseProfileRepository();

  bool _isLoadingBlogs = true;
  String _selectedCategory = 'all';
  int _currentPage = 1;
  int _totalCount = 0;
  List<Blog> _blogs = const [];
  Map<String, String> _ownerNames = const {};
  Map<String, String?> _ownerAvatarUrls = const {};
  String _welcomeName = 'InkFrame Writer';
  String? _welcomeAvatarUrl;

  int get _totalPages {
    final pages = (_totalCount / _pageSize).ceil();
    return pages == 0 ? 1 : pages;
  }

  @override
  void initState() {
    super.initState();
    _loadBlogs();
  }

  Future<void> _loadWelcomeName() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      _welcomeAvatarUrl = null;
      return;
    }

    final profile = await _profileRepository.fetchProfileById(currentUser.id);
    final profileName = profile?.username.trim().isNotEmpty == true
        ? profile!.username.trim()
        : 'Guest';
    _welcomeName = profileName;
    _welcomeAvatarUrl = profile?.avatarUrl;
  }

  Future<_OwnerDetails> _loadOwnerDetails(List<Blog> items) async {
    final ownerNames = <String, String>{};
    final ownerAvatars = <String, String?>{};
    // Fetch profile details once per unique owner to avoid duplicate requests.
    final uniqueOwners = items.map((e) => e.authorId).toSet();
    for (final ownerId in uniqueOwners) {
      final profile = await _profileRepository.fetchProfileById(ownerId);
      final username = profile?.username.trim();
      ownerNames[ownerId] = (username == null || username.isEmpty)
          ? 'Guest'
          : username;
      ownerAvatars[ownerId] = profile?.avatarUrl;
    }
    return _OwnerDetails(names: ownerNames, avatars: ownerAvatars);
  }

  Future<void> _loadBlogs() async {
    setState(() => _isLoadingBlogs = true);

    try {
      await _loadWelcomeName();

      final count = await _blogRepository.countBlogs(
        category: _selectedCategory,
      );
      final maxPage = ((count / _pageSize).ceil()).clamp(1, 1 << 20);
      if (_currentPage > maxPage) {
        _currentPage = maxPage;
      }

      final items = await _blogRepository.fetchBlogs(
        page: _currentPage,
        pageSize: _pageSize,
        category: _selectedCategory,
      );

      if (!mounted) return;
      final ownerDetails = await _loadOwnerDetails(items);

      setState(() {
        _totalCount = count;
        _blogs = items;
        _ownerNames = ownerDetails.names;
        _ownerAvatarUrls = ownerDetails.avatars;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load blogs: $error')));
    } finally {
      if (mounted) {
        setState(() => _isLoadingBlogs = false);
      }
    }
  }

  void _changeCategory(String category) {
    if (_selectedCategory == category) return;

    setState(() {
      _selectedCategory = category;
      _currentPage = 1;
    });
    _loadBlogs();
  }

  void _goToPreviousPage() {
    if (_currentPage == 1) return;
    setState(() => _currentPage--);
    _loadBlogs();
  }

  void _goToNextPage() {
    if (_currentPage >= _totalPages) return;
    setState(() => _currentPage++);
    _loadBlogs();
  }

  Future<void> _openProfileByUserId(String userId) async {
    final currentUserId = supabase.auth.currentUser?.id;
    // Reuse one helper so owner taps route correctly for self vs other users.
    await Navigator.pushNamed(
      context,
      userId == currentUserId ? AppRoutes.profile : AppRoutes.profileView,
      arguments: userId,
    );
    if (mounted) {
      _loadBlogs();
    }
  }

  Future<void> _openCreateBlog() async {
    await Navigator.pushNamed(context, AppRoutes.blogCreate);
    if (mounted) {
      _loadBlogs();
    }
  }

  Future<void> _openMyProfile() async {
    await Navigator.pushNamed(context, AppRoutes.profile);
    if (mounted) {
      _loadBlogs();
    }
  }

  Future<void> _openBlogDetail(String blogId) async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.blogDetail,
      arguments: blogId,
    );
    if (changed == true && mounted) {
      _loadBlogs();
    }
  }

  Future<void> _openEditBlog(String blogId) async {
    final updated = await Navigator.pushNamed(
      context,
      AppRoutes.blogCreate,
      arguments: blogId,
    );
    if (updated == true && mounted) {
      _loadBlogs();
    }
  }

  List<Widget> _buildHeaderSection({required double heroFontSize}) {
    return [
      Text(
        'Stories That Stick',
        style: GoogleFonts.bebasNeue(
          fontSize: heroFontSize,
          height: 0.9,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 6),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundImage:
                (_welcomeAvatarUrl != null && _welcomeAvatarUrl!.isNotEmpty)
                ? NetworkImage(_welcomeAvatarUrl!)
                : null,
            child: (_welcomeAvatarUrl == null || _welcomeAvatarUrl!.isEmpty)
                ? const Icon(Icons.person, size: 14)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            'Welcome: $_welcomeName',
            style: const TextStyle(color: Color(0xFF6B6360)),
          ),
        ],
      ),
    ];
  }

  Widget _buildQuickActions({required bool isCompact}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: isCompact ? double.infinity : 220,
          child: ElevatedButton(
            onPressed: _openCreateBlog,
            child: const Text('Create Blog'),
          ),
        ),
        SizedBox(
          width: isCompact ? double.infinity : 220,
          child: OutlinedButton(
            onPressed: _openMyProfile,
            child: const Text('Profile'),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories
            .map(
              (category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (_) => _changeCategory(category),
                  selectedColor: const Color(0xFF00BFA6),
                  backgroundColor: const Color(0xFFFFFAF2),
                  side: const BorderSide(color: Color(0x1F231F20), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  List<Widget> _buildBlogList({
    required String? currentUserId,
    required double cardImageHeight,
  }) {
    if (_isLoadingBlogs) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_blogs.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: Text('No blogs found.')),
        ),
      ];
    }

    return List.generate(_blogs.length, (index) {
      final blog = _blogs[index];
      final isOwner = blog.authorId == currentUserId;
      final ownerName = _ownerNames[blog.authorId] ?? 'InkFrame Writer';
      final ownerAvatarUrl = _ownerAvatarUrls[blog.authorId];

      return Padding(
        padding: EdgeInsets.only(bottom: index == _blogs.length - 1 ? 0 : 10),
        child: BlogPreviewCard(
          blog: blog,
          imageHeight: cardImageHeight,
          ownerName: ownerName,
          ownerAvatarUrl: ownerAvatarUrl,
          onOwnerTap: () => _openProfileByUserId(blog.authorId),
          titleFontSize: 19,
          actions: [
            OutlinedButton.icon(
              onPressed: () => _openBlogDetail(blog.id),
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: const Text('Read Blog'),
            ),
            if (isOwner)
              ElevatedButton.icon(
                onPressed: () => _openEditBlog(blog.id),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit Blog'),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildPagination({required bool isCompact}) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: isCompact ? 130 : 170,
          child: OutlinedButton(
            onPressed: _currentPage > 1 ? _goToPreviousPage : null,
            child: const Text('Previous'),
          ),
        ),
        Text('Page $_currentPage / $_totalPages'),
        SizedBox(
          width: isCompact ? 130 : 170,
          child: OutlinedButton(
            onPressed: _currentPage < _totalPages ? _goToNextPage : null,
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser?.id;
    final isCompact = Responsive.isCompact(context);
    final isLandscape = Responsive.isLandscape(context);
    final heroFontSize = Responsive.value(
      context,
      compact: isLandscape ? 34 : 40,
      medium: 50,
      expanded: 58,
    );
    final cardImageHeight = Responsive.adaptiveImageHeight(
      context,
      compact: 120,
      compactLandscape: 92,
      medium: 138,
      expanded: 148,
    );

    return AppScaffold(
      title: 'Home',
      scrollable: false,
      maxContentWidth: 1100,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ..._buildHeaderSection(heroFontSize: heroFontSize),
          const SizedBox(height: 12),
          _buildQuickActions(isCompact: isCompact),
          const SizedBox(height: 12),
          _buildCategoryFilters(),
          const SizedBox(height: 12),
          const SectionTitle('Latest Blogs'),
          const SizedBox(height: 8),
          ..._buildBlogList(
            currentUserId: currentUserId,
            cardImageHeight: cardImageHeight,
          ),
          const SizedBox(height: 8),
          _buildPagination(isCompact: isCompact),
        ],
      ),
    );
  }
}

class _OwnerDetails {
  const _OwnerDetails({required this.names, required this.avatars});

  final Map<String, String> names;
  final Map<String, String?> avatars;
}
