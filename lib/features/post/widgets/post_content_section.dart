import 'package:flutter/material.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/models/post_model.dart';

/// Post content section displaying title and content
class PostContentSection extends StatelessWidget {
  final PostModel post;

  const PostContentSection({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.title.isNotEmpty) ...[
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.md),
          ],
          Text(
            post.content,
            style: const TextStyle(fontSize: 18, height: 1.6),
          ),
        ],
      ),
    );
  }
}
