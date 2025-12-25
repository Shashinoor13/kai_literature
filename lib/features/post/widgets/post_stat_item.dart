import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';

/// Stat item widget for displaying interaction counts (likes, comments, shares)
class PostStatItem extends StatelessWidget {
  final HeroIcons icon;
  final int count;
  final String label;

  const PostStatItem({
    super.key,
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HeroIcon(
          icon,
          style: HeroIconStyle.outline,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: AppSizes.xs),
        Text(
          '$count',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }
}
