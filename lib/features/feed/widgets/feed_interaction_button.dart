import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';

/// Interaction button with count for feed posts (like, comment, bookmark, share)
class FeedInteractionButton extends StatelessWidget {
  final HeroIcons icon;
  final HeroIconStyle iconStyle;
  final String count;
  final VoidCallback onTap;
  final bool useGradient;
  final Animation<double>? scale;

  const FeedInteractionButton({
    super.key,
    required this.icon,
    required this.iconStyle,
    required this.count,
    required this.onTap,
    this.useGradient = false,
    this.scale,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = HeroIcon(
      icon,
      style: iconStyle,
      size: 32,
      color: Colors.white,
    );

    if (useGradient) {
      iconWidget = ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Color(0xFFFF0080), // Pink
            Color(0xFFFF0000), // Red
            Color(0xFF7928CA), // Purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: iconWidget,
      );
    }

    if (scale != null) {
      iconWidget = AnimatedBuilder(
        animation: scale!,
        builder: (context, child) {
          return Transform.scale(scale: scale!.value, child: child);
        },
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          iconWidget,
          if (count.isNotEmpty) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
