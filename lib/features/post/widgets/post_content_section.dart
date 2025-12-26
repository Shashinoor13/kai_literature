import 'package:flutter/material.dart';
import 'package:literature/core/constants/colors.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/widgets/paginated_text_content.dart';
import 'package:literature/models/post_model.dart';

/// Post content section displaying title and content with pagination support
class PostContentSection extends StatelessWidget {
  final PostModel post;

  const PostContentSection({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400, // Fixed height for paginated content
      child: PaginatedTextContent(
        content: post.content,
        title: post.title.isNotEmpty ? post.title : null,
        textAlign: TextAlign.start,
        maxCharsPerPage: 800,
        padding: const EdgeInsets.all(AppSizes.lg),
        contentStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 18,
          height: 1.6,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.white
              : AppColors.black,
        ),
        titleStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.white
              : AppColors.black,
        ),
      ),
    );
  }
}
