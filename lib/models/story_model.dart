import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Story model for temporary posts (7 days expiry)
class StoryModel extends Equatable {
  final String id;
  final String authorId;
  final String type; // 'text'
  final String title;
  final String textContent;
  final String category;
  final String? backgroundImageUrl;
  final String backgroundColor; // 'black' or 'white'
  final int duration; // default 5 seconds
  final int viewsCount;
  final DateTime createdAt;
  final DateTime expiresAt;

  const StoryModel({
    required this.id,
    required this.authorId,
    this.type = 'text',
    required this.title,
    required this.textContent,
    required this.category,
    this.backgroundImageUrl,
    this.backgroundColor = 'black',
    this.duration = 5,
    this.viewsCount = 0,
    required this.createdAt,
    required this.expiresAt,
  });

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoryModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      type: data['type'] ?? 'text',
      title: data['title'] ?? '',
      textContent: data['textContent'] ?? '',
      category: data['category'] ?? 'other',
      backgroundImageUrl: data['backgroundImageUrl'],
      backgroundColor: data['backgroundColor'] ?? 'black',
      duration: data['duration'] ?? 5,
      viewsCount: data['viewsCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'type': type,
      'title': title,
      'textContent': textContent,
      'category': category,
      if (backgroundImageUrl != null) 'backgroundImageUrl': backgroundImageUrl,
      'backgroundColor': backgroundColor,
      'duration': duration,
      'viewsCount': viewsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        authorId,
        type,
        title,
        textContent,
        category,
        backgroundImageUrl,
        backgroundColor,
        duration,
        viewsCount,
        createdAt,
        expiresAt,
      ];
}
