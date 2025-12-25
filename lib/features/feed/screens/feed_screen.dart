import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/widgets/search_bar_widget.dart';
import 'package:literature/features/feed/bloc/feed_bloc.dart';
import 'package:literature/features/feed/bloc/feed_event.dart';
import 'package:literature/features/feed/bloc/feed_state.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/repositories/post_repository.dart';
import 'package:literature/repositories/auth_repository.dart';
import 'package:literature/models/post_model.dart';
import 'package:literature/models/story_model.dart';
import 'package:literature/models/user_model.dart';
import 'package:literature/features/feed/screens/comment_screen.dart';

/// Home Feed Screen - TikTok-style vertical scrolling feed
/// See CLAUDE.md: Navigation Structure > Bottom Navigation Bar > Home (Feed)
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late FeedBloc _feedBloc;
  late PageController _pageController;
  bool _showStoryBar = true;
  double _previousPage = 0.0;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is Authenticated ? authState.user.id : null;

    _feedBloc = FeedBloc(
      postRepository: context.read<PostRepository>(),
      authRepository: context.read<AuthRepository>(),
      currentUserId: currentUserId,
    )..add(const LoadFeedPosts());

    _pageController = PageController();
    _pageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    final page = _pageController.page ?? 0;

    // Detect scroll direction
    if (page > _previousPage) {
      // Scrolling down - hide story bar
      if (_showStoryBar) {
        setState(() {
          _showStoryBar = false;
        });
      }
    } else if (page < _previousPage) {
      // Scrolling up - show story bar
      if (!_showStoryBar) {
        setState(() {
          _showStoryBar = true;
        });
      }
    }

    _previousPage = page;
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _feedBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _feedBloc,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: GestureDetector(
            onTap: () => context.push('/search'),
            child: const SearchBarWidget(
              hintText: 'Search posts, users...',
              enabled: false,
            ),
          ),
        ),
        body: Stack(
          children: [
            // Main Feed Content
            BlocBuilder<FeedBloc, FeedState>(
              builder: (context, state) {
                if (state is FeedLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is FeedError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const HeroIcon(
                          HeroIcons.exclamationTriangle,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          'Error loading feed',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSizes.md),
                        Text(state.message),
                        const SizedBox(height: AppSizes.lg),
                        ElevatedButton(
                          onPressed: () =>
                              _feedBloc.add(const RefreshFeedPosts()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is FeedLoaded) {
                  if (state.posts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const HeroIcon(
                            HeroIcons.documentText,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: AppSizes.md),
                          Text(
                            'No posts yet',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppSizes.sm),
                          const Text(
                            'Be the first to share something!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: state.posts.length,
                    itemBuilder: (context, index) {
                      final post = state.posts[index];
                      return _FullScreenPostCard(post: post);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            // Story Bar - Positioned at top, shows/hides on scroll
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: _showStoryBar ? 120 : -120,
              left: 0,
              right: 0,
              child: const _StoryBar(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen post card with TikTok-style interactions
class _FullScreenPostCard extends StatefulWidget {
  final PostModel post;

  const _FullScreenPostCard({required this.post});

  @override
  State<_FullScreenPostCard> createState() => _FullScreenPostCardState();
}

class _FullScreenPostCardState extends State<_FullScreenPostCard>
    with SingleTickerProviderStateMixin {
  UserModel? _author;
  bool _isLiked = false;
  bool _isFavorited = false;
  int _likesCount = 0;
  int _commentsCount = 0;
  int _sharesCount = 0;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
    _commentsCount = widget.post.commentsCount;
    _sharesCount = widget.post.sharesCount;
    _loadAuthorData();
    _checkInteractions();

    // Like animation
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _likeScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(
            parent: _likeAnimationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthorData() async {
    try {
      final author = await context.read<AuthRepository>().getUserData(
        widget.post.authorId,
      );
      if (mounted) {
        setState(() {
          _author = author;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _checkInteractions() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    try {
      final postRepo = context.read<PostRepository>();
      final isLiked = await postRepo.hasUserLikedPost(
        userId: authState.user.id,
        postId: widget.post.id,
      );
      final isFavorited = await postRepo.hasUserFavoritedPost(
        userId: authState.user.id,
        postId: widget.post.id,
      );

      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _isFavorited = isFavorited;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _toggleLike() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    try {
      final postRepo = context.read<PostRepository>();

      // Animate
      _likeAnimationController.forward(from: 0);

      if (_isLiked) {
        await postRepo.unlikePost(
          userId: authState.user.id,
          postId: widget.post.id,
        );
        setState(() {
          _isLiked = false;
          _likesCount--;
        });
      } else {
        await postRepo.likePost(
          userId: authState.user.id,
          postId: widget.post.id,
        );
        setState(() {
          _isLiked = true;
          _likesCount++;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    try {
      final postRepo = context.read<PostRepository>();

      if (_isFavorited) {
        await postRepo.unfavoritePost(
          userId: authState.user.id,
          postId: widget.post.id,
        );
        setState(() {
          _isFavorited = false;
        });
      } else {
        await postRepo.favoritePost(
          userId: authState.user.id,
          postId: widget.post.id,
        );
        setState(() {
          _isFavorited = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentScreen(post: widget.post),
    );
  }

  void _sharePost() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share feature coming soon')));
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
              leading: const HeroIcon(HeroIcons.flag),
              title: const Text('Report Post'),
              onTap: () {
                Navigator.pop(context);
                _reportPost();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _reportPost() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: const Text('Are you sure you want to report this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Post reported')));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years${years == 1 ? 'y' : 'y'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months${months == 1 ? 'mo' : 'mo'} ago';
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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'poem':
        return const Color(0xFF90EE90); // Light green
      case 'joke':
        return const Color(0xFFFFD700); // Yellow/Gold
      case 'story':
        return const Color(0xFFADD8E6); // Light blue
      default:
        return Colors.white70; // Default gray
    }
  }

  Color _getCategoryTextColor(String category) {
    switch (category.toLowerCase()) {
      case 'poem':
      case 'joke':
      case 'story':
        return Colors.black87; // Dark text for light backgrounds
      default:
        return Colors.white; // White text for gray background
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Post Content - Centered
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl,
                vertical: AppSizes.xl * 3,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.post.title.isNotEmpty) ...[
                    Text(
                      widget.post.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.lg),
                  ],
                  Text(
                    widget.post.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Author Info - Bottom Left
          Positioned(
            bottom: 20,
            left: AppSizes.md,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Badge at top
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(widget.post.category),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.post.category.toUpperCase(),
                    style: TextStyle(
                      color: _getCategoryTextColor(widget.post.category),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),

                // User Details
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      child: Text(
                        _author?.username[0].toUpperCase() ?? '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        _author?.username ?? 'Loading...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xs),

                // Date
                Text(
                  _getTimeAgo(widget.post.createdAt),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Interaction Buttons - Right Side
          Positioned(
            right: AppSizes.sm,
            bottom: 20,
            child: Column(
              children: [
                // Like Button
                _InteractionButton(
                  icon: _isLiked ? HeroIcons.heart : HeroIcons.heart,
                  iconStyle: _isLiked
                      ? HeroIconStyle.solid
                      : HeroIconStyle.outline,
                  count: _formatCount(_likesCount),
                  onTap: _toggleLike,
                  useGradient: _isLiked,
                  scale: _likeScaleAnimation,
                ),
                const SizedBox(height: AppSizes.lg),

                // Comment Button
                _InteractionButton(
                  icon: HeroIcons.chatBubbleLeft,
                  iconStyle: HeroIconStyle.outline,
                  count: _formatCount(_commentsCount),
                  onTap: _openComments,
                ),
                const SizedBox(height: AppSizes.lg),

                // Favorite Button
                _InteractionButton(
                  icon: HeroIcons.bookmark,
                  iconStyle: _isFavorited
                      ? HeroIconStyle.solid
                      : HeroIconStyle.outline,
                  count: '',
                  onTap: _toggleFavorite,
                ),
                const SizedBox(height: AppSizes.lg),

                // Share Button
                _InteractionButton(
                  icon: HeroIcons.share,
                  iconStyle: HeroIconStyle.outline,
                  count: _formatCount(_sharesCount),
                  onTap: _sharePost,
                ),
                const SizedBox(height: AppSizes.lg),

                // Options Menu
                _InteractionButton(
                  icon: HeroIcons.ellipsisVertical,
                  iconStyle: HeroIconStyle.outline,
                  count: '',
                  onTap: _showOptionsMenu,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Interaction button with count
class _InteractionButton extends StatelessWidget {
  final HeroIcons icon;
  final HeroIconStyle iconStyle;
  final String count;
  final VoidCallback onTap;
  final bool useGradient;
  final Animation<double>? scale;

  const _InteractionButton({
    required this.icon,
    required this.iconStyle,
    required this.count,
    required this.onTap,
    this.useGradient = false,
    this.scale,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = HeroIcon(
      icon,
      style: iconStyle,
      size: 32,
      color: Colors.white,
    );

    if (useGradient) {
      iconWidget = ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Color(0xFFFF0080), // Pink
            Color(0xFFFF0000), // Red
            Color(0xFF7928CA), // Purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: iconWidget,
      );
    }

    if (scale != null) {
      iconWidget = AnimatedBuilder(
        animation: scale!,
        builder: (context, child) {
          return Transform.scale(scale: scale!.value, child: child);
        },
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          iconWidget,
          if (count.isNotEmpty) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Story Bar Widget - Horizontal scrollable story list
class _StoryBar extends StatelessWidget {
  const _StoryBar();

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
          return const SizedBox(
            height: 110,
            child: Center(child: CircularProgressIndicator()),
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
                return _AddStoryButton(currentUserId: currentUserId);
              }

              final authorIndex = index - 1;
              final authorId = allAuthorIds[authorIndex];
              final authorStories = storiesByAuthor[authorId]!;

              return _StoryAvatar(
                authorId: authorId,
                storyCount: authorStories.length,
                hasUnseen: true, // TODO: Track viewed stories
                allAuthorIds: allAuthorIds,
                authorIndex: authorIndex,
              );
            },
          ),
        );
      },
    );
  }
}

/// Add Story Button
class _AddStoryButton extends StatelessWidget {
  final String currentUserId;

  const _AddStoryButton({required this.currentUserId});

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

/// Story Avatar Widget
class _StoryAvatar extends StatelessWidget {
  final String authorId;
  final int storyCount;
  final bool hasUnseen;
  final List<String> allAuthorIds;
  final int authorIndex;

  const _StoryAvatar({
    required this.authorId,
    required this.storyCount,
    required this.hasUnseen,
    required this.allAuthorIds,
    required this.authorIndex,
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
              storyCount > 0 ? '$storyCount' : '',
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
