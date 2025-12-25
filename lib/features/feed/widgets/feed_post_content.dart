import 'package:flutter/material.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/models/post_model.dart';

/// Post content section for feed posts (centered, scrollable)
class FeedPostContent extends StatelessWidget {
  final PostModel post;

  const FeedPostContent({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.xl,
          vertical: AppSizes.xl * 3,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (post.title.isNotEmpty) ...[
              Text(
                post.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.lg),
            ],
            Text(
              post.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
