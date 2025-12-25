import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/utils/format_utils.dart';
import 'package:literature/core/utils/category_utils.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/models/post_model.dart';
import 'package:literature/models/user_model.dart';
import 'package:literature/repositories/post_repository.dart';
import 'package:literature/repositories/auth_repository.dart';
import 'package:literature/features/feed/screens/comment_screen.dart';
import 'package:literature/features/post/widgets/post_author_header.dart';
import 'package:literature/features/post/widgets/post_content_section.dart';
import 'package:literature/features/post/widgets/post_interaction_stats.dart';
import 'package:literature/features/post/widgets/post_action_buttons.dart';

/// Post Detail Screen - Full post view with interactions
class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  PostModel? _post;
  UserModel? _author;
  bool _isLiked = false;
  bool _isFavorited = false;
  int _likesCount = 0;
  int _commentsCount = 0;
  int _sharesCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  Future<void> _loadPostData() async {
    try {
      final postRepo = context.read<PostRepository>();
      final authRepo = context.read<AuthRepository>();
      final post = await postRepo.getPostById(widget.postId);

      if (post != null && mounted) {
        final author = await authRepo.getUserData(post.authorId);

        if (mounted) {
          setState(() {
            _post = post;
            _author = author;
            _likesCount = post.likesCount;
            _commentsCount = post.commentsCount;
            _sharesCount = post.sharesCount;
            _isLoading = false;
          });

          _checkInteractions();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkInteractions() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated || _post == null) return;

    try {
      final postRepo = context.read<PostRepository>();
      final isLiked = await postRepo.hasUserLikedPost(
        userId: authState.user.id,
        postId: _post!.id,
      );
      final isFavorited = await postRepo.hasUserFavoritedPost(
        userId: authState.user.id,
        postId: _post!.id,
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
    if (authState is! Authenticated || _post == null) return;

    try {
      final postRepo = context.read<PostRepository>();

      if (_isLiked) {
        await postRepo.unlikePost(userId: authState.user.id, postId: _post!.id);
        setState(() {
          _isLiked = false;
          _likesCount--;
        });
      } else {
        await postRepo.likePost(userId: authState.user.id, postId: _post!.id);
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
    if (authState is! Authenticated || _post == null) return;

    try {
      final postRepo = context.read<PostRepository>();

      if (_isFavorited) {
        await postRepo.unfavoritePost(
          userId: authState.user.id,
          postId: _post!.id,
        );
        setState(() {
          _isFavorited = false;
        });
      } else {
        await postRepo.favoritePost(
          userId: authState.user.id,
          postId: _post!.id,
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
    if (_post == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentScreen(post: _post!),
    );
  }

  void _sharePost() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share feature coming soon')));
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post Not Found')),
        body: const Center(child: Text('This post could not be found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          IconButton(
            icon: HeroIcon(
              _isFavorited ? HeroIcons.bookmark : HeroIcons.bookmark,
              style: _isFavorited ? HeroIconStyle.solid : HeroIconStyle.outline,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Header
            PostAuthorHeader(
              author: _author,
              post: _post!,
              getTimeAgo: FormatUtils.getTimeAgo,
              getCategoryColor: CategoryUtils.getCategoryColor,
              getCategoryTextColor: CategoryUtils.getCategoryTextColor,
            ),

            // Post Content
            PostContentSection(post: _post!),

            const SizedBox(height: AppSizes.lg),

            // Interaction Stats
            PostInteractionStats(
              likesCount: _likesCount,
              commentsCount: _commentsCount,
              sharesCount: _sharesCount,
            ),

            // Action Buttons
            PostActionButtons(
              isLiked: _isLiked,
              onLikePressed: _toggleLike,
              onCommentPressed: _openComments,
              onSharePressed: _sharePost,
            ),
          ],
        ),
      ),
    );
  }
}
