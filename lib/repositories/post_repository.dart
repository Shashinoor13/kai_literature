import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:literature/models/post_model.dart';
import 'package:literature/models/draft_model.dart';
import 'package:literature/models/comment_model.dart';
import 'package:literature/models/story_model.dart';
import 'package:literature/models/report_reason.dart';
import 'dart:io';

/// Repository for posts, drafts, and stories
class PostRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  PostRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  /// Create a new post
  Future<String> createPost({
    required String authorId,
    required String title,
    required String content,
    required String category,
    String? backgroundImageUrl,
  }) async {
    try {
      final docRef = await _firestore.collection('posts').add({
        'authorId': authorId,
        'title': title,
        'content': content,
        'category': category,
        if (backgroundImageUrl != null)
          'backgroundImageUrl': backgroundImageUrl,
        'likesCount': 0,
        'commentsCount': 0,
        'sharesCount': 0,
        'favoritesCount': 0,
        'trendingScore': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  /// Save as draft
  Future<String> saveDraft({
    required String authorId,
    required String title,
    required String content,
    required String category,
    String? backgroundImageUrl,
    String? draftId,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      final data = {
        'authorId': authorId,
        'title': title,
        'content': content,
        'category': category,
        if (backgroundImageUrl != null)
          'backgroundImageUrl': backgroundImageUrl,
        'updatedAt': now,
      };

      if (draftId != null) {
        // Update existing draft
        await _firestore.collection('drafts').doc(draftId).update(data);
        return draftId;
      } else {
        // Create new draft
        data['createdAt'] = now;
        final docRef = await _firestore.collection('drafts').add(data);
        return docRef.id;
      }
    } catch (e) {
      throw Exception('Failed to save draft: $e');
    }
  }

  /// Create a story (7 days expiry)
  Future<String> createStory({
    required String authorId,
    required String title,
    required String content,
    required String category,
    String? backgroundImageUrl,
    String backgroundColor = 'black',
  }) async {
    try {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 7));

      final docRef = await _firestore.collection('stories').add({
        'authorId': authorId,
        'type': 'text',
        'title': title,
        'textContent': content,
        'category': category,
        if (backgroundImageUrl != null)
          'backgroundImageUrl': backgroundImageUrl,
        'backgroundColor': backgroundColor,
        'duration': 5,
        'viewsCount': 0,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });

      // Update user's hasActiveStory field
      await _firestore.collection('users').doc(authorId).update({
        'hasActiveStory': true,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create story: $e');
    }
  }

  /// Get active stories from users the current user follows
  /// Returns stories that haven't expired yet, filtered by following list
  Stream<List<StoryModel>> getActiveStories(String currentUserId) async* {
    final now = DateTime.now();

    // Get list of users that current user follows
    final followsSnapshot = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: currentUserId)
        .get();

    final followingIds = followsSnapshot.docs
        .map((doc) => doc.data()['followingId'] as String)
        .toSet();

    // Add current user's ID to see their own stories
    followingIds.add(currentUserId);

    // Stream all active stories and filter by following list
    await for (final snapshot in _firestore
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()) {

      final stories = snapshot.docs
          .map((doc) => StoryModel.fromFirestore(doc))
          .where((story) => followingIds.contains(story.authorId))
          .toList();

      yield stories;
    }
  }

  /// Get stories by a specific user
  Stream<List<StoryModel>> getUserStories(String userId) {
    final now = DateTime.now();
    return _firestore
        .collection('stories')
        .where('authorId', isEqualTo: userId)
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StoryModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Delete a story
  Future<void> deleteStory(String storyId, String authorId) async {
    try {
      await _firestore.collection('stories').doc(storyId).delete();

      // Check if user has any other active stories
      final now = DateTime.now();
      final userStories = await _firestore
          .collection('stories')
          .where('authorId', isEqualTo: authorId)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
          .get();

      // Update hasActiveStory if no more active stories
      if (userStories.docs.isEmpty) {
        await _firestore.collection('users').doc(authorId).update({
          'hasActiveStory': false,
        });
      }
    } catch (e) {
      throw Exception('Failed to delete story: $e');
    }
  }

  /// Upload background image to Firebase Storage
  Future<String> uploadBackgroundImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final fileName =
          'background_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('posts/$userId/$fileName');

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Get user's drafts
  Stream<List<DraftModel>> getUserDrafts(String userId) {
    return _firestore
        .collection('drafts')
        .where('authorId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DraftModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Delete draft
  Future<void> deleteDraft(String draftId) async {
    try {
      await _firestore.collection('drafts').doc(draftId).delete();
    } catch (e) {
      throw Exception('Failed to delete draft: $e');
    }
  }

  /// Get a single post by ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      if (doc.exists) {
        return PostModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get post: $e');
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  /// Update a post
  Future<void> updatePost({
    required String postId,
    required String title,
    required String content,
    required String category,
  }) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'title': title,
        'content': content,
        'category': category,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  /// Get feed posts (all posts - recommended)
  Stream<List<PostModel>> getFeedPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList(),
        );
  }

  /// Get posts from users the current user follows
  Stream<List<PostModel>> getFollowingFeedPosts(String currentUserId) async* {
    // Get list of users that current user follows
    final followsSnapshot = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: currentUserId)
        .get();

    final followingIds = followsSnapshot.docs
        .map((doc) => doc.data()['followingId'] as String)
        .toSet();

    if (followingIds.isEmpty) {
      yield [];
      return;
    }

    // Stream posts from followed users
    await for (final snapshot in _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .where((post) => followingIds.contains(post.authorId))
          .toList();

      yield posts;
    }
  }

  /// Get posts by category
  Stream<List<PostModel>> getPostsByCategory(String category) {
    return _firestore
        .collection('posts')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList(),
        );
  }

  /// Get posts from following users filtered by category
  Stream<List<PostModel>> getFollowingPostsByCategory(
    String currentUserId,
    String category,
  ) async* {
    // Get list of users that current user follows
    final followsSnapshot = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: currentUserId)
        .get();

    final followingIds = followsSnapshot.docs
        .map((doc) => doc.data()['followingId'] as String)
        .toSet();

    if (followingIds.isEmpty) {
      yield [];
      return;
    }

    // Stream posts from followed users filtered by category
    await for (final snapshot in _firestore
        .collection('posts')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .where((post) => followingIds.contains(post.authorId))
          .toList();

      yield posts;
    }
  }

  /// Get user's posts
  /// Requires composite index: (authorId, createdAt DESC)
  Stream<List<PostModel>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList(),
        );
  }

  /// Search posts by content or title (excludes posts from blocked users)
  /// Returns list of posts whose title or content contains the search query (case-insensitive)
  Future<List<PostModel>> searchPosts(String query, {List<String>? blockedUserIds}) async {
    try {
      if (query.isEmpty) return [];

      final lowercaseQuery = query.toLowerCase();
      final blockedIds = blockedUserIds ?? [];

      // Get recent posts and filter in-memory for substring matching
      // Note: Firestore doesn't support full-text search natively
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(100) // Limit to recent 100 posts for performance
          .get();

      final posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .where((post) {
            // Filter out posts from blocked users
            if (blockedIds.contains(post.authorId)) return false;

            // Filter by search query
            return post.title.toLowerCase().contains(lowercaseQuery) ||
                post.content.toLowerCase().contains(lowercaseQuery);
          })
          .toList();

      return posts;
    } catch (e) {
      throw Exception('Failed to search posts: $e');
    }
  }

  /// Like a post
  Future<void> likePost({required String userId, required String postId}) async {
    try {
      final batch = _firestore.batch();

      // Add like document
      batch.set(
        _firestore.collection('likes').doc('${userId}_$postId'),
        {
          'userId': userId,
          'postId': postId,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Increment likes count
      batch.update(
        _firestore.collection('posts').doc(postId),
        {'likesCount': FieldValue.increment(1)},
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  /// Unlike a post
  Future<void> unlikePost({required String userId, required String postId}) async {
    try {
      final batch = _firestore.batch();

      // Remove like document
      batch.delete(_firestore.collection('likes').doc('${userId}_$postId'));

      // Decrement likes count
      batch.update(
        _firestore.collection('posts').doc(postId),
        {'likesCount': FieldValue.increment(-1)},
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to unlike post: $e');
    }
  }

  /// Check if user has liked a post
  Future<bool> hasUserLikedPost({required String userId, required String postId}) async {
    try {
      final doc = await _firestore.collection('likes').doc('${userId}_$postId').get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Favorite a post
  Future<void> favoritePost({required String userId, required String postId}) async {
    try {
      final batch = _firestore.batch();

      // Add favorite document
      batch.set(
        _firestore.collection('favorites').doc('${userId}_$postId'),
        {
          'userId': userId,
          'postId': postId,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Increment favorites count
      batch.update(
        _firestore.collection('posts').doc(postId),
        {'favoritesCount': FieldValue.increment(1)},
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to favorite post: $e');
    }
  }

  /// Unfavorite a post
  Future<void> unfavoritePost({required String userId, required String postId}) async {
    try {
      final batch = _firestore.batch();

      // Remove favorite document
      batch.delete(_firestore.collection('favorites').doc('${userId}_$postId'));

      // Decrement favorites count
      batch.update(
        _firestore.collection('posts').doc(postId),
        {'favoritesCount': FieldValue.increment(-1)},
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to unfavorite post: $e');
    }
  }

  /// Check if user has favorited a post
  Future<bool> hasUserFavoritedPost({required String userId, required String postId}) async {
    try {
      final doc = await _firestore.collection('favorites').doc('${userId}_$postId').get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Share a post (increment share count)
  Future<void> sharePost({required String userId, required String postId}) async {
    try {
      final batch = _firestore.batch();

      // Add share document
      batch.set(
        _firestore.collection('shares').doc('${userId}_$postId'),
        {
          'userId': userId,
          'postId': postId,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Increment shares count
      batch.update(
        _firestore.collection('posts').doc(postId),
        {'sharesCount': FieldValue.increment(1)},
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to share post: $e');
    }
  }

  /// Add a comment to a post
  Future<String> addComment({
    required String postId,
    required String authorId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Add comment document
      final commentRef = _firestore.collection('comments').doc();
      batch.set(commentRef, {
        'postId': postId,
        'authorId': authorId,
        'content': content,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Increment comments count on the post
      batch.update(
        _firestore.collection('posts').doc(postId),
        {'commentsCount': FieldValue.increment(1)},
      );

      await batch.commit();
      return commentRef.id;
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Get comments for a post (stream)
  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId, String postId) async {
    try {
      final batch = _firestore.batch();

      // Delete comment document
      batch.delete(_firestore.collection('comments').doc(commentId));

      // Decrement comments count
      batch.update(
        _firestore.collection('posts').doc(postId),
        {'commentsCount': FieldValue.increment(-1)},
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  /// Get posts liked by user
  Stream<List<PostModel>> getLikedPosts(String userId) {
    return _firestore
        .collection('likes')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final posts = <PostModel>[];
      for (final doc in snapshot.docs) {
        final postId = doc.data()['postId'] as String;
        try {
          final postDoc = await _firestore.collection('posts').doc(postId).get();
          if (postDoc.exists) {
            posts.add(PostModel.fromFirestore(postDoc));
          }
        } catch (e) {
          // Skip if post not found
          continue;
        }
      }
      return posts;
    });
  }

  /// Get posts favorited by user
  Stream<List<PostModel>> getFavoritedPosts(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final posts = <PostModel>[];
      for (final doc in snapshot.docs) {
        final postId = doc.data()['postId'] as String;
        try {
          final postDoc = await _firestore.collection('posts').doc(postId).get();
          if (postDoc.exists) {
            posts.add(PostModel.fromFirestore(postDoc));
          }
        } catch (e) {
          // Skip if post not found
          continue;
        }
      }
      return posts;
    });
  }

  /// Get posts commented on by user
  Stream<List<PostModel>> getCommentedPosts(String userId) {
    return _firestore
        .collection('comments')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final posts = <PostModel>[];
      final seenPostIds = <String>{};

      for (final doc in snapshot.docs) {
        final postId = doc.data()['postId'] as String;

        // Skip if we've already added this post
        if (seenPostIds.contains(postId)) continue;
        seenPostIds.add(postId);

        try {
          final postDoc = await _firestore.collection('posts').doc(postId).get();
          if (postDoc.exists) {
            posts.add(PostModel.fromFirestore(postDoc));
          }
        } catch (e) {
          // Skip if post not found
          continue;
        }
      }
      return posts;
    });
  }

  /// Report a post
  /// Creates a report document in Firestore for admin review
  Future<void> reportPost({
    required String postId,
    required String reporterId,
    required ReportReason reason,
    String? additionalDetails,
  }) async {
    try {
      final reportRef = _firestore.collection('reports').doc();
      final report = PostReport(
        reportId: reportRef.id,
        postId: postId,
        reporterId: reporterId,
        reason: reason,
        additionalDetails: additionalDetails,
        createdAt: DateTime.now(),
      );

      await reportRef.set(report.toFirestore());
    } catch (e) {
      throw Exception('Failed to report post: $e');
    }
  }
}
