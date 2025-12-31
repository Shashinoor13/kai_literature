import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:literature/features/notifications/bloc/notification_event.dart';
import 'package:literature/features/notifications/bloc/notification_state.dart';
import 'package:literature/repositories/notification_repository.dart';
import 'package:literature/models/notification_model.dart';

/// BLoC for managing notifications
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;

  NotificationBloc({
    required NotificationRepository notificationRepository,
  })  : _notificationRepository = notificationRepository,
        super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<DeleteAllNotifications>(_onDeleteAllNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());

    try {
      // Use emit.forEach to properly handle stream emissions
      await emit.forEach<List<NotificationModel>>(
        _notificationRepository.getUserNotifications(event.userId),
        onData: (notifications) {
          final unreadCount = notifications.where((n) => !n.isRead).length;
          return NotificationLoaded(
            notifications: notifications,
            unreadCount: unreadCount,
          );
        },
        onError: (error, stackTrace) {
          return NotificationError('Failed to load notifications: $error');
        },
      );
    } catch (e) {
      emit(NotificationError('Failed to load notifications: $e'));
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.markAsRead(
        event.userId,
        event.notificationId,
      );
      // The stream will automatically update the state
    } catch (e) {
      emit(NotificationError('Failed to mark notification as read: $e'));
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.markAllAsRead(event.userId);
      // The stream will automatically update the state
    } catch (e) {
      emit(NotificationError('Failed to mark all notifications as read: $e'));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.deleteNotification(
        event.userId,
        event.notificationId,
      );
      // The stream will automatically update the state
    } catch (e) {
      emit(NotificationError('Failed to delete notification: $e'));
    }
  }

  Future<void> _onDeleteAllNotifications(
    DeleteAllNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.deleteAllNotifications(event.userId);
      // The stream will automatically update the state
    } catch (e) {
      emit(NotificationError('Failed to delete all notifications: $e'));
    }
  }
}
