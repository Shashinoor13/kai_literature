import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/features/messaging/bloc/messaging_bloc.dart';
import 'package:literature/features/messaging/bloc/messaging_event.dart';
import 'package:literature/features/messaging/bloc/messaging_state.dart';
import 'package:literature/repositories/auth_repository.dart';

/// Chat Screen - Individual conversation
/// See CLAUDE.md: Messaging (Mutual Follows Only)
class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _authRepository = AuthRepository();
  String? _otherUserId;

  @override
  void initState() {
    super.initState();
    _loadOtherUserId();
    context.read<MessagingBloc>().add(LoadMessages(widget.conversationId));

    // Mark messages as read
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<MessagingBloc>().add(
            MarkMessagesRead(
              conversationId: widget.conversationId,
              currentUserId: authState.user.id,
            ),
          );
    }
  }

  void _loadOtherUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final participants = widget.conversationId.split('_');
    _otherUserId = participants.firstWhere(
      (id) => id != authState.user.id,
      orElse: () => '',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(String senderId) {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    context.read<MessagingBloc>().add(
          SendMessage(
            conversationId: widget.conversationId,
            senderId: senderId,
            content: content,
          ),
        );

    _messageController.clear();
  }

  Future<String> _getOtherUsername() async {
    if (_otherUserId == null || _otherUserId!.isEmpty) return '';

    try {
      final otherUser = await _authRepository.getUserData(_otherUserId!);
      return otherUser.username;
    } catch (e) {
      return '';
    }
  }

  void _navigateToUserProfile() {
    if (_otherUserId != null && _otherUserId!.isNotEmpty) {
      context.push('/user/$_otherUserId');
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
            title: InkWell(
              onTap: _navigateToUserProfile,
              child: FutureBuilder<String>(
                future: _getOtherUsername(),
                builder: (context, snapshot) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(snapshot.data ?? 'Chat'),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  );
                },
              ),
            ),
          ),
          body: Column(
            children: [
              // Messages list
              Expanded(
                child: BlocBuilder<MessagingBloc, MessagingState>(
                  buildWhen: (previous, current) {
                    // Only rebuild when we get new MessagesLoaded for this conversation
                    // or when there's an error
                    if (current is MessagesLoaded &&
                        current.conversationId == widget.conversationId) {
                      return true;
                    }
                    if (current is MessagingError) {
                      return true;
                    }
                    // Don't rebuild for MessageSent or other states
                    return previous is! MessagesLoaded;
                  },
                  builder: (context, state) {
                    if (state is MessagingError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: AppSizes.md),
                            Text(
                              'Error: ${state.message}',
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is MessagesLoaded &&
                        state.conversationId == widget.conversationId) {
                      if (state.messages.isEmpty) {
                        return const Center(
                          child: Text('No messages yet'),
                        );
                      }

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(AppSizes.md),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages[index];
                          final isMe = message.senderId == authState.user.id;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: AppSizes.sm),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.md,
                                vertical: AppSizes.sm,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.content,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: isMe
                                              ? Theme.of(context).colorScheme.onPrimary
                                              : null,
                                        ),
                                  ),
                                  const SizedBox(height: AppSizes.xs),
                                  Text(
                                    timeago.format(message.timestamp),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: isMe
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                                  .withValues(alpha: 0.7)
                                              : null,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }

                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),

              // Message input
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: AppSizes.borderWidth,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(authState.user.id),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _sendMessage(authState.user.id),
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
