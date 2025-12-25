import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/widgets/search_bar_widget.dart';
import 'package:literature/features/search/bloc/search_bloc.dart';
import 'package:literature/features/search/bloc/search_event.dart';
import 'package:literature/features/search/bloc/search_state.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/repositories/auth_repository.dart';
import 'package:literature/repositories/post_repository.dart';
import 'package:literature/models/user_model.dart';
import 'package:literature/models/post_model.dart';

/// Search Screen - Users & Content search
/// See CLAUDE.md: Navigation Structure > Bottom Navigation Bar > Search
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late SearchBloc _searchBloc;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is Authenticated ? authState.user.id : null;

    _searchBloc = SearchBloc(
      authRepository: context.read<AuthRepository>(),
      postRepository: context.read<PostRepository>(),
      currentUserId: currentUserId,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchBloc.close();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchBloc.add(SearchQueryChanged(query));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _searchBloc,
      child: Scaffold(
        appBar: AppBar(
          title: SearchBarWidget(
            controller: _searchController,
            hintText: 'Search posts, users...',
            autofocus: true,
            onChanged: _onSearchChanged,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _searchBloc.add(const ClearSearch());
                      setState(() {});
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : null,
          ),
        ),
        body: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            if (state is SearchInitial) {
              return const _EmptyState(
                message: 'Search for users and posts',
              );
            }

            if (state is SearchLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SearchError) {
              return _EmptyState(
                message: 'Error: ${state.message}',
              );
            }

            if (state is SearchSuccess) {
              if (state.users.isEmpty && state.posts.isEmpty) {
                return _EmptyState(
                  message: 'No results for "${state.query}"',
                );
              }

              return _SearchResults(
                users: state.users,
                posts: state.posts,
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

/// Empty state widget
class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 16, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Search results widget with tabs
class _SearchResults extends StatelessWidget {
  final List<UserModel> users;
  final List<PostModel> posts;

  const _SearchResults({
    required this.users,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Users (${users.length})'),
              Tab(text: 'Posts (${posts.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _UsersList(users: users),
                _PostsList(posts: posts),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Users list widget
class _UsersList extends StatelessWidget {
  final List<UserModel> users;

  const _UsersList({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const _EmptyState(message: 'No users found');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.md),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(user.username[0].toUpperCase()),
            ),
            title: Text('@${user.username}'),
            subtitle: user.bio.isNotEmpty ? Text(user.bio) : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/user/${user.id}');
            },
          ),
        );
      },
    );
  }
}

/// Posts list widget
class _PostsList extends StatelessWidget {
  final List<PostModel> posts;

  const _PostsList({required this.posts});

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'poem':
        return '📝';
      case 'story':
        return '📖';
      case 'joke':
        return '😄';
      default:
        return '📄';
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

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _EmptyState(message: 'No posts found');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Category and Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getCategoryIcon(post.category),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Text(
                          post.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatDate(post.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),

                // Title
                if (post.title.isNotEmpty) ...[
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.xs),
                ],

                // Content Preview
                Text(
                  post.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.sm),

                // Interaction Stats
                Row(
                  children: [
                    _InteractionStat(
                      icon: Icons.favorite_outline,
                      count: post.likesCount,
                    ),
                    const SizedBox(width: AppSizes.md),
                    _InteractionStat(
                      icon: Icons.comment_outlined,
                      count: post.commentsCount,
                    ),
                    const SizedBox(width: AppSizes.md),
                    _InteractionStat(
                      icon: Icons.share_outlined,
                      count: post.sharesCount,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Interaction stat widget
class _InteractionStat extends StatelessWidget {
  final IconData icon;
  final int count;

  const _InteractionStat({
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
