import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/features/auth/screens/login_screen.dart';
import 'package:literature/features/auth/screens/signup_screen.dart';
import 'package:literature/features/feed/screens/feed_screen.dart';
import 'package:literature/features/search/screens/search_screen.dart';
import 'package:literature/features/notifications/screens/notifications_screen.dart';
import 'package:literature/features/profile/screens/profile_screen.dart';
import 'package:literature/features/profile/screens/edit_profile_screen.dart';
import 'package:literature/features/profile/screens/settings_screen.dart';
import 'package:literature/features/profile/screens/about_screen.dart';
import 'package:literature/features/profile/screens/user_profile_screen.dart';
import 'package:literature/features/profile/screens/blocked_users_screen.dart';
import 'package:literature/features/messaging/screens/chat_list_screen.dart';
import 'package:literature/features/messaging/screens/chat_screen.dart';
import 'package:literature/features/post/screens/create_post_screen.dart';
import 'package:literature/features/post/screens/post_detail_screen.dart';
import 'package:literature/features/feed/screens/story_viewer_screen.dart';
import 'package:literature/core/routing/scaffold_with_nav_bar.dart';
import 'package:literature/models/post_model.dart';

/// App router configuration using go_router with navigation shell
/// See CLAUDE.md: Navigation Structure
class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthenticated = authState is Authenticated;
      final isOnAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      // Redirect to home if authenticated and on auth page
      if (isAuthenticated && isOnAuthPage) {
        return '/';
      }

      // Redirect to login if not authenticated and not on auth page
      if (!isAuthenticated && !isOnAuthPage) {
        return '/login';
      }

      return null;
    },
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      // Auth routes (no bottom nav)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),

      // Main app routes with bottom navigation shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Home/Feed tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),

          // Messages/Chat tab (replaces Search)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                builder: (context, state) => const ChatListScreen(),
              ),
            ],
          ),

          // Create Post tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/create',
                builder: (context, state) {
                  final postToEdit = state.extra as PostModel?;
                  return CreatePostScreen(postToEdit: postToEdit);
                },
              ),
            ],
          ),

          // Notifications tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),

          // Profile tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Search route (outside bottom nav, accessed from top AppBar)
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),

      // Chat conversation route (outside bottom nav)
      GoRoute(
        path: '/chats',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final conversationId = state.pathParameters['id']!;
          return ChatScreen(conversationId: conversationId);
        },
      ),

      // Edit Profile route
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // Settings route
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // About route
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),

      // User Profile route
      GoRoute(
        path: '/user/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserProfileScreen(userId: userId);
        },
      ),

      // Blocked Users route
      GoRoute(
        path: '/blocked-users',
        builder: (context, state) => const BlockedUsersScreen(),
      ),

      // Post Detail route
      GoRoute(
        path: '/post/:postId',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return PostDetailScreen(postId: postId);
        },
      ),

      // Story Viewer route
      GoRoute(
        path: '/story/:authorId',
        builder: (context, state) {
          final authorId = state.pathParameters['authorId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final allAuthorIds = extra?['allAuthorIds'] as List<String>?;
          final startAuthorIndex = extra?['startAuthorIndex'] as int?;

          return StoryViewerScreen(
            authorId: authorId,
            allAuthorIds: allAuthorIds,
            startAuthorIndex: startAuthorIndex,
          );
        },
      ),
    ],
  );
}

/// Helper class to make GoRouter refresh when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

