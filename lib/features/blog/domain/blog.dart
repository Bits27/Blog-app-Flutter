// Blog domain model with JSON/map conversion helpers.
class Blog {
  const Blog({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.authorId,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.imageUrls = const [],
  });

  final String id;
  final String title;
  final String content;
  final String category;
  final String authorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;
  final List<String> imageUrls;

  String? get primaryImageUrl {
    if (imageUrls.isNotEmpty) return imageUrls.first;
    return imageUrl;
  }

  factory Blog.fromMap(Map<String, dynamic> map) {
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

    return Blog(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String,
      authorId: map['user_id'] as String,
      imageUrl: legacy,
      imageUrls: mergedUrls,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
