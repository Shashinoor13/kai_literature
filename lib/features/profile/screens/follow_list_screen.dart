import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/models/user_model.dart';
import 'package:literature/repositories/auth_repository.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';

/// Follow List Screen - Shows followers and following tabs
class FollowListScreen extends StatefulWidget {
  final String userId;
  final int initialTab; // 0 for followers, 1 for following

  const FollowListScreen({
    super.key,
    required this.userId,
    this.initialTab = 0,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connections'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: [
            // Tab(text: 'Followers', icon: Icon(Icons.people)),
            // Tab(text: 'Following', icon: Icon(Icons.person_add)),
            Tab(child: Text('Followers')),
            Tab(child: Text('Following')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FollowersTab(userId: widget.userId),
          _FollowingTab(userId: widget.userId),
        ],
      ),
    );
  }
}

/// Followers Tab Widget
class _FollowersTab extends StatefulWidget {
  final String userId;

  const _FollowersTab({required this.userId});

  @override
  State<_FollowersTab> createState() => _FollowersTabState();
}

class _FollowersTabState extends State<_FollowersTab> {
  late Future<List<UserModel>> _followersFuture;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  void _loadFollowers() {
    setState(() {
      _followersFuture = context.read<AuthRepository>().getFollowers(
        widget.userId,
      );
    });
  }

  Future<void> _handleRefresh() async {
    _loadFollowers();
    await _followersFuture;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: FutureBuilder<List<UserModel>>(
        future: _followersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          'Error loading followers',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final followers = snapshot.data ?? [];

          if (followers.isEmpty) {
            return ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: AppSizes.md),
                        Text(
                          'No followers yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: followers.length,
            itemBuilder: (context, index) {
              final user = followers[index];
              return _UserListItem(user: user, onChanged: _loadFollowers);
            },
          );
        },
      ),
    );
  }
}

/// Following Tab Widget
class _FollowingTab extends StatefulWidget {
  final String userId;

  const _FollowingTab({required this.userId});

  @override
  State<_FollowingTab> createState() => _FollowingTabState();
}

class _FollowingTabState extends State<_FollowingTab> {
  late Future<List<UserModel>> _followingFuture;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  void _loadFollowing() {
    setState(() {
      _followingFuture = context.read<AuthRepository>().getFollowing(
        widget.userId,
      );
    });
  }

  Future<void> _handleRefresh() async {
    _loadFollowing();
    await _followingFuture;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: FutureBuilder<List<UserModel>>(
        future: _followingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          'Error loading following',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final following = snapshot.data ?? [];

          if (following.isEmpty) {
            return ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: AppSizes.md),
                        Text(
                          'Not following anyone yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: following.length,
            itemBuilder: (context, index) {
              final user = following[index];
              return _UserListItem(user: user, onChanged: _loadFollowing);
            },
          );
        },
      ),
    );
  }
}

/// User List Item Widget
class _UserListItem extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onChanged;

  const _UserListItem({required this.user, this.onChanged});

  @override
  State<_UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<_UserListItem> {
  bool _isFollowing = false;
  bool _isLoading = false;

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

    setState(() => _isLoading = true);

    try {
      final authRepo = context.read<AuthRepository>();

      if (_isFollowing) {
        await authRepo.unfollowUser(
          followerId: authState.user.id,
          followingId: widget.user.id,
        );
        if (!mounted) return;
        setState(() => _isFollowing = false);
        widget.onChanged?.call();
      } else {
        await authRepo.followUser(
          followerId: authState.user.id,
          followingId: widget.user.id,
        );
        if (!mounted) return;
        setState(() => _isFollowing = true);
        widget.onChanged?.call();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isCurrentUser =
        authState is Authenticated && authState.user.id == widget.user.id;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 4,
          ),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[300],
            backgroundImage: widget.user.profileImageUrl.isNotEmpty
                ? NetworkImage(widget.user.profileImageUrl)
                : null,
            child: widget.user.profileImageUrl.isEmpty
                ? Text(
                    widget.user.username[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          title: Text(
            widget.user.username,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: widget.user.bio.isNotEmpty
              ? Text(
                  widget.user.bio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: isCurrentUser
              ? null
              : SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _toggleFollow,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _isFollowing
                          ? Colors.white
                          : Colors.black,
                      foregroundColor: _isFollowing
                          ? Colors.black
                          : Colors.white,
                      side: const BorderSide(color: Colors.black),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isFollowing ? 'Unfollow' : 'Follow'),
                  ),
                ),
          onTap: () => context.push('/user/${widget.user.id}'),
        ),
        const Divider(height: 0),
      ],
    );
  }
}
