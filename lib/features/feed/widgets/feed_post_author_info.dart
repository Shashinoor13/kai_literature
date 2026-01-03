import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/utils/category_utils.dart';
import 'package:literature/core/utils/format_utils.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/models/user_model.dart';
import 'package:literature/models/post_model.dart';
import 'package:literature/repositories/auth_repository.dart';

/// Author information section for feed posts
class FeedPostAuthorInfo extends StatefulWidget {
  final UserModel? author;
  final PostModel post;

  const FeedPostAuthorInfo({
    super.key,
    required this.author,
    required this.post,
  });

  @override
  State<FeedPostAuthorInfo> createState() => _FeedPostAuthorInfoState();
}

class _FeedPostAuthorInfoState extends State<FeedPostAuthorInfo> {
  bool _isFollowing = false;
  bool _isLoading = false;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
  }

  @override
  void didUpdateWidget(FeedPostAuthorInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.author?.id != widget.author?.id) {
      _checkIfFollowing();
    }
  }

  Future<void> _checkIfFollowing() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated || widget.author == null) return;

    // Check if viewing own post
    if (authState.user.id == widget.author!.id) {
      setState(() {
        _isCurrentUser = true;
      });
      return;
    }

    try {
      final isFollowing = await context.read<AuthRepository>().isFollowing(
            followerId: authState.user.id,
            followingId: widget.author!.id,
          );

      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _toggleFollow() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated || widget.author == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authRepo = context.read<AuthRepository>();

      if (_isFollowing) {
        await authRepo.unfollowUser(
          followerId: authState.user.id,
          followingId: widget.author!.id,
        );
      } else {
        await authRepo.followUser(
          followerId: authState.user.id,
          followingId: widget.author!.id,
        );
      }

      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _navigateToProfile() {
    if (widget.author != null) {
      context.push('/user/${widget.author!.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Badge at top
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.xs,
          ),
          decoration: BoxDecoration(
            color: CategoryUtils.getCategoryColor(widget.post.category),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.post.category.toUpperCase(),
            style: TextStyle(
              color: CategoryUtils.getCategoryTextColor(widget.post.category),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),

        // User Details
        Row(
          children: [
            GestureDetector(
              onTap: _navigateToProfile,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                backgroundImage: widget.author?.profileImageUrl.isNotEmpty == true
                    ? CachedNetworkImageProvider(widget.author!.profileImageUrl)
                    : null,
                child: widget.author?.profileImageUrl.isEmpty != false
                    ? Text(
                        widget.author?.username[0].toUpperCase() ?? '?',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username - clickable
                  GestureDetector(
                    onTap: _navigateToProfile,
                    child: Text(
                      widget.author?.username ?? 'Loading...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Follow button - only show if not current user
                  if (!_isCurrentUser && widget.author != null)
                    GestureDetector(
                      onTap: _isLoading ? null : _toggleFollow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isFollowing
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                              : Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 12,
                                width: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : Text(
                                _isFollowing ? 'Following' : 'Follow',
                                style: TextStyle(
                                  color: _isFollowing
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),

        // Date
        Text(
          FormatUtils.getTimeAgo(widget.post.createdAt),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
