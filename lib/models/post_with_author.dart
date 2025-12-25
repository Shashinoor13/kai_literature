import 'package:literature/models/post_model.dart';
import 'package:literature/models/user_model.dart';

/// Model combining post data with author information
/// Useful for displaying posts with author details
class PostWithAuthor {
  final PostModel post;
  final UserModel? author;

  const PostWithAuthor({
    required this.post,
    this.author,
  });

  /// Get author username with fallback
  String get authorUsername => author?.username ?? 'Unknown';

  /// Get author initial for avatar
  String get authorInitial =>
      author?.username[0].toUpperCase() ?? '?';

  /// Check if author data is loaded
  bool get hasAuthor => author != null;

  /// Get post ID
  String get postId => post.id;

  /// Get author ID
  String get authorId => post.authorId;

  /// Copy with method
  PostWithAuthor copyWith({
    PostModel? post,
    UserModel? author,
  }) {
    return PostWithAuthor(
      post: post ?? this.post,
      author: author ?? this.author,
    );
  }
}
