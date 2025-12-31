import 'package:equatable/equatable.dart';

/// Events for NotificationBloc
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load notifications for the current user
class LoadNotifications extends NotificationEvent {
  final String userId;

  const LoadNotifications(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Mark a notification as read
class MarkNotificationAsRead extends NotificationEvent {
  final String userId;
  final String notificationId;

  const MarkNotificationAsRead(this.userId, this.notificationId);

  @override
  List<Object?> get props => [userId, notificationId];
}

/// Mark all notifications as read
class MarkAllNotificationsAsRead extends NotificationEvent {
  final String userId;

  const MarkAllNotificationsAsRead(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Delete a notification
class DeleteNotification extends NotificationEvent {
  final String userId;
  final String notificationId;

  const DeleteNotification(this.userId, this.notificationId);

  @override
  List<Object?> get props => [userId, notificationId];
}

/// Delete all notifications
class DeleteAllNotifications extends NotificationEvent {
  final String userId;

  const DeleteAllNotifications(this.userId);

  @override
  List<Object?> get props => [userId];
}
