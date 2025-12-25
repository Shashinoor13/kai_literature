import 'package:flutter/material.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/models/user_model.dart';
import 'package:literature/models/post_model.dart';

/// Author header component for post detail screen
class PostAuthorHeader extends StatelessWidget {
  final UserModel? author;
  final PostModel post;
  final String Function(DateTime) getTimeAgo;
  final Color Function(String) getCategoryColor;
  final Color Function(String) getCategoryTextColor;

  const PostAuthorHeader({
    super.key,
    required this.author,
    required this.post,
    required this.getTimeAgo,
    required this.getCategoryColor,
    required this.getCategoryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[300],
            child: Text(
              author?.username[0].toUpperCase() ?? '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author?.username ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  getTimeAgo(post.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm,
              vertical: AppSizes.xs,
            ),
            decoration: BoxDecoration(
              color: getCategoryColor(post.category),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              post.category.toUpperCase(),
              style: TextStyle(
                color: getCategoryTextColor(post.category),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
