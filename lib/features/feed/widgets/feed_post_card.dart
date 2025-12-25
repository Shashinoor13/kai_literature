import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/features/feed/screens/comment_screen.dart';
import 'package:literature/features/feed/widgets/feed_post_author_info.dart';
import 'package:literature/features/feed/widgets/feed_post_content.dart';
import 'package:literature/features/feed/widgets/feed_post_interactions.dart';
import 'package:literature/models/post_model.dart';
import 'package:literature/models/user_model.dart';
import 'package:literature/repositories/auth_repository.dart';
import 'package:literature/repositories/post_repository.dart';

/// Full-screen post card with TikTok-style interactions
class FeedPostCard extends StatefulWidget {
  final PostModel post;

  const FeedPostCard({
    super.key,
    required this.post,
  });

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard>
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
    _likeScaleAnimation = TweenSequence<double>([
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post reported')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Report'),
          ),
        ],
      ),
    );
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
          FeedPostContent(post: widget.post),

          // Author Info - Bottom Left
          Positioned(
            bottom: 20,
            left: AppSizes.md,
            right: 80,
            child: FeedPostAuthorInfo(
              author: _author,
              post: widget.post,
            ),
          ),

          // Interaction Buttons - Right Side
          Positioned(
            right: AppSizes.sm,
            bottom: 20,
            child: FeedPostInteractions(
              isLiked: _isLiked,
              isFavorited: _isFavorited,
              likesCount: _likesCount,
              commentsCount: _commentsCount,
              sharesCount: _sharesCount,
              onLikeTap: _toggleLike,
              onCommentTap: _openComments,
              onFavoriteTap: _toggleFavorite,
              onShareTap: _sharePost,
              onOptionsTap: _showOptionsMenu,
              likeAnimation: _likeScaleAnimation,
            ),
          ),
        ],
      ),
    );
  }
}
