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
  });

  final String id;
  final String blogId;
  final String userId;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;

  factory CommentItem.fromMap(Map<String, dynamic> map) {
    return CommentItem(
      id: map['id'] as String,
      blogId: map['blog_id'] as String,
      userId: map['user_id'] as String,
      body: map['content'] as String,
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
