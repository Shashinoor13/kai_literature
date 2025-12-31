import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/features/post/bloc/post_bloc.dart';
import 'package:literature/features/post/bloc/post_event.dart';
import 'package:literature/features/post/bloc/post_state.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/repositories/post_repository.dart';
import 'package:literature/repositories/auth_repository.dart';
import 'package:literature/models/post_model.dart';
import 'package:literature/models/user_model.dart';

/// User Profile Screen - View any user's profile
class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  PostBloc? _postBloc;
  UserModel? _user;
  bool _isLoading = true;
  bool _isBlocked = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authRepo = context.read<AuthRepository>();
      final postRepo = context.read<PostRepository>();
      final authState = context.read<AuthBloc>().state;
      final currentUserId = authState is Authenticated ? authState.user.id : null;

      final user = await authRepo.getUserData(widget.userId);

      // Check if user is blocked
      bool isBlocked = false;
      if (currentUserId != null) {
        isBlocked = await authRepo.isUserBlocked(
          currentUserId: currentUserId,
          userId: widget.userId,
        );
      }

      if (!mounted) return;

      setState(() {
        _user = user;
        _isBlocked = isBlocked;
        _isLoading = false;
      });

      // Initialize post bloc
      _postBloc = PostBloc(
        postRepository: postRepo,
        userId: widget.userId,
      )..add(LoadUserPosts(widget.userId));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBlock() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final currentUserId = authState.user.id;
    final authRepo = context.read<AuthRepository>();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_isBlocked ? 'Unblock User' : 'Block User'),
        content: Text(
          _isBlocked
              ? 'Are you sure you want to unblock @${_user!.username}?'
              : 'Are you sure you want to block @${_user!.username}? They will no longer appear in search results.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: Text(_isBlocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {

      if (_isBlocked) {
        await authRepo.unblockUser(
          currentUserId: currentUserId,
          blockedUserId: widget.userId,
        );
      } else {
        await authRepo.blockUser(
          currentUserId: currentUserId,
          blockedUserId: widget.userId,
        );
      }

      if (!mounted) return;

      final scaffoldMessenger = ScaffoldMessenger.of(context);

      final wasBlocked = _isBlocked;

      setState(() {
        _isBlocked = !_isBlocked;
      });

      // Show success message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            !wasBlocked
                ? 'User blocked successfully'
                : 'User unblocked successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final scaffoldMessenger = ScaffoldMessenger.of(context);

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _postBloc?.close();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    // Reload user data and posts
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Text('Error: ${_error ?? 'User not found'}'),
        ),
      );
    }

    return BlocProvider.value(
      value: _postBloc!,
      child: Scaffold(
        appBar: AppBar(
          title: Text('@${_user!.username}'),
          actions: [
            PopupMenuButton<String>(
              icon: const HeroIcon(
                HeroIcons.ellipsisVertical,
                style: HeroIconStyle.outline,
              ),
              onSelected: (value) {
                if (value == 'block') {
                  _toggleBlock();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'block',
                  child: Row(
                    children: [
                      HeroIcon(
                        _isBlocked ? HeroIcons.lockOpen : HeroIcons.noSymbol,
                        style: HeroIconStyle.outline,
                        size: 20,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Text(_isBlocked ? 'Unblock User' : 'Block User'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            slivers: [
              // Profile Header
              SliverToBoxAdapter(
                child: _ProfileHeader(user: _user!),
              ),

              // Posts Grid
              BlocBuilder<PostBloc, PostState>(
                builder: (context, postState) {
                  if (postState is PostsLoaded) {
                    if (postState.posts.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HeroIcon(
                                HeroIcons.documentText,
                                size: 64,
                                color: Colors.grey,
                                style: HeroIconStyle.outline,
                              ),
                              SizedBox(height: AppSizes.md),
                              Text(
                                'No posts yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: AppSizes.xs,
                      ),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                          childAspectRatio: 1,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = postState.posts[index];
                            return _PostGridItem(post: post);
                          },
                          childCount: postState.posts.length,
                        ),
                      ),
                    );
                  }

                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile Header
class _ProfileHeader extends StatefulWidget {
  final UserModel user;

  const _ProfileHeader({required this.user});

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final authRepo = context.read<AuthRepository>();
    final isFollowing = await authRepo.isFollowing(
      followerId: authState.user.id,
      followingId: widget.user.id,
    );

    if (!mounted) return;
    setState(() => _isFollowing = isFollowing);
  }

  Future<void> _toggleFollow() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    setState(() => _isFollowLoading = true);

    try {
      final authRepo = context.read<AuthRepository>();

      if (_isFollowing) {
        await authRepo.unfollowUser(
          followerId: authState.user.id,
          followingId: widget.user.id,
        );
        if (!mounted) return;
        setState(() => _isFollowing = false);
      } else {
        await authRepo.followUser(
          followerId: authState.user.id,
          followingId: widget.user.id,
        );
        if (!mounted) return;
        setState(() => _isFollowing = true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isFollowLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostBloc, PostState>(
      builder: (context, postState) {
        final postsCount = postState is PostsLoaded ? postState.posts.length : 0;

        return Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            children: [
              // Profile Picture and Stats Row
              Row(
                children: [
                  // Profile Picture with border
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: widget.user.profileImageUrl.isNotEmpty
                          ? CachedNetworkImageProvider(
                              widget.user.profileImageUrl,
                            )
                          : null,
                      child: widget.user.profileImageUrl.isEmpty
                          ? Text(
                              widget.user.username[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSizes.lg),

                  // Stats
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Posts',
                          count: postsCount,
                        ),
                        _StatItem(
                          label: 'Followers',
                          count: widget.user.followersCount,
                        ),
                        _StatItem(
                          label: 'Following',
                          count: widget.user.followingCount,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),

              // Username and Bio
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${widget.user.username}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.user.bio.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        widget.user.bio,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Follow/Unfollow Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isFollowLoading ? null : _toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing ? Colors.white : Colors.black,
                    foregroundColor: _isFollowing ? Colors.black : Colors.white,
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: _isFollowLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isFollowing ? 'Unfollow' : 'Follow'),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Divider
              const Divider(),
            ],
          ),
        );
      },
    );
  }
}

/// Stat Item Widget
class _StatItem extends StatelessWidget {
  final String label;
  final int count;

  const _StatItem({
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Post Grid Item Widget - Instagram-style grid
class _PostGridItem extends StatelessWidget {
  final PostModel post;

  const _PostGridItem({required this.post});

  HeroIcons _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'library':
        return HeroIcons.buildingLibrary;
      case 'poem':
        return HeroIcons.bookOpen;
      case 'story':
        return HeroIcons.documentText;
      case 'book':
        return HeroIcons.bookmarkSquare;
      case 'joke':
        return HeroIcons.faceSmile;
      case 'reflection':
        return HeroIcons.lightBulb;
      case 'research':
        return HeroIcons.academicCap;
      case 'novel':
        return HeroIcons.newspaper;
      default:
        return HeroIcons.document;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/post/${post.id}'),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 0.5),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Content background
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon
                  HeroIcon(
                    _getCategoryIcon(post.category),
                    size: 20,
                    color: Colors.black54,
                    style: HeroIconStyle.outline,
                  ),
                  const SizedBox(height: 4),
                  // Content preview
                  Expanded(
                    child: Text(
                      post.content,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: Colors.black87,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Interaction overlay (bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HeroIcon(
                      HeroIcons.heart,
                      size: 12,
                      color: Colors.white,
                      style: HeroIconStyle.solid,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${post.likesCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const HeroIcon(
                      HeroIcons.chatBubbleLeft,
                      size: 12,
                      color: Colors.white,
                      style: HeroIconStyle.solid,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${post.commentsCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
