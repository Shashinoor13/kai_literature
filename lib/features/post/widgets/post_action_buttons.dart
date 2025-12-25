import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';

/// Action buttons section for post interactions (like, comment, share)
class PostActionButtons extends StatelessWidget {
  final bool isLiked;
  final VoidCallback onLikePressed;
  final VoidCallback onCommentPressed;
  final VoidCallback onSharePressed;

  const PostActionButtons({
    super.key,
    required this.isLiked,
    required this.onLikePressed,
    required this.onCommentPressed,
    required this.onSharePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onLikePressed,
              icon: HeroIcon(
                HeroIcons.heart,
                style: isLiked
                    ? HeroIconStyle.solid
                    : HeroIconStyle.outline,
                size: 20,
                color: isLiked ? Colors.red : null,
              ),
              label: Text(isLiked ? 'Liked' : 'Like'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.md,
                ),
                side: BorderSide(
                  color: isLiked
                      ? Colors.red
                      : Theme.of(context).dividerColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCommentPressed,
              icon: const HeroIcon(
                HeroIcons.chatBubbleLeft,
                style: HeroIconStyle.outline,
                size: 20,
              ),
              label: const Text('Comment'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.md,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          OutlinedButton(
            onPressed: onSharePressed,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(AppSizes.md),
              minimumSize: const Size(48, 48),
            ),
            child: const HeroIcon(
              HeroIcons.share,
              style: HeroIconStyle.outline,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
