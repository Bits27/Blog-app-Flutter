// Supabase implementation for comment data and image storage handling.
import 'dart:typed_data';

import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/comment_item.dart';
import 'comment_repository.dart';

class SupabaseCommentRepository implements CommentRepository {
  static const _table = 'comments';
  static const _bucket = 'comment_images';

  @override
  Future<List<CommentItem>> fetchCommentsByBlog(String blogId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('blog_id', blogId)
        .order('created_at', ascending: true);

    return rows.map((row) => CommentItem.fromMap(row)).toList();
  }

  @override
  Future<String> uploadCommentImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = supabase.auth.currentUser;

    final extension = fileName.toLowerCase().split('.').last;
    final path =
        '${user!.id}/comment_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await supabase.storage.from(_bucket).uploadBinary(path, bytes);
    return supabase.storage.from(_bucket).getPublicUrl(path);
  }

  @override
  Future<void> createComment({
    required String blogId,
    required String content,
    String? imageUrl,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to comment.');
    }

    await supabase.from(_table).insert({
      'blog_id': blogId,
      'user_id': user.id,
      'content': content,
      'image_url': imageUrl,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateComment({
    required String commentId,
    required String content,
    String? imageUrl,
  }) async {
    await supabase
        .from(_table)
        .update({
          'content': content,
          'image_url': imageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', commentId);
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await supabase.from(_table).delete().eq('id', commentId);
  }
}
