// Reusable compact blog card used across home and profile pages.
import 'package:flutter/material.dart';

import '../../../../shared/widgets/ink_card.dart';
import '../../domain/blog.dart';

class BlogPreviewCard extends StatelessWidget {
  const BlogPreviewCard({
    required this.blog,
    required this.imageHeight,
    this.ownerName,
    this.ownerAvatarUrl,
    this.onOwnerTap,
    this.actions = const [],
    this.titleFontSize = 18,
    super.key,
  });

  final Blog blog;
  final double imageHeight;
  final String? ownerName;
  final String? ownerAvatarUrl;
  final VoidCallback? onOwnerTap;
  final List<Widget> actions;
  final double titleFontSize;

  bool get _showOwner => ownerName != null;

  @override
  Widget build(BuildContext context) {
    return InkCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (blog.imageUrl != null && blog.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    blog.imageUrl!,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Text(
              blog.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: titleFontSize,
              ),
            ),
            const SizedBox(height: 4),
            if (_showOwner)
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundImage:
                        (ownerAvatarUrl != null && ownerAvatarUrl!.isNotEmpty)
                        ? NetworkImage(ownerAvatarUrl!)
                        : null,
                    child: (ownerAvatarUrl == null || ownerAvatarUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 12)
                        : null,
                  ),
                  const SizedBox(width: 6),
                  const Text('By '),
                  InkWell(
                    onTap: onOwnerTap,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 2,
                      ),
                      child: Text(
                        ownerName!,
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (_showOwner) const SizedBox(height: 2),
            Text('Category: ${blog.category}'),
            const SizedBox(height: 6),
            Text(blog.content, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}
