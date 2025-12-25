import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  bool _isBlockActionLoading = false;
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

    setState(() => _isBlockActionLoading = true);

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
        _isBlockActionLoading = false;
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

      setState(() => _isBlockActionLoading = false);

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
            if (_isBlockActionLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: Icon(_isBlocked ? Icons.block : Icons.block_outlined),
                tooltip: _isBlocked ? 'Unblock' : 'Block',
                onPressed: _toggleBlock,
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

              // Posts List
              BlocBuilder<PostBloc, PostState>(
                builder: (context, postState) {
                  if (postState is PostsLoaded) {
                    if (postState.posts.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'No posts yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.all(AppSizes.screenPadding),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = postState.posts[index];
                            return _PostListItem(post: post);
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
                  // Profile Picture
                  CircleAvatar(
                    radius: 40,
                    child: Text(
                      widget.user.username[0].toUpperCase(),
                      style: const TextStyle(fontSize: 28),
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

/// Post List Item Widget
class _PostListItem extends StatelessWidget {
  final PostModel post;

  const _PostListItem({required this.post});

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'poem':
        return '📝';
      case 'story':
        return '📖';
      case 'joke':
        return '😄';
      default:
        return '📄';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.month}/${date.day}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _getCategoryIcon(post.category),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      post.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDate(post.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),

            // Title
            if (post.title.isNotEmpty) ...[
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSizes.xs),
            ],

            // Content Preview
            Text(
              post.content,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSizes.sm),

            // Interaction Stats
            Row(
              children: [
                _InteractionStat(
                  icon: Icons.favorite_outline,
                  count: post.likesCount,
                ),
                const SizedBox(width: AppSizes.md),
                _InteractionStat(
                  icon: Icons.comment_outlined,
                  count: post.commentsCount,
                ),
                const SizedBox(width: AppSizes.md),
                _InteractionStat(
                  icon: Icons.share_outlined,
                  count: post.sharesCount,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Interaction Stat Widget
class _InteractionStat extends StatelessWidget {
  final IconData icon;
  final int count;

  const _InteractionStat({
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
