import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/widgets/shimmer_loading.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/features/feed/models/story_display_data.dart';
import 'package:literature/features/feed/widgets/feed_add_story_button.dart';
import 'package:literature/features/feed/widgets/feed_story_avatar.dart';
import 'package:literature/models/story_model.dart';
import 'package:literature/repositories/auth_repository.dart';
import 'package:literature/repositories/post_repository.dart';

/// Story Bar Widget - Horizontal scrollable story list
class FeedStoryBar extends StatelessWidget {
  const FeedStoryBar({super.key});

  @override
  Widget build(BuildContext context) {
    final postRepository = context.read<PostRepository>();
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is Authenticated ? authState.user.id : null;

    if (currentUserId == null) return const SizedBox.shrink();

    return StreamBuilder<List<StoryModel>>(
      stream: postRepository.getActiveStories(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 110,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) => const ShimmerStoryAvatar(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stories = snapshot.data!;

        // Group stories by author
        final Map<String, List<StoryModel>> storiesByAuthor = {};
        for (final story in stories) {
          if (!storiesByAuthor.containsKey(story.authorId)) {
            storiesByAuthor[story.authorId] = [];
          }
          storiesByAuthor[story.authorId]!.add(story);
        }

        // Build list of all author IDs for Instagram-style flow
        final allAuthorIds = storiesByAuthor.keys.toList();

        return Container(
          height: 110,
          padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
            itemCount: storiesByAuthor.length + 1, // +1 for "Add Story" button
            itemBuilder: (context, index) {
              if (index == 0) {
                // Add Story button (current user)
                return FeedAddStoryButton(currentUserId: currentUserId);
              }

              final authorIndex = index - 1;
              final authorId = allAuthorIds[authorIndex];
              final authorStories = storiesByAuthor[authorId]!;

              // Fetch the author's username asynchronously
              return FutureBuilder(
                future: context.read<AuthRepository>().getUserData(authorId),
                builder: (context, snapshot) {
                  final authorName = snapshot.hasData
                      ? snapshot.data!.username
                      : '';
                  return FeedStoryAvatar(
                    storyData: StoryDisplayData(
                      authorId: authorId,
                      authorName: authorName,
                      authorInitial: authorName.isNotEmpty
                          ? authorName[0].toUpperCase()
                          : '',
                      storyCount: authorStories.length,
                      allAuthorIds: allAuthorIds,
                      authorIndex: authorIndex,
                      hasUnseen: true,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
