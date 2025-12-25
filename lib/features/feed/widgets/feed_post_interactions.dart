import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/utils/format_utils.dart';
import 'package:literature/features/feed/widgets/feed_interaction_button.dart';

/// Interaction buttons column for feed posts
class FeedPostInteractions extends StatelessWidget {
  final bool isLiked;
  final bool isFavorited;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onShareTap;
  final VoidCallback onOptionsTap;
  final Animation<double>? likeAnimation;

  const FeedPostInteractions({
    super.key,
    required this.isLiked,
    required this.isFavorited,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onFavoriteTap,
    required this.onShareTap,
    required this.onOptionsTap,
    this.likeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Like Button
        FeedInteractionButton(
          icon: HeroIcons.heart,
          iconStyle: isLiked ? HeroIconStyle.solid : HeroIconStyle.outline,
          count: FormatUtils.formatCount(likesCount),
          onTap: onLikeTap,
          useGradient: isLiked,
          scale: likeAnimation,
        ),
        const SizedBox(height: AppSizes.lg),

        // Comment Button
        FeedInteractionButton(
          icon: HeroIcons.chatBubbleLeft,
          iconStyle: HeroIconStyle.outline,
          count: FormatUtils.formatCount(commentsCount),
          onTap: onCommentTap,
        ),
        const SizedBox(height: AppSizes.lg),

        // Favorite Button
        FeedInteractionButton(
          icon: HeroIcons.bookmark,
          iconStyle: isFavorited ? HeroIconStyle.solid : HeroIconStyle.outline,
          count: '',
          onTap: onFavoriteTap,
        ),
        const SizedBox(height: AppSizes.lg),

        // Share Button
        FeedInteractionButton(
          icon: HeroIcons.share,
          iconStyle: HeroIconStyle.outline,
          count: FormatUtils.formatCount(sharesCount),
          onTap: onShareTap,
        ),
        const SizedBox(height: AppSizes.lg),

        // Options Menu
        FeedInteractionButton(
          icon: HeroIcons.ellipsisVertical,
          iconStyle: HeroIconStyle.outline,
          count: '',
          onTap: onOptionsTap,
        ),
      ],
    );
  }
}
