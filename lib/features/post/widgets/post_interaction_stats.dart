import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/features/post/widgets/post_stat_item.dart';

/// Interaction statistics section for post detail screen
class PostInteractionStats extends StatelessWidget {
  final int likesCount;
  final int commentsCount;
  final int sharesCount;

  const PostInteractionStats({
    super.key,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.md,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          PostStatItem(
            icon: HeroIcons.heart,
            count: likesCount,
            label: 'Likes',
          ),
          const SizedBox(width: AppSizes.xl),
          PostStatItem(
            icon: HeroIcons.chatBubbleLeft,
            count: commentsCount,
            label: 'Comments',
          ),
          const SizedBox(width: AppSizes.xl),
          PostStatItem(
            icon: HeroIcons.share,
            count: sharesCount,
            label: 'Shares',
          ),
        ],
      ),
    );
  }
}
