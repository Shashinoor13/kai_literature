import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:literature/core/widgets/search_bar_widget.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/features/messaging/bloc/messaging_bloc.dart';
import 'package:literature/features/messaging/bloc/messaging_event.dart';
import 'package:literature/features/messaging/bloc/messaging_state.dart';
import 'package:literature/repositories/auth_repository.dart';

/// Chat List Screen - Shows all conversations
/// See CLAUDE.md: Messaging (Mutual Follows Only)
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<MessagingBloc>().add(LoadConversations(authState.user.id));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
  }

  void _handleSearch(String query, String currentUserId) {
    if (query.isEmpty) {
      context.read<MessagingBloc>().add(LoadConversations(currentUserId));
    } else {
      context.read<MessagingBloc>().add(
            SearchUsersToChat(query: query, currentUserId: currentUserId),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Scaffold(
            body: Center(child: Text('Please log in')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? SearchBarWidget(
                    controller: _searchController,
                    autofocus: true,
                    hintText: 'Search users...',
                    onChanged: (query) => _handleSearch(query, authState.user.id),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: _stopSearch,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  )
                : const Text('Messages'),
            actions: [
              if (!_isSearching)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _startSearch,
                ),
            ],
          ),
          body: BlocConsumer<MessagingBloc, MessagingState>(
            listener: (context, state) {
              if (state is MessagingError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              } else if (state is ConversationCreated) {
                context.push('/chat/${state.conversationId}');
              }
            },
            buildWhen: (previous, current) {
              // Only rebuild for states relevant to chat list
              // Don't rebuild when MessagesLoaded (from individual chat)
              if (current is MessagesLoaded) {
                return false;
              }
              return true;
            },
            builder: (context, state) {
              if (state is MessagingLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is UserSearchResults) {
                return _buildUserSearchResults(state, authState.user.id);
              }

              if (state is ConversationsLoaded) {
                if (state.conversations.isEmpty) {
                  return const Center(
                    child: Text('No conversations yet'),
                  );
                }

                return ListView.builder(
                  itemCount: state.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = state.conversations[index];
                    final otherUserId =
                        conversation.getOtherParticipantId(authState.user.id);

                    return FutureBuilder(
                      future: context
                          .read<AuthBloc>()
                          .authRepository
                          .getUserData(otherUserId),
                      builder: (context, snapshot) {
                        final otherUser = snapshot.data;
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              otherUser?.username[0].toUpperCase() ?? '?',
                            ),
                          ),
                          title: Text(otherUser?.username ?? 'Loading...'),
                          subtitle: Text(
                            conversation.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            timeago.format(conversation.updatedAt),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          onTap: () {
                            context.push('/chat/${conversation.id}');
                          },
                        );
                      },
                    );
                  },
                );
              }

              return const Center(
                child: Text('Start a conversation'),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUserSearchResults(UserSearchResults state, String currentUserId) {
    if (state.users.isEmpty) {
      return const Center(
        child: Text('No users found'),
      );
    }

    return ListView.builder(
      itemCount: state.users.length,
      itemBuilder: (context, index) {
        final user = state.users[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(user.username[0].toUpperCase()),
          ),
          title: Text(user.username),
          subtitle: Text(user.bio.isEmpty ? 'No bio' : user.bio),
          onTap: () {
            context.read<MessagingBloc>().add(
                  CreateConversation(
                    currentUserId: currentUserId,
                    otherUserId: user.id,
                  ),
                );
          },
        );
      },
    );
  }
}

// Extension to access authRepository from AuthBloc
extension on AuthBloc {
  AuthRepository get authRepository => AuthRepository();
}
