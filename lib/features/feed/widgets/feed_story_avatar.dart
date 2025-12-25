import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/models/user_model.dart';
import 'package:literature/repositories/auth_repository.dart';

/// Story Avatar Widget for story bar
class FeedStoryAvatar extends StatelessWidget {
  final String authorId;
  final int storyCount;
  final bool hasUnseen;
  final List<String> allAuthorIds;
  final int authorIndex;
  final String authorName;

  const FeedStoryAvatar({
    super.key,
    required this.authorId,
    required this.storyCount,
    required this.hasUnseen,
    required this.allAuthorIds,
    required this.authorIndex,
    required this.authorName,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hasUnseen ? Colors.white : Colors.grey[600]!;

    return GestureDetector(
      onTap: () {
        context.push(
          '/story/$authorId',
          extra: {
            'allAuthorIds': allAuthorIds,
            'startAuthorIndex': authorIndex,
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
                child: FutureBuilder<UserModel>(
                  future: context.read<AuthRepository>().getUserData(authorId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        snapshot.data!.username[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      );
                    }
                    return const HeroIcon(HeroIcons.user, color: Colors.white);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              storyCount > 0 ? authorName : '',
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
