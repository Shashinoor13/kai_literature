import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:literature/models/user_model.dart';

/// Authentication repository handling Firebase Auth and Firestore user operations
/// Follows BLoC pattern - repository handles data layer only
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get current Firebase user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Sign up with email and password
  /// Returns user ID on success, throws exception on failure
  Future<String> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Check if username is already taken
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw Exception('Username already taken');
      }

      // Create Firebase Auth user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Create Firestore user document
      final userModel = UserModel(
        id: userId,
        username: username,
        email: email,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .set(userModel.toFirestore());

      return userId;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Change password (requires current password for reauthentication)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user currently signed in');
      }

      // Reauthenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Get user data from Firestore
  Future<UserModel> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw Exception('User not found');
      }
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? username,
    String? bio,
    String? profileImageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (bio != null) updates['bio'] = bio;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Stream of user data from Firestore
  Stream<UserModel> getUserDataStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => UserModel.fromFirestore(doc));
  }

  /// Get user by ID (returns null if not found)
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Delete user account
  /// Deletes user from both Firebase Auth and Firestore
  Future<void> deleteAccount(String userId) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No user currently signed in');
    }

    try {
      // Delete Firebase Auth user FIRST
      // If this fails (e.g., requires-recent-login), we don't delete Firestore data
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('Please sign in again to delete your account');
      }
      throw Exception('Failed to delete authentication: ${e.message}');
    }

    try {
      // Delete Firestore user document
      // Even if this fails, auth user is already deleted
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      // Log error but don't throw - auth deletion already succeeded
      // In production, you'd log this to error tracking service
      throw Exception('Authentication deleted but failed to clean up user data: $e');
    }

    // Sign out to clear any cached state
    await signOut();
  }

  /// Block a user
  /// Creates a block document and removes follow relationships (both ways)
  Future<void> blockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Create block document
      batch.set(
        _firestore.collection('blocks').doc('${currentUserId}_$blockedUserId'),
        {
          'blockerId': currentUserId,
          'blockedId': blockedUserId,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Check if current user follows blocked user
      final currentFollowsBlocked = await _firestore
          .collection('follows')
          .doc('${currentUserId}_$blockedUserId')
          .get();

      if (currentFollowsBlocked.exists) {
        // Remove follow relationship (current -> blocked)
        batch.delete(
          _firestore.collection('follows').doc('${currentUserId}_$blockedUserId'),
        );

        // Decrement following count for current user
        batch.update(
          _firestore.collection('users').doc(currentUserId),
          {'followingCount': FieldValue.increment(-1)},
        );

        // Decrement followers count for blocked user
        batch.update(
          _firestore.collection('users').doc(blockedUserId),
          {'followersCount': FieldValue.increment(-1)},
        );
      }

      // Check if blocked user follows current user
      final blockedFollowsCurrent = await _firestore
          .collection('follows')
          .doc('${blockedUserId}_$currentUserId')
          .get();

      if (blockedFollowsCurrent.exists) {
        // Remove follow relationship (blocked -> current)
        batch.delete(
          _firestore.collection('follows').doc('${blockedUserId}_$currentUserId'),
        );

        // Decrement following count for blocked user
        batch.update(
          _firestore.collection('users').doc(blockedUserId),
          {'followingCount': FieldValue.increment(-1)},
        );

        // Decrement followers count for current user
        batch.update(
          _firestore.collection('users').doc(currentUserId),
          {'followersCount': FieldValue.increment(-1)},
        );
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  /// Unblock a user
  /// Deletes the block document
  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    try {
      await _firestore
          .collection('blocks')
          .doc('${currentUserId}_$blockedUserId')
          .delete();
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  /// Check if current user has blocked another user
  Future<bool> isUserBlocked({
    required String currentUserId,
    required String userId,
  }) async {
    try {
      final doc = await _firestore
          .collection('blocks')
          .doc('${currentUserId}_$userId')
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get list of blocked user IDs
  Future<List<String>> getBlockedUserIds(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('blocks')
          .where('blockerId', isEqualTo: currentUserId)
          .get();

      return snapshot.docs.map((doc) => doc.data()['blockedId'] as String).toList();
    } catch (e) {
      throw Exception('Failed to get blocked users: $e');
    }
  }

  /// Get blocked users with full user data
  Future<List<UserModel>> getBlockedUsers(String currentUserId) async {
    try {
      final blockedIds = await getBlockedUserIds(currentUserId);

      if (blockedIds.isEmpty) return [];

      final users = <UserModel>[];
      for (final userId in blockedIds) {
        try {
          final user = await getUserData(userId);
          users.add(user);
        } catch (e) {
          // Skip if user not found
          continue;
        }
      }

      return users;
    } catch (e) {
      throw Exception('Failed to get blocked users: $e');
    }
  }

  /// Search users by username (excludes current user and blocked users)
  /// Returns list of users whose username contains the search query (case-insensitive)
  Future<List<UserModel>> searchUsers(String query, {String? currentUserId}) async {
    try {
      if (query.isEmpty) return [];

      final lowercaseQuery = query.toLowerCase();

      // Get blocked user IDs if currentUserId provided
      final blockedIds = currentUserId != null
          ? await getBlockedUserIds(currentUserId)
          : <String>[];

      // Get all users and filter in-memory for substring matching
      // Note: Firestore doesn't support case-insensitive or substring queries natively
      final snapshot = await _firestore.collection('users').get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) {
            // Filter out current user
            if (currentUserId != null && user.id == currentUserId) return false;

            // Filter out blocked users
            if (blockedIds.contains(user.id)) return false;

            // Filter by search query
            return user.username.toLowerCase().contains(lowercaseQuery);
          })
          .toList();

      return users;
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  /// Follow a user
  /// Checks if users are blocked before allowing follow
  Future<void> followUser({
    required String followerId,
    required String followingId,
  }) async {
    try {
      // Check if either user has blocked the other
      final followerBlockedFollowing = await isUserBlocked(
        currentUserId: followerId,
        userId: followingId,
      );

      final followingBlockedFollower = await isUserBlocked(
        currentUserId: followingId,
        userId: followerId,
      );

      if (followerBlockedFollowing || followingBlockedFollower) {
        throw Exception('Cannot follow blocked users');
      }

      final batch = _firestore.batch();

      // Create follow relationship document
      batch.set(
        _firestore.collection('follows').doc('${followerId}_$followingId'),
        {
          'followerId': followerId,
          'followingId': followingId,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Increment follower's following count
      batch.update(
        _firestore.collection('users').doc(followerId),
        {'followingCount': FieldValue.increment(1)},
      );

      // Increment following user's followers count
      batch.update(
        _firestore.collection('users').doc(followingId),
        {'followersCount': FieldValue.increment(1)},
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Delete follow relationship document
      batch.delete(
        _firestore.collection('follows').doc('${followerId}_$followingId'),
      );

      // Decrement follower's following count
      batch.update(
        _firestore.collection('users').doc(followerId),
        {'followingCount': FieldValue.increment(-1)},
      );

      // Decrement following user's followers count
      batch.update(
        _firestore.collection('users').doc(followingId),
        {'followersCount': FieldValue.increment(-1)},
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  /// Check if user A follows user B
  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    try {
      final doc = await _firestore
          .collection('follows')
          .doc('${followerId}_$followingId')
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get list of followers for a user
  Future<List<UserModel>> getFollowers(String userId) async {
    try {
      // Get all follow documents where followingId == userId
      final snapshot = await _firestore
          .collection('follows')
          .where('followingId', isEqualTo: userId)
          .get();

      // Extract follower IDs
      final followerIds = snapshot.docs
          .map((doc) => doc.data()['followerId'] as String)
          .toList();

      if (followerIds.isEmpty) return [];

      // Get user documents for all followers
      final users = <UserModel>[];
      for (final followerId in followerIds) {
        final userDoc = await _firestore.collection('users').doc(followerId).get();
        if (userDoc.exists) {
          users.add(UserModel.fromFirestore(userDoc));
        }
      }

      return users;
    } catch (e) {
      throw Exception('Failed to get followers: $e');
    }
  }

  /// Get list of users that a user is following
  Future<List<UserModel>> getFollowing(String userId) async {
    try {
      // Get all follow documents where followerId == userId
      final snapshot = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .get();

      // Extract following IDs
      final followingIds = snapshot.docs
          .map((doc) => doc.data()['followingId'] as String)
          .toList();

      if (followingIds.isEmpty) return [];

      // Get user documents for all following users
      final users = <UserModel>[];
      for (final followingId in followingIds) {
        final userDoc = await _firestore.collection('users').doc(followingId).get();
        if (userDoc.exists) {
          users.add(UserModel.fromFirestore(userDoc));
        }
      }

      return users;
    } catch (e) {
      throw Exception('Failed to get following: $e');
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No account found with this email. Please check your email or sign up.';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Email/password sign in is not enabled';
      case 'invalid-action-code':
        return 'The password reset link is invalid or has expired';
      case 'expired-action-code':
        return 'The password reset link has expired. Please request a new one.';
      case 'missing-email':
        return 'Please enter an email address';
      default:
        return 'Authentication error: ${e.message ?? 'Unknown error'}';
    }
  }
}
