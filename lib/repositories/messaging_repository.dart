import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:literature/features/messaging/models/conversation_model.dart';
import 'package:literature/features/messaging/models/message_model.dart';
import 'package:literature/models/user_model.dart';

/// Messaging repository handling Firestore conversations and messages
/// See CLAUDE.md: Messaging (Mutual Follows Only)
class MessagingRepository {
  final FirebaseFirestore _firestore;

  MessagingRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Check if two users mutually follow each other
  /// Required before allowing DMs (see CLAUDE.md: Mutual Follow Messaging)
  Future<bool> checkMutualFollow(String userId1, String userId2) async {
    try {
      // Check if user1 follows user2
      final follow1 = await _firestore
          .collection('follows')
          .doc('${userId1}_$userId2')
          .get();

      // Check if user2 follows user1
      final follow2 = await _firestore
          .collection('follows')
          .doc('${userId2}_$userId1')
          .get();

      return follow1.exists && follow2.exists;
    } catch (e) {
      return false;
    }
  }

  /// Check if either user has blocked the other
  Future<bool> checkBlockedUsers(String userId1, String userId2) async {
    try {
      // Check if user1 blocked user2
      final block1 = await _firestore
          .collection('blocks')
          .doc('${userId1}_$userId2')
          .get();

      // Check if user2 blocked user1
      final block2 = await _firestore
          .collection('blocks')
          .doc('${userId2}_$userId1')
          .get();

      return block1.exists || block2.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get or create conversation between two users
  /// Only works if mutual follow exists and users are not blocked
  Future<String> getOrCreateConversation(
    String currentUserId,
    String otherUserId,
  ) async {
    // Check if users are blocked first
    final isBlocked = await checkBlockedUsers(currentUserId, otherUserId);
    if (isBlocked) {
      throw Exception('Cannot message blocked users');
    }

    // Check mutual follow
    final isMutualFollow = await checkMutualFollow(currentUserId, otherUserId);
    if (!isMutualFollow) {
      throw Exception('Can only message mutual followers');
    }

    // Create conversation ID (sorted to ensure consistency)
    final participants = [currentUserId, otherUserId]..sort();
    final conversationId = participants.join('_');

    // Check if conversation exists
    final conversationDoc =
        await _firestore.collection('conversations').doc(conversationId).get();

    if (!conversationDoc.exists) {
      // Create new conversation
      final conversation = ConversationModel(
        id: conversationId,
        participants: participants,
        lastMessage: '',
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .set(conversation.toFirestore());
    }

    return conversationId;
  }

  /// Get stream of conversations for a user
  Stream<List<ConversationModel>> getConversationsStream(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConversationModel.fromFirestore(doc))
            .toList());
  }

  /// Send a message
  /// Checks if users are blocked before sending
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String? replyToStoryId,
  }) async {
    // Get conversation to check participants
    final conversationDoc =
        await _firestore.collection('conversations').doc(conversationId).get();

    if (!conversationDoc.exists) {
      throw Exception('Conversation not found');
    }

    final participants =
        List<String>.from(conversationDoc.data()?['participants'] ?? []);
    final otherUserId = participants.firstWhere((id) => id != senderId);

    // Check if users are blocked
    final isBlocked = await checkBlockedUsers(senderId, otherUserId);
    if (isBlocked) {
      throw Exception('Cannot send messages to blocked users');
    }

    final message = MessageModel(
      id: '', // Firestore will generate
      senderId: senderId,
      content: content,
      isRead: false,
      timestamp: DateTime.now(),
      replyToStoryId: replyToStoryId,
    );

    // Add message to messages subcollection
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message.toFirestore());

    // Update conversation's lastMessage and updatedAt
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': content,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Get stream of messages for a conversation
  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(
    String conversationId,
    String currentUserId,
  ) async {
    final unreadMessages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Get mutual followers (users who follow each other)
  Future<List<String>> getMutualFollowers(String userId) async {
    try {
      // Get all users this user follows
      final followingSnapshot = await _firestore
          .collection('follows')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '${userId}_')
          .where(FieldPath.documentId, isLessThan: '${userId}_\uf8ff')
          .get();

      final following = followingSnapshot.docs
          .map((doc) => doc.id.split('_')[1])
          .toList();

      // Check which of those follow back
      final mutualFollowers = <String>[];
      for (final followedUserId in following) {
        final followsBack = await _firestore
            .collection('follows')
            .doc('${followedUserId}_$userId')
            .get();

        if (followsBack.exists) {
          mutualFollowers.add(followedUserId);
        }
      }

      return mutualFollowers;
    } catch (e) {
      throw Exception('Failed to get mutual followers: $e');
    }
  }

  /// Search users by username (for finding people to message)
  Future<List<UserModel>> searchUsers(String query, String currentUserId) async {
    if (query.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.id != currentUserId) // Exclude current user
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}
