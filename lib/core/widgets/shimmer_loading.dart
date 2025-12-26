import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:literature/core/constants/colors.dart';
import 'package:literature/core/constants/sizes.dart';

/// Base shimmer widget following app's monochrome design system
class ShimmerLoading extends StatelessWidget {
  final Widget child;

  const ShimmerLoading({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray100,
      highlightColor: AppColors.white,
      child: child,
    );
  }
}

/// Shimmer placeholder for a rectangular container
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppSizes.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer placeholder for circular avatar
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Shimmer loading for post cards in feed
class ShimmerPostCard extends StatelessWidget {
  const ShimmerPostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.black,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: ShimmerLoading(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title placeholder
              ShimmerBox(
                width: MediaQuery.of(context).size.width * 0.7,
                height: 24,
              ),
              const SizedBox(height: AppSizes.md),
              // Content placeholders
              ...List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading for story avatars
class ShimmerStoryAvatar extends StatelessWidget {
  const ShimmerStoryAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
      child: ShimmerLoading(
        child: Column(
          children: [
            const ShimmerCircle(size: 65),
            const SizedBox(height: AppSizes.xs),
            ShimmerBox(
              width: 50,
              height: 10,
              borderRadius: AppSizes.radiusSm,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading for list items (posts, comments, etc.)
class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.gray300),
      ),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerCircle(size: 40),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: 120,
                        height: 14,
                        borderRadius: AppSizes.radiusSm,
                      ),
                      const SizedBox(height: 4),
                      ShimmerBox(
                        width: 80,
                        height: 12,
                        borderRadius: AppSizes.radiusSm,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            ShimmerBox(
              width: double.infinity,
              height: 16,
              borderRadius: AppSizes.radiusSm,
            ),
            const SizedBox(height: AppSizes.xs),
            ShimmerBox(
              width: double.infinity,
              height: 16,
              borderRadius: AppSizes.radiusSm,
            ),
            const SizedBox(height: AppSizes.xs),
            ShimmerBox(
              width: 200,
              height: 16,
              borderRadius: AppSizes.radiusSm,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading for profile header
class ShimmerProfileHeader extends StatelessWidget {
  const ShimmerProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          children: [
            const ShimmerCircle(size: 100),
            const SizedBox(height: AppSizes.md),
            ShimmerBox(
              width: 150,
              height: 20,
              borderRadius: AppSizes.radiusSm,
            ),
            const SizedBox(height: AppSizes.xs),
            ShimmerBox(
              width: 200,
              height: 14,
              borderRadius: AppSizes.radiusSm,
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatShimmer(),
                _buildStatShimmer(),
                _buildStatShimmer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatShimmer() {
    return Column(
      children: [
        ShimmerBox(
          width: 50,
          height: 20,
          borderRadius: AppSizes.radiusSm,
        ),
        const SizedBox(height: 4),
        ShimmerBox(
          width: 60,
          height: 12,
          borderRadius: AppSizes.radiusSm,
        ),
      ],
    );
  }
}

/// Generic shimmer loading indicator to replace CircularProgressIndicator
class ShimmerLoader extends StatelessWidget {
  final double size;

  const ShimmerLoader({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ShimmerLoading(
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
