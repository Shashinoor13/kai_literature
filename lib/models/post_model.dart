import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Post model matching Firestore structure
class PostModel extends Equatable {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final String category;
  final String? backgroundImageUrl;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int favoritesCount;
  final double trendingScore;
  final DateTime createdAt;

  const PostModel({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    required this.category,
    this.backgroundImageUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.favoritesCount = 0,
    this.trendingScore = 0.0,
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? 'other',
      backgroundImageUrl: data['backgroundImageUrl'],
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      sharesCount: data['sharesCount'] ?? 0,
      favoritesCount: data['favoritesCount'] ?? 0,
      trendingScore: (data['trendingScore'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'title': title,
      'content': content,
      'category': category,
      if (backgroundImageUrl != null) 'backgroundImageUrl': backgroundImageUrl,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'favoritesCount': favoritesCount,
      'trendingScore': trendingScore,
      'createdAt': Timestamp.fromDate(createdAt),
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
        likesCount,
        commentsCount,
        sharesCount,
        favoritesCount,
        trendingScore,
        createdAt,
      ];
}
