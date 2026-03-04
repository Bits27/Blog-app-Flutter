// Contract for blog CRUD, pagination, and blog image upload.
import 'dart:typed_data';

import '../domain/blog.dart';

abstract class BlogRepository {
  Future<Blog?> fetchBlogById(String blogId);

  Future<List<Blog>> fetchBlogs({
    required int page,
    required int pageSize,
    required String category,
  });

  Future<int> countBlogs({required String category});

  Future<List<Blog>> fetchBlogsByUserId(String userId);

  Future<String> uploadBlogImage({
    required Uint8List bytes,
    required String fileName,
  });

  Future<String> createBlog({
    required String title,
    required String content,
    required String category,
    String? imageUrl,
  });
  Future<void> updateBlog({
    required String blogId,
    required String title,
    required String content,
    required String category,
    String? imageUrl,
  });
  Future<void> deleteBlog(String blogId);
}
