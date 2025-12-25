import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/repositories/post_repository.dart';
import 'package:literature/repositories/auth_repository.dart';
import 'package:literature/models/story_model.dart';
import 'package:literature/models/user_model.dart';

/// Story Viewer Screen - Full-screen story viewer
/// See CLAUDE.md: Stories Feature
class StoryViewerScreen extends StatefulWidget {
  final String authorId;
  final List<String>? allAuthorIds; // List of all authors with stories
  final int? startAuthorIndex; // Index of the starting author in allAuthorIds

  const StoryViewerScreen({
    super.key,
    required this.authorId,
    this.allAuthorIds,
    this.startAuthorIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  int _currentStoryIndex = 0;
  int _currentAuthorIndex = 0;
  String _currentAuthorId = '';
  List<StoryModel> _stories = [];
  UserModel? _author;

  @override
  void initState() {
    super.initState();
    _currentAuthorId = widget.authorId;
    _currentAuthorIndex = widget.startAuthorIndex ?? 0;
    _loadAuthorData();
  }

  Future<void> _loadAuthorData() async {
    try {
      final author = await context.read<AuthRepository>().getUserData(_currentAuthorId);
      if (mounted) {
        setState(() {
          _author = author;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  void _nextStory() {
    if (_currentStoryIndex < _stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
    } else {
      // Last story of current author - move to next author
      _moveToNextAuthor();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
    } else {
      // First story of current author - move to previous author's last story
      _moveToPreviousAuthor();
    }
  }

  void _moveToNextAuthor() {
    if (widget.allAuthorIds == null || widget.allAuthorIds!.isEmpty) {
      // No author list provided, just close
      context.pop();
      return;
    }

    final nextAuthorIndex = _currentAuthorIndex + 1;
    if (nextAuthorIndex < widget.allAuthorIds!.length) {
      setState(() {
        _currentAuthorIndex = nextAuthorIndex;
        _currentAuthorId = widget.allAuthorIds![nextAuthorIndex];
        _currentStoryIndex = 0; // Start at first story of next author
        _author = null; // Reset author, will reload
      });
      _loadAuthorData();
    } else {
      // No more authors, close viewer
      context.pop();
    }
  }

  void _moveToPreviousAuthor() {
    if (widget.allAuthorIds == null || widget.allAuthorIds!.isEmpty) {
      // No author list provided, do nothing
      return;
    }

    final previousAuthorIndex = _currentAuthorIndex - 1;
    if (previousAuthorIndex >= 0) {
      // We'll set the index to the last story after we load the stories
      setState(() {
        _currentAuthorIndex = previousAuthorIndex;
        _currentAuthorId = widget.allAuthorIds![previousAuthorIndex];
        _currentStoryIndex = -1; // Flag to set to last story
        _author = null; // Reset author, will reload
      });
      _loadAuthorData();
    }
  }

  void _deleteStory(String storyId) async {
    try {
      await context.read<PostRepository>().deleteStory(storyId, _currentAuthorId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story deleted')),
      );

      // If no more stories, move to next author or close
      if (_stories.length <= 1) {
        _moveToNextAuthor();
      } else {
        // Move to next story or previous if this was the last one
        if (_currentStoryIndex >= _stories.length - 1) {
          setState(() {
            _currentStoryIndex = _stories.length - 2;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is Authenticated ? authState.user.id : null;
    final isOwnStory = currentUserId == _currentAuthorId;

    return StreamBuilder<List<StoryModel>>(
      key: ValueKey(_currentAuthorId), // Force rebuild when author changes
      stream: context.read<PostRepository>().getUserStories(_currentAuthorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 64),
                  const SizedBox(height: AppSizes.md),
                  const Text(
                    'No stories available',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          );
        }

        _stories = snapshot.data!;

        // Handle flag to jump to last story (when moving to previous author)
        if (_currentStoryIndex == -1 && _stories.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentStoryIndex = _stories.length - 1;
              });
            }
          });
        }

        // Ensure current index is valid
        if (_currentStoryIndex >= _stories.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _stories.isNotEmpty) {
              setState(() {
                _currentStoryIndex = _stories.length - 1;
              });
            }
          });
        }

        if (_stories.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 64),
                  const SizedBox(height: AppSizes.md),
                  const Text(
                    'No stories available',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          );
        }

        // Clamp index to valid range
        final safeIndex = _currentStoryIndex.clamp(0, _stories.length - 1);
        final currentStory = _stories[safeIndex];
        final backgroundColor = currentStory.backgroundColor == 'black'
            ? Colors.black
            : Colors.white;
        final textColor = currentStory.backgroundColor == 'black'
            ? Colors.white
            : Colors.black;

        return Scaffold(
          backgroundColor: backgroundColor,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final screenWidth = MediaQuery.of(context).size.width;
              final tapPosition = details.globalPosition.dx;

              // Left half = previous, Right half = next (Instagram style)
              if (tapPosition < screenWidth / 2) {
                _previousStory();
              } else {
                _nextStory();
              }
            },
            child: SafeArea(
              child: Stack(
                children: [
                  // Story Content
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (currentStory.title.isNotEmpty) ...[
                            Text(
                              currentStory.title,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSizes.lg),
                          ],
                          Text(
                            currentStory.textContent,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 22,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Progress Bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.sm),
                      child: Row(
                        children: List.generate(
                          _stories.length,
                          (index) => Expanded(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: index <= safeIndex
                                    ? textColor
                                    : textColor.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Header
                  Positioned(
                    top: 15,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: textColor.withValues(alpha: 0.2),
                            child: Text(
                              _author?.username[0].toUpperCase() ?? '?',
                              style: TextStyle(color: textColor, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _author?.username ?? 'Loading...',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _getTimeAgo(currentStory.createdAt),
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isOwnStory)
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: textColor),
                              onPressed: () => _showDeleteDialog(currentStory.id),
                            ),
                          IconButton(
                            icon: Icon(Icons.close, color: textColor),
                            onPressed: () => context.pop(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Story counter at bottom
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${safeIndex + 1} / ${_stories.length}',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(String storyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Story'),
        content: const Text('Are you sure you want to delete this story?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteStory(storyId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
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
