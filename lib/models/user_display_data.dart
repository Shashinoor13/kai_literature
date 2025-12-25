import 'package:literature/models/user_model.dart';

/// Model representing user data for display purposes
/// Includes computed fields for UI rendering
class UserDisplayData {
  final String userId;
  final String username;
  final String initial;
  final String? bio;
  final String? profileImageUrl;

  const UserDisplayData({
    required this.userId,
    required this.username,
    required this.initial,
    this.bio,
    this.profileImageUrl,
  });

  /// Create from UserModel
  factory UserDisplayData.fromUser(UserModel user) {
    return UserDisplayData(
      userId: user.id,
      username: user.username,
      initial: user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
      bio: user.bio,
      profileImageUrl: user.profileImageUrl,
    );
  }

  /// Create a loading/unknown user
  factory UserDisplayData.unknown({String userId = ''}) {
    return UserDisplayData(
      userId: userId,
      username: 'Unknown',
      initial: '?',
    );
  }

  /// Check if this is an unknown/loading user
  bool get isUnknown => username == 'Unknown';

  /// Check if user has profile image
  bool get hasProfileImage => profileImageUrl != null && profileImageUrl!.isNotEmpty;

  /// Check if user has bio
  bool get hasBio => bio != null && bio!.isNotEmpty;
}
