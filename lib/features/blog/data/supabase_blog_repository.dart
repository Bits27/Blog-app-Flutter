// Supabase implementation for blog queries, writes, and storage uploads.
import 'dart:typed_data';

import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/blog.dart';
import 'blog_repository.dart';

class SupabaseBlogRepository implements BlogRepository {
  static const _table = 'blogs';
  static const _bucket = 'blog_images';

  @override
  Future<Blog?> fetchBlogById(String blogId) async {
    final row = await supabase
        .from(_table)
        .select()
        .eq('id', blogId)
        .maybeSingle();
    if (row == null) return null;
    return Blog.fromMap(row);
  }

  @override
  Future<List<Blog>> fetchBlogs({
    required int page,
    required int pageSize,
    required String category,
  }) async {
    final start = (page - 1) * pageSize;
    final end = start + pageSize - 1;

    final rows = await (category == 'all'
        ? supabase
              .from(_table)
              .select()
              .order('created_at', ascending: false)
              .range(start, end)
        : supabase
              .from(_table)
              .select()
              .eq('category', category)
              .order('created_at', ascending: false)
              .range(start, end));
    return rows.map((row) => Blog.fromMap(row)).toList();
  }

  @override
  Future<int> countBlogs({required String category}) async {
    final rows = await (category == 'all'
        ? supabase.from(_table).select('id')
        : supabase.from(_table).select('id').eq('category', category));
    return rows.length;
  }

  @override
  Future<List<Blog>> fetchBlogsByUserId(String userId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.map((row) => Blog.fromMap(row)).toList();
  }

  @override
  Future<String> uploadBlogImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to upload blog image.');
    }

    final extension = fileName.toLowerCase().split('.').last;
    final path =
        '${user.id}/blog_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await supabase.storage.from(_bucket).uploadBinary(path, bytes);
    return supabase.storage.from(_bucket).getPublicUrl(path);
  }

  @override
  Future<String> createBlog({
    required String title,
    required String content,
    required String category,
    List<String> imageUrls = const [],
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to create a blog.');
    }

    // Keep legacy cover.
    final primaryImageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

    final row = await supabase
        .from(_table)
        .insert({
          'user_id': user.id,
          'title': title,
          'content': content,
          'category': category,
          'image_url': primaryImageUrl,
          'image_urls': imageUrls,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    return row['id'] as String;
  }

  @override
  Future<void> updateBlog({
    required String blogId,
    required String title,
    required String content,
    required String category,
    List<String> imageUrls = const [],
  }) async {
    // Keep legacy cover.
    final primaryImageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

    await supabase
        .from(_table)
        .update({
          'title': title,
          'content': content,
          'category': category,
          'image_url': primaryImageUrl,
          'image_urls': imageUrls,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', blogId);
  }

  @override
  Future<void> deleteBlog(String blogId) async {
    await supabase.from(_table).delete().eq('id', blogId);
  }
}
