import 'package:cloud_firestore/cloud_firestore.dart';

/// Comment model for post comments
class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final String? parentCommentId;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    this.parentCommentId,
    required this.createdAt,
  });

  /// Create CommentModel from Firestore document
  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      postId: data['postId'] as String,
      authorId: data['authorId'] as String,
      content: data['content'] as String,
      parentCommentId: data['parentCommentId'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert CommentModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'content': content,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
