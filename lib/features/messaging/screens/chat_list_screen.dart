import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/widgets/search_bar_widget.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/features/messaging/bloc/messaging_bloc.dart';
import 'package:literature/features/messaging/bloc/messaging_event.dart';
import 'package:literature/features/messaging/bloc/messaging_state.dart';
import 'package:literature/repositories/auth_repository.dart';
import 'package:literature/repositories/messaging_repository.dart';
import 'package:literature/models/user_model.dart';

/// Chat List Screen - Shows all conversations
/// See CLAUDE.md: Messaging (Mutual Follows Only)
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchController = TextEditingController();
  final _messagingRepository = MessagingRepository();
  final _authRepository = AuthRepository();
  String _searchQuery = '';

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

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<dynamic> _filterConversations(List conversations, String query) {
    if (query.isEmpty) return conversations;

    return conversations.where((conversation) {
      final lastMessage = conversation.lastMessage.toLowerCase();
      return lastMessage.contains(query);
    }).toList();
  }

  void _showMutualFollowersSheet(String currentUserId) {
    final mainContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _MutualFollowersSheet(
        currentUserId: currentUserId,
        messagingRepository: _messagingRepository,
        authRepository: _authRepository,
        onUserSelected: (userId) async {
          try {
            // Create or get conversation
            final conversationId = await _messagingRepository.getOrCreateConversation(
              currentUserId,
              userId,
            );

            // Close the sheet
            if (!sheetContext.mounted) return;
            Navigator.of(sheetContext).pop();

            // Navigate to chat
            if (!mounted || !mainContext.mounted) return;
            mainContext.push('/chat/$conversationId');
          } catch (e) {
            if (!sheetContext.mounted) return;
            ScaffoldMessenger.of(sheetContext).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: Colors.white,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'Please log in',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            centerTitle: false,
            backgroundColor: Colors.black,
            elevation: 0,
            title: const Text(
              'Messages',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: SearchBarWidget(
                  controller: _searchController,
                  hintText: 'Search conversations...',
                  onChanged: _handleSearch,
                ),
              ),

              // Conversations list
              Expanded(
                child: BlocConsumer<MessagingBloc, MessagingState>(
                  listener: (context, state) {
                    if (state is MessagingError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.white,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (state is ConversationCreated) {
                      context.push('/chat/${state.conversationId}');
                    }
                  },
                  buildWhen: (previous, current) {
                    if (current is MessagesLoaded) {
                      return false;
                    }
                    return true;
                  },
                  builder: (context, state) {
                    if (state is MessagingLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (state is ConversationsLoaded) {
                      final filteredConversations = _filterConversations(
                        state.conversations,
                        _searchQuery,
                      );

                      if (filteredConversations.isEmpty) {
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
                                _searchQuery.isEmpty
                                    ? 'No conversations yet'
                                    : 'No matching conversations',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: AppSizes.xs),
                                const Text(
                                  'Start chatting with your followers',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filteredConversations.length,
                        separatorBuilder: (context, index) => const Divider(
                          color: Colors.white12,
                          height: 1,
                          indent: 72,
                        ),
                        itemBuilder: (context, index) {
                          final conversation = filteredConversations[index];
                          final otherUserId = conversation
                              .getOtherParticipantId(authState.user.id);

                          return FutureBuilder(
                            future: context
                                .read<AuthBloc>()
                                .authRepository
                                .getUserData(otherUserId),
                            builder: (context, snapshot) {
                              final otherUser = snapshot.data;
                              final username =
                                  otherUser?.username ?? 'Loading...';
                              final profileImage = otherUser?.profileImageUrl;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.md,
                                  vertical: AppSizes.sm,
                                ),
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.white12,
                                  backgroundImage:
                                      profileImage != null &&
                                          profileImage.isNotEmpty
                                      ? NetworkImage(profileImage)
                                      : null,
                                  child:
                                      profileImage == null ||
                                          profileImage.isEmpty
                                      ? Text(
                                          username[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  conversation.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                trailing: Text(
                                  timeago.format(conversation.updatedAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white54,
                                  ),
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
                          const Text(
                            'No conversations',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          const Text(
                            'Start chatting with your followers',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showMutualFollowersSheet(authState.user.id),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            child: const HeroIcon(
              HeroIcons.plus,
              size: 24,
              color: Colors.black,
            ),
          ),
        );
      },
    );
  }
}

// Mutual followers bottom sheet widget
class _MutualFollowersSheet extends StatefulWidget {
  final String currentUserId;
  final MessagingRepository messagingRepository;
  final AuthRepository authRepository;
  final Function(String) onUserSelected;

  const _MutualFollowersSheet({
    required this.currentUserId,
    required this.messagingRepository,
    required this.authRepository,
    required this.onUserSelected,
  });

  @override
  State<_MutualFollowersSheet> createState() => _MutualFollowersSheetState();
}

class _MutualFollowersSheetState extends State<_MutualFollowersSheet> {
  List<UserModel>? _mutualFollowers;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMutualFollowers();
  }

  Future<void> _loadMutualFollowers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get mutual follower IDs
      final followerIds = await widget.messagingRepository.getMutualFollowers(
        widget.currentUserId,
      );

      // Fetch user data for each follower
      final followers = <UserModel>[];
      for (final userId in followerIds) {
        try {
          final user = await widget.authRepository.getUserData(userId);
          followers.add(user);
        } catch (e) {
          // Skip users that couldn't be loaded
          continue;
        }
      }

      setState(() {
        _mutualFollowers = followers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                const HeroIcon(
                  HeroIcons.users,
                  style: HeroIconStyle.outline,
                  size: 24,
                  color: Colors.white,
                ),
                const SizedBox(width: AppSizes.sm),
                const Expanded(
                  child: Text(
                    'New Message',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const HeroIcon(
                    HeroIcons.xMark,
                    style: HeroIconStyle.outline,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.lg),
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
                                'Error loading followers',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: AppSizes.xs),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : _mutualFollowers == null || _mutualFollowers!.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const HeroIcon(
                                  HeroIcons.userGroup,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: AppSizes.md),
                                const Text(
                                  'No mutual followers',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.xs),
                                const Text(
                                  'Follow people to start chatting',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSizes.md),
                            itemCount: _mutualFollowers!.length,
                            separatorBuilder: (context, index) => const Divider(
                              color: Colors.white12,
                              height: 1,
                              indent: 72,
                            ),
                            itemBuilder: (context, index) {
                              final user = _mutualFollowers![index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.md,
                                  vertical: AppSizes.sm,
                                ),
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.white12,
                                  backgroundImage: user.profileImageUrl.isNotEmpty
                                      ? NetworkImage(user.profileImageUrl)
                                      : null,
                                  child: user.profileImageUrl.isEmpty
                                      ? Text(
                                          user.username[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  user.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: user.bio.isNotEmpty
                                    ? Text(
                                        user.bio,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      )
                                    : null,
                                onTap: () => widget.onUserSelected(user.id),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// Extension to access authRepository from AuthBloc
extension on AuthBloc {
  AuthRepository get authRepository => AuthRepository();
}
