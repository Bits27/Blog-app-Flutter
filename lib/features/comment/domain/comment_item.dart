// Comment domain model with map-to-object conversion.
class CommentItem {
  const CommentItem({
    required this.id,
    required this.blogId,
    required this.userId,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.imageUrls = const [],
  });

  final String id;
  final String blogId;
  final String userId;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;
  final List<String> imageUrls;

  factory CommentItem.fromMap(Map<String, dynamic> map) {
    final rawImageUrls = map['image_urls'];
    final urls = rawImageUrls is List
        ? rawImageUrls
              .whereType<String>()
              .where((value) => value.trim().isNotEmpty)
              .toList()
        : <String>[];
    final legacy = map['image_url'] as String?;
    // Legacy fallback.
    final mergedUrls = urls.isNotEmpty
        ? urls
        : (legacy != null && legacy.trim().isNotEmpty ? [legacy] : <String>[]);

    return CommentItem(
      id: map['id'] as String,
      blogId: map['blog_id'] as String,
      userId: map['user_id'] as String,
      body: map['content'] as String,
      imageUrl: legacy,
      imageUrls: mergedUrls,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
