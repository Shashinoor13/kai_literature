import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// User model matching Firestore users/ collection structure
/// See CLAUDE.md: Firebase Architecture > Firestore Collections > users/
class UserModel extends Equatable {
  final String id;
  final String username;
  final String email;
  final String bio;
  final String profileImageUrl;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool hasActiveStory;
  final DateTime? dateOfBirth;  // Optional for existing users
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.bio = '',
    this.profileImageUrl = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.hasActiveStory = false,
    this.dateOfBirth,
    required this.createdAt,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      bio: data['bio'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      postsCount: data['postsCount'] ?? 0,
      hasActiveStory: data['hasActiveStory'] ?? false,
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert UserModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'hasActiveStory': hasActiveStory,
      if (dateOfBirth != null) 'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? bio,
    String? profileImageUrl,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? hasActiveStory,
    DateTime? dateOfBirth,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      hasActiveStory: hasActiveStory ?? this.hasActiveStory,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        bio,
        profileImageUrl,
        followersCount,
        followingCount,
        postsCount,
        hasActiveStory,
        dateOfBirth,
        createdAt,
      ];
}
