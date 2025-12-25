import 'package:equatable/equatable.dart';

/// Messaging events
abstract class MessagingEvent extends Equatable {
  const MessagingEvent();

  @override
  List<Object?> get props => [];
}

/// Load conversations for current user
class LoadConversations extends MessagingEvent {
  final String userId;

  const LoadConversations(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Load messages for a conversation
class LoadMessages extends MessagingEvent {
  final String conversationId;

  const LoadMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Send a message
class SendMessage extends MessagingEvent {
  final String conversationId;
  final String senderId;
  final String content;
  final String? replyToStoryId;

  const SendMessage({
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.replyToStoryId,
  });

  @override
  List<Object?> get props => [conversationId, senderId, content, replyToStoryId];
}

/// Create or get conversation with a user
class CreateConversation extends MessagingEvent {
  final String currentUserId;
  final String otherUserId;

  const CreateConversation({
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  List<Object?> get props => [currentUserId, otherUserId];
}

/// Mark messages as read
class MarkMessagesRead extends MessagingEvent {
  final String conversationId;
  final String currentUserId;

  const MarkMessagesRead({
    required this.conversationId,
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [conversationId, currentUserId];
}

/// Search users to chat with
class SearchUsersToChat extends MessagingEvent {
  final String query;
  final String currentUserId;

  const SearchUsersToChat({
    required this.query,
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [query, currentUserId];
}
