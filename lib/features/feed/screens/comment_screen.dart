import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/models/post_model.dart';
import 'package:literature/models/comment_model.dart';
import 'package:literature/models/user_model.dart';
import 'package:literature/repositories/post_repository.dart';
import 'package:literature/repositories/auth_repository.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';

/// Comment Screen - Modal bottom sheet for viewing and adding comments
class CommentScreen extends StatefulWidget {
  final PostModel post;

  const CommentScreen({super.key, required this.post});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  List<CommentModel>? _lastComments; // Cache last known comments

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      setState(() {}); // Rebuild to update send button state
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final postRepo = context.read<PostRepository>();
      await postRepo.addComment(
        postId: widget.post.id,
        authorId: authState.user.id,
        content: content,
      );

      if (!mounted) return;
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Comments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const HeroIcon(
                    HeroIcons.xMark,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Comments list
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: context.read<PostRepository>().getComments(
                widget.post.id,
              ),
              builder: (context, snapshot) {
                // Update cache when we have data
                if (snapshot.hasData) {
                  _lastComments = snapshot.data;
                }

                // Use cached comments if available, otherwise use snapshot data
                final comments = _lastComments ?? snapshot.data ?? [];

                // Only show loading on initial load (no cached data)
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _lastComments == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                // Only show error if we have no cached data
                if (snapshot.hasError && _lastComments == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const HeroIcon(
                          HeroIcons.exclamationTriangle,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          'Error loading comments',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const HeroIcon(
                          HeroIcons.chatBubbleLeftRight,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          'Be the first to comment!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.md),
                  itemCount: comments.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: Colors.white12, height: 24),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _CommentItem(comment: comment);
                  },
                );
              },
            ),
          ),

          // Comment input
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(32),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 10,
                          ),
                          filled: false,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        enabled: !_isSubmitting,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap:
                          _isSubmitting ||
                              _commentController.text.trim().isEmpty
                          ? null
                          : _submitComment,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              _isSubmitting ||
                                  _commentController.text.trim().isEmpty
                              ? Colors.white24
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: _isSubmitting
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Center(
                                child: HeroIcon(
                                  HeroIcons.paperAirplane,
                                  size: 20,
                                  color: _commentController.text.trim().isEmpty
                                      ? Colors.white38
                                      : Colors.black,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Comment item widget
class _CommentItem extends StatelessWidget {
  final CommentModel comment;

  const _CommentItem({required this.comment});

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
    return FutureBuilder<UserModel?>(
      future: context.read<AuthRepository>().getUserById(comment.authorId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final username = user?.username ?? 'Unknown User';
        final profileImage = user?.profileImageUrl;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                backgroundImage: profileImage != null
                    ? NetworkImage(profileImage)
                    : null,
                child: profileImage == null
                    ? Text(
                        username[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSizes.sm),

              // Comment content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Text(
                          _formatDate(comment.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      comment.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.4,
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
