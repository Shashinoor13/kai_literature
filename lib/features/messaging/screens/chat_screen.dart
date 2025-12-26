import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
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

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _authRepository = AuthRepository();
  String? _otherUserId;
  String? _otherUsername;
  String? _otherProfileImage;
  bool _isBlocked = false; // TODO: Implement actual blocking check
  bool _isCheckingBlock = true;

  @override
  void initState() {
    super.initState();
    _loadOtherUserId();
    _checkBlockStatus();
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

  Future<void> _checkBlockStatus() async {
    // TODO: Implement actual blocking check with backend
    // For now, just set to false
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _isBlocked = false;
      _isCheckingBlock = false;
    });
  }

  void _loadOtherUserId() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final participants = widget.conversationId.split('_');
    final otherId = participants.firstWhere(
      (id) => id != authState.user.id,
      orElse: () => '',
    );

    try {
      final otherUser = await _authRepository.getUserData(otherId);
      setState(() {
        _otherUserId = otherId;
        _otherUsername = otherUser.username;
        _otherProfileImage = otherUser.profileImageUrl;
      });
    } catch (e) {
      setState(() {
        _otherUserId = otherId;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(String senderId) {
    if (_isBlocked) return;

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
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const HeroIcon(HeroIcons.arrowLeft, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: InkWell(
              onTap: _navigateToUserProfile,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white12,
                    backgroundImage:
                        _otherProfileImage != null &&
                            _otherProfileImage!.isNotEmpty
                        ? NetworkImage(_otherProfileImage!)
                        : null,
                    child:
                        _otherProfileImage == null ||
                            _otherProfileImage!.isEmpty
                        ? Text(
                            (_otherUsername ?? '?')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Flexible(
                    child: Text(
                      _otherUsername ?? 'Chat',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  const HeroIcon(
                    HeroIcons.chevronRight,
                    size: 16,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              // Blocked user banner
              if (!_isCheckingBlock && _isBlocked)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: const BoxDecoration(
                    color: Colors.white12,
                    border: Border(
                      bottom: BorderSide(color: Colors.white24, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const HeroIcon(
                        HeroIcons.noSymbol,
                        size: 20,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          'You have blocked this person and can\'t send messages',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Messages list
              Expanded(
                child: BlocBuilder<MessagingBloc, MessagingState>(
                  buildWhen: (previous, current) {
                    if (current is MessagesLoaded &&
                        current.conversationId == widget.conversationId) {
                      return true;
                    }
                    if (current is MessagingError) {
                      return true;
                    }
                    return previous is! MessagesLoaded;
                  },
                  builder: (context, state) {
                    if (state is MessagingError) {
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HeroIcon(
                                HeroIcons.chatBubbleLeftRight,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: AppSizes.md),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: AppSizes.xs),
                              Text(
                                'Send a message to start the conversation',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
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
                              margin: const EdgeInsets.only(
                                bottom: AppSizes.md,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.md,
                                vertical: AppSizes.sm,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.white : Colors.white12,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      color: isMe ? Colors.black : Colors.white,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: AppSizes.xs),
                                  Text(
                                    timeago.format(message.timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isMe
                                          ? Colors.black54
                                          : Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }

                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                ),
              ),

              // Message input
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    top: BorderSide(color: Colors.white12, width: 1),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            enabled: !_isBlocked,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: InputDecoration(
                              fillColor: Colors.transparent,
                              hintText: 'Message...',
                              hintStyle: const TextStyle(
                                color: Colors.white54,
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              isDense: false,
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: !_isBlocked
                                ? (_) => _sendMessage(authState.user.id)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      GestureDetector(
                        onTap: !_isBlocked
                            ? () => _sendMessage(authState.user.id)
                            : null,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _isBlocked ? Colors.white24 : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: HeroIcon(
                              HeroIcons.paperAirplane,
                              size: 20,
                              color: _isBlocked ? Colors.white38 : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
