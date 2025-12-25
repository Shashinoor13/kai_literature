import 'package:bloc/bloc.dart';
import 'package:literature/features/messaging/bloc/messaging_event.dart';
import 'package:literature/features/messaging/bloc/messaging_state.dart';
import 'package:literature/repositories/messaging_repository.dart';

/// Messaging BLoC
/// Handles all messaging-related business logic
/// See CLAUDE.md: Messaging (Mutual Follows Only)
class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final MessagingRepository _messagingRepository;

  MessagingBloc({
    required MessagingRepository messagingRepository,
  })  : _messagingRepository = messagingRepository,
        super(MessagingInitial()) {
    // Register event handlers
    on<LoadConversations>(_onLoadConversations);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<CreateConversation>(_onCreateConversation);
    on<MarkMessagesRead>(_onMarkMessagesRead);
    on<SearchUsersToChat>(_onSearchUsersToChat);
  }

  /// Load conversations
  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      // Use emit.forEach to properly handle stream emissions
      await emit.forEach(
        _messagingRepository.getConversationsStream(event.userId),
        onData: (conversations) => ConversationsLoaded(conversations),
        onError: (error, stackTrace) => MessagingError(error.toString()),
      );
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }

  /// Load messages for a conversation
  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      // Use emit.forEach to properly handle stream emissions
      await emit.forEach(
        _messagingRepository.getMessagesStream(event.conversationId),
        onData: (messages) => MessagesLoaded(
          conversationId: event.conversationId,
          messages: messages,
        ),
        onError: (error, stackTrace) => MessagingError(error.toString()),
      );
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }

  /// Send a message
  /// Note: Does not emit state - the stream will automatically update
  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      await _messagingRepository.sendMessage(
        conversationId: event.conversationId,
        senderId: event.senderId,
        content: event.content,
        replyToStoryId: event.replyToStoryId,
      );
      // Don't emit MessageSent - let the stream handle the update
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }

  /// Create or get conversation
  Future<void> _onCreateConversation(
    CreateConversation event,
    Emitter<MessagingState> emit,
  ) async {
    emit(MessagingLoading());
    try {
      final conversationId = await _messagingRepository.getOrCreateConversation(
        event.currentUserId,
        event.otherUserId,
      );
      emit(ConversationCreated(conversationId));
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }

  /// Mark messages as read
  Future<void> _onMarkMessagesRead(
    MarkMessagesRead event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      await _messagingRepository.markMessagesAsRead(
        event.conversationId,
        event.currentUserId,
      );
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }

  /// Search users to chat with
  Future<void> _onSearchUsersToChat(
    SearchUsersToChat event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      final users = await _messagingRepository.searchUsers(
        event.query,
        event.currentUserId,
      );
      emit(UserSearchResults(users));
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }

}
