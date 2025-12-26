import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Draft model for saved but unpublished posts
class DraftModel extends Equatable {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final String category;
  final String? backgroundImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DraftModel({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    required this.category,
    this.backgroundImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DraftModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final now = DateTime.now();
    return DraftModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? 'other',
      backgroundImageUrl: data['backgroundImageUrl'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : now,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : now,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'title': title,
      'content': content,
      'category': category,
      if (backgroundImageUrl != null) 'backgroundImageUrl': backgroundImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        authorId,
        title,
        content,
        category,
        backgroundImageUrl,
        createdAt,
        updatedAt,
      ];
}
