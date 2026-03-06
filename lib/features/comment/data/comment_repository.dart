// Contract for comment CRUD and comment image upload operations.
import 'dart:typed_data';

import '../domain/comment_item.dart';

abstract class CommentRepository {
  Future<List<CommentItem>> fetchCommentsByBlog(String blogId);

  Future<String> uploadCommentImage({
    required Uint8List bytes,
    required String fileName,
  });

  Future<void> createComment({
    required String blogId,
    required String content,
    List<String> imageUrls,
  });

  Future<void> updateComment({
    required String commentId,
    required String content,
    List<String> imageUrls,
  });

  Future<void> deleteComment(String commentId);
}
