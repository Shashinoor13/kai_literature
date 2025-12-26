import 'package:flutter/material.dart';
import 'package:literature/core/constants/colors.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/widgets/paginated_text_content.dart';
import 'package:literature/models/post_model.dart';

/// Post content section for feed posts (centered, paginated for long content)
class FeedPostContent extends StatelessWidget {
  final PostModel post;

  const FeedPostContent({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PaginatedTextContent(
        content: post.content,
        title: post.title.isNotEmpty ? post.title : null,
        textAlign: TextAlign.center,
        maxCharsPerPage: 600, // Adjust based on screen size
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.xl,
          vertical: AppSizes.xl * 3,
        ),
        contentStyle: const TextStyle(
          color: AppColors.white,
          fontSize: 22,
          height: 1.6,
        ),
        titleStyle: const TextStyle(
          color: AppColors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
