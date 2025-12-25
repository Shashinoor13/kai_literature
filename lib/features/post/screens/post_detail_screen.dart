import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/models/post_model.dart';
import 'package:literature/models/user_model.dart';
import 'package:literature/repositories/post_repository.dart';
import 'package:literature/repositories/auth_repository.dart';
import 'package:literature/features/feed/screens/comment_screen.dart';

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

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
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
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[300],
                    child: Text(
                      _author?.username[0].toUpperCase() ?? '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _author?.username ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getTimeAgo(_post!.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: AppSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(_post!.category),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _post!.category.toUpperCase(),
                      style: TextStyle(
                        color: _getCategoryTextColor(_post!.category),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Post Content
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_post!.title.isNotEmpty) ...[
                    Text(
                      _post!.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                  ],
                  Text(
                    _post!.content,
                    style: const TextStyle(fontSize: 18, height: 1.6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // Interaction Stats
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.md,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  _StatItem(
                    icon: HeroIcons.heart,
                    count: _likesCount,
                    label: 'Likes',
                  ),
                  const SizedBox(width: AppSizes.xl),
                  _StatItem(
                    icon: HeroIcons.chatBubbleLeft,
                    count: _commentsCount,
                    label: 'Comments',
                  ),
                  const SizedBox(width: AppSizes.xl),
                  _StatItem(
                    icon: HeroIcons.share,
                    count: _sharesCount,
                    label: 'Shares',
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _toggleLike,
                      icon: HeroIcon(
                        HeroIcons.heart,
                        style: _isLiked
                            ? HeroIconStyle.solid
                            : HeroIconStyle.outline,
                        size: 20,
                        color: _isLiked ? Colors.red : null,
                      ),
                      label: Text(_isLiked ? 'Liked' : 'Like'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.md,
                        ),
                        side: BorderSide(
                          color: _isLiked
                              ? Colors.red
                              : Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openComments,
                      icon: const HeroIcon(
                        HeroIcons.chatBubbleLeft,
                        style: HeroIconStyle.outline,
                        size: 20,
                      ),
                      label: const Text('Comment'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.md,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  OutlinedButton(
                    onPressed: _sharePost,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(AppSizes.md),
                      minimumSize: const Size(48, 48),
                    ),
                    child: const HeroIcon(
                      HeroIcons.share,
                      style: HeroIconStyle.outline,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat item widget for interaction counts
class _StatItem extends StatelessWidget {
  final HeroIcons icon;
  final int count;
  final String label;

  const _StatItem({
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HeroIcon(
          icon,
          style: HeroIconStyle.outline,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: AppSizes.xs),
        Text(
          '$count',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }
}
