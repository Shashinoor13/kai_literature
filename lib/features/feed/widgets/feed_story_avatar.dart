import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';
// import 'package:literature/models/user_model.dart';
import 'package:literature/features/feed/models/story_display_data.dart';
// import 'package:literature/repositories/auth_repository.dart';

/// Story Avatar Widget for story bar
class FeedStoryAvatar extends StatelessWidget {
  final StoryDisplayData storyData;

  const FeedStoryAvatar({
    super.key,
    required this.storyData,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = storyData.shouldShowWhiteBorder
        ? Colors.white
        : Colors.grey[600]!;

    return GestureDetector(
      onTap: () {
        context.push(
          '/story/${storyData.authorId}',
          extra: {
            'allAuthorIds': storyData.allAuthorIds,
            'startAuthorIndex': storyData.authorIndex,
          },
        );
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
        child: Column(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white24,
                child: Text(
                  storyData.authorInitial,
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              storyData.storyCount > 0 ? storyData.authorName : '',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
