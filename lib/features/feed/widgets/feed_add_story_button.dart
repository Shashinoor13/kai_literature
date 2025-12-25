import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/models/user_model.dart';
import 'package:literature/repositories/auth_repository.dart';

/// Add Story Button for story bar
class FeedAddStoryButton extends StatelessWidget {
  final String currentUserId;

  const FeedAddStoryButton({
    super.key,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/create'),
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
        child: Column(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white24,
                    child: FutureBuilder<UserModel>(
                      future: context.read<AuthRepository>().getUserData(
                            currentUserId,
                          ),
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
                        return const HeroIcon(
                          HeroIcons.user,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: const HeroIcon(
                        HeroIcons.plus,
                        size: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            const Text(
              'Your Story',
              style: TextStyle(fontSize: 12, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
