import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
              title: const Text(''),
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
                return _PostListItem(post: post, isOwnPost: true);
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

void _showFullScreenImage(BuildContext context, String imageUrl) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Image (tap anywhere to close)
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Center(
                  child: InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              //Close button (top-right)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 12,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
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
                  GestureDetector(
                    onTap: () {
                      if (user.profileImageUrl.isNotEmpty) {
                        _showFullScreenImage(context, user.profileImageUrl);
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: user.profileImageUrl.isNotEmpty
                          ? CachedNetworkImageProvider(user.profileImageUrl)
                          : null,
                      child: user.profileImageUrl.isEmpty
                          ? Text(
                              user.username[0].toUpperCase(),
                              style: const TextStyle(fontSize: 28),
                            )
                          : null,
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
class _PostListItem extends StatefulWidget {
  final PostModel post;
  final bool isOwnPost;

  const _PostListItem({required this.post, this.isOwnPost = false});

  @override
  State<_PostListItem> createState() => _PostListItemState();
}

class _PostListItemState extends State<_PostListItem> {
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'poem':
        return const Color(0xFF90EE90);
      case 'joke':
        return const Color(0xFFFFD700);
      case 'story':
        return const Color(0xFFADD8E6);
      default:
        return Colors.grey[300]!;
    }
  }

  Color _getCategoryTextColor(String category) {
    switch (category.toLowerCase()) {
      case 'poem':
      case 'joke':
      case 'story':
        return Colors.black87;
      default:
        return Colors.white;
    }
  }

  HeroIcons _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'poem':
        return HeroIcons.bookOpen;
      case 'story':
        return HeroIcons.documentText;
      case 'joke':
        return HeroIcons.faceSmile;
      default:
        return HeroIcons.document;
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

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const HeroIcon(HeroIcons.pencil),
              title: const Text('Edit Post'),
              onTap: () {
                Navigator.pop(context);
                _editPost();
              },
            ),
            ListTile(
              leading: const HeroIcon(HeroIcons.trash, color: Colors.red),
              title: const Text(
                'Delete Post',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deletePost();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editPost() {
    context.push('/create', extra: widget.post);
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<PostRepository>().deletePost(widget.post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
          // Reload posts
          final authState = context.read<AuthBloc>().state;
          if (authState is Authenticated) {
            context.read<PostBloc>().add(LoadUserPosts(authState.user.id));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting post: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/post/${widget.post.id}'),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSizes.md),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category badge, date, and options
              Row(
                children: [
                  // Category badge with icon
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: AppSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(widget.post.category),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HeroIcon(
                          _getCategoryIcon(widget.post.category),
                          size: 14,
                          color: _getCategoryTextColor(widget.post.category),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.post.category.toUpperCase(),
                          style: TextStyle(
                            color: _getCategoryTextColor(widget.post.category),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(widget.post.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (widget.isOwnPost) ...[
                    const SizedBox(width: AppSizes.xs),
                    IconButton(
                      icon: const HeroIcon(
                        HeroIcons.ellipsisVertical,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _showOptionsMenu,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSizes.md),

              // Title
              if (widget.post.title.isNotEmpty) ...[
                Text(
                  widget.post.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.xs),
              ],

              // Content Preview
              Text(
                widget.post.content,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey[800],
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSizes.md),

              // Divider
              Divider(height: 1, color: Colors.grey[300]),
              const SizedBox(height: AppSizes.sm),

              // Interaction Stats
              Row(
                children: [
                  _InteractionStat(
                    icon: HeroIcons.heart,
                    count: widget.post.likesCount,
                  ),
                  const SizedBox(width: AppSizes.lg),
                  _InteractionStat(
                    icon: HeroIcons.chatBubbleLeft,
                    count: widget.post.commentsCount,
                  ),
                  const SizedBox(width: AppSizes.lg),
                  _InteractionStat(
                    icon: HeroIcons.share,
                    count: widget.post.sharesCount,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interaction Stat Widget
class _InteractionStat extends StatelessWidget {
  final HeroIcons icon;
  final int count;

  const _InteractionStat({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HeroIcon(
          icon,
          style: HeroIconStyle.outline,
          size: 18,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
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
