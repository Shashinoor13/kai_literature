import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:literature/models/notification_model.dart';

/// Repository for managing notifications
/// See CLAUDE.md: Firebase Architecture > Firestore Collections > notifications/
class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a notification
  /// Used when someone likes, comments, follows, etc.
  Future<void> createNotification({
    required String userId, // The user who will receive the notification
    required NotificationType type,
    required String fromUserId, // The user who triggered the action
    String? fromUsername,
    String? fromUserProfileImage,
    String? postId,
    String? storyId,
  }) async {
    try {
      // Don't create notification if user is notifying themselves
      if (userId == fromUserId) return;

      final notificationRef = _firestore
          .collection('notifications')
          .doc(userId)
          .collection('user_notifications')
          .doc();

      final notification = NotificationModel(
        id: notificationRef.id,
        userId: userId,
        type: type,
        fromUserId: fromUserId,
        fromUsername: fromUsername,
        fromUserProfileImage: fromUserProfileImage,
        postId: postId,
        storyId: storyId,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await notificationRef.set(notification.toFirestore());
    } catch (e) {
      // Silently fail to not disrupt main operations
      // Logging can be added here if needed
    }
  }

  /// Get notifications for a user (stream)
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .doc(userId)
        .collection('user_notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Mark a notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('user_notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('user_notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Get unread notification count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .doc(userId)
        .collection('user_notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Delete a notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('user_notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('user_notifications')
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }
}
