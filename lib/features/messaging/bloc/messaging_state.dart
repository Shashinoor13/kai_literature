import 'package:equatable/equatable.dart';
import 'package:literature/features/messaging/models/conversation_model.dart';
import 'package:literature/features/messaging/models/message_model.dart';
import 'package:literature/models/user_model.dart';

/// Messaging states
abstract class MessagingState extends Equatable {
  const MessagingState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class MessagingInitial extends MessagingState {}

/// Loading state
class MessagingLoading extends MessagingState {}

/// Conversations loaded
class ConversationsLoaded extends MessagingState {
  final List<ConversationModel> conversations;

  const ConversationsLoaded(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

/// Messages loaded for a conversation
class MessagesLoaded extends MessagingState {
  final String conversationId;
  final List<MessageModel> messages;

  const MessagesLoaded({
    required this.conversationId,
    required this.messages,
  });

  @override
  List<Object?> get props => [conversationId, messages];
}

/// Message sent successfully
class MessageSent extends MessagingState {}

/// Conversation created successfully
class ConversationCreated extends MessagingState {
  final String conversationId;

  const ConversationCreated(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// User search results
class UserSearchResults extends MessagingState {
  final List<UserModel> users;

  const UserSearchResults(this.users);

  @override
  List<Object?> get props => [users];
}

/// Error state
class MessagingError extends MessagingState {
  final String message;

  const MessagingError(this.message);

  @override
  List<Object?> get props => [message];
}
