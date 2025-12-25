import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/features/post/bloc/post_bloc.dart';
import 'package:literature/features/post/bloc/post_event.dart';
import 'package:literature/features/post/bloc/post_state.dart';
import 'package:literature/repositories/post_repository.dart';
import 'package:literature/models/post_model.dart';
import 'package:literature/features/profile/screens/follow_list_screen.dart';

/// Profile Screen - My profile page
/// See CLAUDE.md: Navigation Structure > Bottom Navigation Bar > Profile
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  PostBloc? _postBloc;
  String? _currentUserId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      // Only create new bloc if userId changed or bloc doesn't exist
      if (_currentUserId != authState.user.id) {
        _currentUserId = authState.user.id;
        _postBloc?.close(); // Close previous bloc if exists
        _postBloc = PostBloc(
          postRepository: context.read<PostRepository>(),
          userId: authState.user.id,
        )..add(LoadUserPosts(authState.user.id));
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postBloc?.close();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated || _postBloc == null) return;

    // Reload posts
    _postBloc!.add(LoadUserPosts(authState.user.id));

    // Wait a bit for the posts to reload
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated || _postBloc == null) {
          return const Scaffold(body: Center(child: Text('Loading...')));
        }

        return BlocProvider.value(
          value: _postBloc!,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
              actions: [
                IconButton(
                  icon: const HeroIcon(HeroIcons.cog6Tooth),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
            body: Column(
              children: [
                // Profile Header (Compact)
                _ProfileHeader(user: authState.user),

                // Tabs
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: const [
                      Tab(
                        icon: HeroIcon(
                          HeroIcons.documentText,
                          style: HeroIconStyle.outline,
                        ),
                      ),
                      Tab(
                        icon: HeroIcon(
                          HeroIcons.heart,
                          style: HeroIconStyle.outline,
                        ),
                      ),
                      Tab(
                        icon: HeroIcon(
                          HeroIcons.bookmark,
                          style: HeroIconStyle.outline,
                        ),
                      ),
                      Tab(
                        icon: HeroIcon(
                          HeroIcons.chatBubbleLeft,
                          style: HeroIconStyle.outline,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Posts Tab
                      _PostsTab(
                        userId: authState.user.id,
                        onRefresh: _handleRefresh,
                      ),

                      // Liked Tab
                      _LikedPostsTab(userId: authState.user.id),

                      // Favorited Tab
                      _FavoritedPostsTab(userId: authState.user.id),

                      // Commented Tab
                      _CommentedPostsTab(userId: authState.user.id),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Posts Tab - Shows user's own posts
class _PostsTab extends StatelessWidget {
  final String userId;
  final Future<void> Function() onRefresh;

  const _PostsTab({required this.userId, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: BlocBuilder<PostBloc, PostState>(
        builder: (context, postState) {
          if (postState is PostsLoaded) {
            if (postState.posts.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Text(
                      'No posts yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              itemCount: postState.posts.length,
              itemBuilder: (context, index) {
                final post = postState.posts[index];
                return _PostListItem(post: post);
              },
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

/// Liked Posts Tab - Shows posts the user has liked
class _LikedPostsTab extends StatefulWidget {
  final String userId;

  const _LikedPostsTab({required this.userId});

  @override
  State<_LikedPostsTab> createState() => _LikedPostsTabState();
}

class _LikedPostsTabState extends State<_LikedPostsTab> {
  int _refreshKey = 0;

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshKey++;
    });
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final postRepository = context.read<PostRepository>();

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: StreamBuilder<List<PostModel>>(
        key: ValueKey(_refreshKey),
        stream: postRepository.getLikedPosts(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Text(
                    'No liked posts yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return _PostListItem(post: posts[index]);
            },
          );
        },
      ),
    );
  }
}

/// Favorited Posts Tab - Shows posts the user has favorited
class _FavoritedPostsTab extends StatefulWidget {
  final String userId;

  const _FavoritedPostsTab({required this.userId});

  @override
  State<_FavoritedPostsTab> createState() => _FavoritedPostsTabState();
}

class _FavoritedPostsTabState extends State<_FavoritedPostsTab> {
  int _refreshKey = 0;

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshKey++;
    });
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final postRepository = context.read<PostRepository>();

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: StreamBuilder<List<PostModel>>(
        key: ValueKey(_refreshKey),
        stream: postRepository.getFavoritedPosts(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Text(
                    'No favorited posts yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return _PostListItem(post: posts[index]);
            },
          );
        },
      ),
    );
  }
}

/// Commented Posts Tab - Shows posts the user has commented on
class _CommentedPostsTab extends StatefulWidget {
  final String userId;

  const _CommentedPostsTab({required this.userId});

  @override
  State<_CommentedPostsTab> createState() => _CommentedPostsTabState();
}

class _CommentedPostsTabState extends State<_CommentedPostsTab> {
  int _refreshKey = 0;

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshKey++;
    });
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final postRepository = context.read<PostRepository>();

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: StreamBuilder<List<PostModel>>(
        key: ValueKey(_refreshKey),
        stream: postRepository.getCommentedPosts(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Text(
                    'No commented posts yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return _PostListItem(post: posts[index]);
            },
          );
        },
      ),
    );
  }
}

/// Compact Profile Header
class _ProfileHeader extends StatelessWidget {
  final dynamic user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostBloc, PostState>(
      builder: (context, postState) {
        final postsCount = postState is PostsLoaded
            ? postState.posts.length
            : 0;

        return Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            children: [
              // Profile Picture and Stats Row
              Row(
                children: [
                  // Profile Picture (smaller)
                  CircleAvatar(
                    radius: 40,
                    child: Text(
                      user.username[0].toUpperCase(),
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: AppSizes.lg),

                  // Stats (horizontal)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(label: 'Posts', count: postsCount),
                        _StatItem(
                          label: 'Followers',
                          count: user.followersCount,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FollowListScreen(
                                  userId: user.id,
                                  initialTab: 0, // 0 for followers
                                ),
                              ),
                            );
                          },
                        ),
                        _StatItem(
                          label: 'Following',
                          count: user.followingCount,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FollowListScreen(
                                  userId: user.id,
                                  initialTab: 1, // 1 for following
                                ),
                              ),
                            );
                          },
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
                      '@${user.username}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      user.bio.isNotEmpty ? user.bio : 'No bio yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: user.bio.isNotEmpty ? null : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
}

/// Interaction Stat Widget
class _InteractionStat extends StatelessWidget {
  final IconData icon;
  final int count;

  const _InteractionStat({required this.icon, required this.count});

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

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback? onTap;

  const _StatItem({required this.label, required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Text('$count', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSizes.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xs),
          child: content,
        ),
      );
    }

    return content;
  }
}
