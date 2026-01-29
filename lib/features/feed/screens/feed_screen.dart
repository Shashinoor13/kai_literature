import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/storages/gloabl/value.dart';
import 'package:literature/core/widgets/search_bar_widget.dart';
import 'package:literature/features/feed/bloc/feed_bloc.dart';
import 'package:literature/features/feed/bloc/feed_event.dart';
import 'package:literature/features/feed/bloc/feed_state.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/features/theme/bloc/theme_bloc.dart';
import 'package:literature/features/theme/bloc/theme_state.dart' as theme_state;
import 'package:literature/repositories/post_repository.dart';
import 'package:literature/repositories/auth_repository.dart';
import 'package:literature/core/routing/scaffold_with_nav_bar.dart';
import 'package:literature/features/feed/widgets/feed_post_card.dart';
import 'package:literature/features/feed/widgets/feed_story_bar.dart';
import 'package:literature/features/feed/widgets/feed_filter_chips.dart';

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
  bool _isUiHidden = false; // Clear mode state
  double _previousPage = 0.0;
  bool _isReadingMode = false;

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

    // Don't auto-hide story bar if in clear mode
    if (_isUiHidden) return;

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

  /// Toggle clear mode - hide/show all UI elements
  void _toggleClearMode() {
    setState(() {
      _isUiHidden = !_isUiHidden;
      // When entering clear mode, hide story bar
      // When exiting, show story bar
      _showStoryBar = !_isUiHidden;
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _feedBloc.close();
    super.dispose();
  }

  // Color _getDefaultBackgroundColor(BuildContext context) {
  //   final filter = GlobalState.instance.selectedContentFilter;
  //   const Color parchmentLight = Color.fromRGBO(240, 215, 181, 1);
  //   const Color parchmentBase = Color.fromRGBO(226, 194, 151, 1);
  //   const Color parchmentDark = Color.fromRGBO(212, 171, 117, 1);

  //   switch (filter) {
  //     case ContentFilter.poem:
  //       // Return a single color from the gradient, e.g., the base color
  //       return parchmentBase;
  //     case ContentFilter.novel:
  //       return Colors.green.shade50;
  //     case ContentFilter.all:
  //     default:
  //       return Theme.of(context).colorScheme.surface;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<FeedRefreshNotification>(
      onNotification: (notification) {
        // Double-tap on home button detected - refresh feed
        _feedBloc.add(
          RefreshFeedPosts(
            feedType: _feedBloc.currentFeedType,
            contentFilter: _feedBloc.currentContentFilter,
          ),
        );
        return true;
      },
      child: BlocProvider.value(
        value: _feedBloc,
        child: BlocBuilder<ThemeBloc, theme_state.ThemeState>(
          builder: (context, themeState) {
            String? backgroundImagePath;
            if (themeState is theme_state.ThemeLoaded) {
              backgroundImagePath = themeState.config.backgroundImagePath;
            }

            return Scaffold(
              extendBodyBehindAppBar: true,
              appBar: _isUiHidden
                  ? null
                  : AppBar(
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
                  // Background Image (if set)
                  if (backgroundImagePath != null &&
                      backgroundImagePath.isNotEmpty)
                    Positioned.fill(
                      child: Image.file(
                        File(backgroundImagePath),
                        fit: BoxFit.cover,
                      ),
                    ),

                  // Main Feed Content
                  BlocBuilder<FeedBloc, FeedState>(
                    builder: (context, state) {
                      if (state is FeedLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
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
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: AppSizes.md),
                              Text(state.message),
                              const SizedBox(height: AppSizes.lg),
                              ElevatedButton(
                                onPressed: () {
                                  _feedBloc.add(const RefreshFeedPosts());
                                },
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
                                const SizedBox(height: AppSizes.xxl),
                                const HeroIcon(
                                  HeroIcons.documentText,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: AppSizes.md),
                                Text(
                                  'No posts yet',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
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

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final topPadding = _showStoryBar ? 200.0 : 20.0;
                            return RefreshIndicator(
                              onRefresh: () async {
                                _feedBloc.add(
                                  RefreshFeedPosts(
                                    feedType: _feedBloc.currentFeedType,
                                    contentFilter:
                                        _feedBloc.currentContentFilter,
                                  ),
                                );
                                await Future.delayed(
                                  const Duration(milliseconds: 500),
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                margin: EdgeInsets.only(top: topPadding),
                                height: constraints.maxHeight - topPadding,
                                child: PageView.builder(
                                  controller: _pageController,
                                  scrollDirection: Axis.vertical,
                                  itemCount: state.posts.length,
                                  itemBuilder: (context, index) {
                                    final post = state.posts[index];
                                    return FeedPostCard(
                                      post: post,
                                      isUiHidden: _isUiHidden,
                                      onTap: _toggleClearMode,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),

                  // Story Bar - Positioned at top, shows/hides on scroll
                  if (!_isUiHidden)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      top: _showStoryBar ? 120 : -200,
                      left: 0,
                      right: 0,
                      child: const FeedStoryBar(),
                    ),

                  // Filter Chips - Always visible, moves up when story bar hides
                  if (!_isUiHidden)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      top: _showStoryBar ? 240 : 120,
                      left: 0,
                      right: 0,
                      child: FeedFilterChips(feedBloc: _feedBloc),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
