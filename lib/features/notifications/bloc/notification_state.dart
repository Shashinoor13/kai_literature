import 'package:equatable/equatable.dart';
import 'package:literature/models/notification_model.dart';

/// States for NotificationBloc
abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class NotificationInitial extends NotificationState {}

/// Loading state
class NotificationLoading extends NotificationState {}

/// Loaded state
class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationLoaded({
    required this.notifications,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [notifications, unreadCount];

  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Error state
class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
