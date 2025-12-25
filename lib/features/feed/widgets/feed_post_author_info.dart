import 'package:flutter/material.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/utils/category_utils.dart';
import 'package:literature/core/utils/format_utils.dart';
import 'package:literature/models/user_model.dart';
import 'package:literature/models/post_model.dart';

/// Author information section for feed posts
class FeedPostAuthorInfo extends StatelessWidget {
  final UserModel? author;
  final PostModel post;

  const FeedPostAuthorInfo({
    super.key,
    required this.author,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Badge at top
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.xs,
          ),
          decoration: BoxDecoration(
            color: CategoryUtils.getCategoryColor(post.category),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            post.category.toUpperCase(),
            style: TextStyle(
              color: CategoryUtils.getCategoryTextColor(post.category),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),

        // User Details
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white24,
              child: Text(
                author?.username[0].toUpperCase() ?? '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                author?.username ?? 'Loading...',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),

        // Date
        Text(
          FormatUtils.getTimeAgo(post.createdAt),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
