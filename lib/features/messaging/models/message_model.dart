import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Message model matching Firestore messages/ subcollection structure
/// See CLAUDE.md: Firebase Architecture > Firestore Collections > messages/
class MessageModel extends Equatable {
  final String id;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime timestamp;
  final String? replyToStoryId; // Optional: when replying to a story

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    this.isRead = false,
    required this.timestamp,
    this.replyToStoryId,
  });

  /// Create MessageModel from Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      isRead: data['isRead'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      replyToStoryId: data['replyToStoryId'],
    );
  }

  /// Convert MessageModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'content': content,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
      if (replyToStoryId != null) 'replyToStoryId': replyToStoryId,
    };
  }

  /// Create a copy with updated fields
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? content,
    bool? isRead,
    DateTime? timestamp,
    String? replyToStoryId,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
      replyToStoryId: replyToStoryId ?? this.replyToStoryId,
    );
  }

  @override
  List<Object?> get props => [id, senderId, content, isRead, timestamp, replyToStoryId];
}
