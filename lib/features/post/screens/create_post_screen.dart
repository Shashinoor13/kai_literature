import 'dart:io';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:literature/features/post/bloc/post_bloc.dart';
import 'package:literature/features/post/bloc/post_event.dart';
import 'package:literature/features/post/bloc/post_state.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/core/constants/sizes.dart';

/// Beautiful text-heavy create post screen
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'poem';
  File? _backgroundImage;
  final _imagePicker = ImagePicker();

  final List<String> _categories = ['poem', 'story', 'joke', 'other'];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickBackgroundImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _backgroundImage = File(pickedFile.path);
      });
    }
  }

  void _removeBackgroundImage() {
    setState(() {
      _backgroundImage = null;
    });
  }

  bool get _hasContent =>
      _titleController.text.trim().isNotEmpty ||
      _contentController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.id : '';

    return BlocProvider(
      create: (context) =>
          PostBloc(postRepository: context.read(), userId: userId),
      child: BlocConsumer<PostBloc, PostState>(
        listener: (context, state) {
          if (state is PostCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Post created successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            context.go('/');
          } else if (state is DraftSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Draft saved'),
                duration: Duration(seconds: 2),
              ),
            );
            context.go('/');
          } else if (state is StoryUploaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Story uploaded successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            context.go('/');
          } else if (state is PostError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is PostLoading;

          return GestureDetector(
            onTap: () {
              // Dismiss keyboard when tapping outside text fields
              FocusScope.of(context).unfocus();
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Create'),
                actions: [
                  if (_backgroundImage != null)
                    IconButton(
                      icon: const HeroIcon(HeroIcons.xMark),
                      onPressed: _removeBackgroundImage,
                      tooltip: 'Remove background',
                    ),
                  if (_backgroundImage == null)
                    IconButton(
                      icon: const HeroIcon(HeroIcons.photo),
                      onPressed: _pickBackgroundImage,
                      tooltip: 'Add background (optional)',
                    ),
                ],
              ),
              body: Stack(
                children: [
                  // Background image if selected
                  if (_backgroundImage != null)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.15,
                        child: Image.file(_backgroundImage!, fit: BoxFit.cover),
                      ),
                    ),

                  // Main content
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category selection
                        Text('Category', style: theme.textTheme.labelLarge),
                        const SizedBox(height: AppSizes.sm),
                        Wrap(
                          spacing: AppSizes.sm,
                          children: _categories.map((category) {
                            final isSelected = _selectedCategory == category;
                            return ChoiceChip(
                              label: Text(
                                category[0].toUpperCase() +
                                    category.substring(1),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: AppSizes.xl),

                        // Title input
                        TextField(
                          controller: _titleController,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                            letterSpacing: -0.5,
                          ),
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Untitled',
                            hintStyle: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              letterSpacing: -0.5,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),

                        const SizedBox(height: AppSizes.xl),

                        // Content input
                        TextField(
                          controller: _contentController,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.8,
                            fontSize: 18,
                            letterSpacing: 0.2,
                          ),
                          maxLines: null,
                          minLines: 12,
                          decoration: InputDecoration(
                            hintText: 'Start writing...',
                            hintStyle: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.8,
                              fontSize: 18,
                              letterSpacing: 0.2,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.25,
                              ),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),

                        const SizedBox(height: AppSizes.xxl),
                      ],
                    ),
                  ),

                  // Loading overlay
                  if (isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Post button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _hasContent && !isLoading
                              ? () {
                                  context.read<PostBloc>().add(
                                    CreatePostRequested(
                                      title: _titleController.text.trim(),
                                      content: _contentController.text.trim(),
                                      category: _selectedCategory,
                                      backgroundImage: _backgroundImage,
                                    ),
                                  );
                                }
                              : null,
                          child: const Text('Post'),
                        ),
                      ),

                      const SizedBox(height: AppSizes.sm),

                      // Secondary actions row
                      Row(
                        children: [
                          // Save as Draft
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _hasContent && !isLoading
                                  ? () {
                                      context.read<PostBloc>().add(
                                        SaveDraftRequested(
                                          title: _titleController.text.trim(),
                                          content: _contentController.text
                                              .trim(),
                                          category: _selectedCategory,
                                          backgroundImage: _backgroundImage,
                                        ),
                                      );
                                    }
                                  : null,
                              child: const Text('Save Draft'),
                            ),
                          ),

                          const SizedBox(width: AppSizes.sm),

                          // Upload as Story
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _hasContent && !isLoading
                                  ? () {
                                      context.read<PostBloc>().add(
                                        UploadStoryRequested(
                                          title: _titleController.text.trim(),
                                          content: _contentController.text
                                              .trim(),
                                          category: _selectedCategory,
                                          backgroundImage: _backgroundImage,
                                          backgroundColor: 'black',
                                        ),
                                      );
                                    }
                                  : null,
                              child: const Text('Story (7d)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
