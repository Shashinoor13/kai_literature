import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification types as per CLAUDE.md
enum NotificationType {
  follow,
  like,
  comment,
  message,
  storyView,
  storyReaction,
}

/// Notification model matching Firestore notifications/ collection structure
/// See CLAUDE.md: Firebase Architecture > Firestore Collections > notifications/
class NotificationModel extends Equatable {
  final String id;
  final String userId; // The user receiving the notification
  final NotificationType type;
  final String fromUserId; // The user who triggered the notification
  final String? fromUsername; // Cached username for display
  final String? fromUserProfileImage; // Cached profile image
  final String? postId;
  final String? storyId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.fromUserId,
    this.fromUsername,
    this.fromUserProfileImage,
    this.postId,
    this.storyId,
    this.isRead = false,
    required this.createdAt,
  });

  /// Create NotificationModel from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: _typeFromString(data['type'] ?? 'like'),
      fromUserId: data['fromUserId'] ?? '',
      fromUsername: data['fromUsername'],
      fromUserProfileImage: data['fromUserProfileImage'],
      postId: data['postId'],
      storyId: data['storyId'],
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert NotificationModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': _typeToString(type),
      'fromUserId': fromUserId,
      if (fromUsername != null) 'fromUsername': fromUsername,
      if (fromUserProfileImage != null)
        'fromUserProfileImage': fromUserProfileImage,
      if (postId != null) 'postId': postId,
      if (storyId != null) 'storyId': storyId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? fromUserId,
    String? fromUsername,
    String? fromUserProfileImage,
    String? postId,
    String? storyId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUsername: fromUsername ?? this.fromUsername,
      fromUserProfileImage: fromUserProfileImage ?? this.fromUserProfileImage,
      postId: postId ?? this.postId,
      storyId: storyId ?? this.storyId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get notification message text
  String getMessage() {
    switch (type) {
      case NotificationType.follow:
        return '${fromUsername ?? 'Someone'} started following you';
      case NotificationType.like:
        return '${fromUsername ?? 'Someone'} liked your post';
      case NotificationType.comment:
        return '${fromUsername ?? 'Someone'} commented on your post';
      case NotificationType.message:
        return '${fromUsername ?? 'Someone'} sent you a message';
      case NotificationType.storyView:
        return '${fromUsername ?? 'Someone'} viewed your story';
      case NotificationType.storyReaction:
        return '${fromUsername ?? 'Someone'} reacted to your story';
    }
  }

  /// Helper: Convert string to NotificationType
  static NotificationType _typeFromString(String type) {
    switch (type) {
      case 'follow':
        return NotificationType.follow;
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'message':
        return NotificationType.message;
      case 'story_view':
        return NotificationType.storyView;
      case 'story_reaction':
        return NotificationType.storyReaction;
      default:
        return NotificationType.like;
    }
  }

  /// Helper: Convert NotificationType to string
  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.follow:
        return 'follow';
      case NotificationType.like:
        return 'like';
      case NotificationType.comment:
        return 'comment';
      case NotificationType.message:
        return 'message';
      case NotificationType.storyView:
        return 'story_view';
      case NotificationType.storyReaction:
        return 'story_reaction';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        fromUserId,
        fromUsername,
        fromUserProfileImage,
        postId,
        storyId,
        isRead,
        createdAt,
      ];
}
