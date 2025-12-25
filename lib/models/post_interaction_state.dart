/// Model representing the interaction state for a post
/// Includes like/favorite status and all interaction counts
class PostInteractionState {
  final bool isLiked;
  final bool isFavorited;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;

  const PostInteractionState({
    required this.isLiked,
    required this.isFavorited,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
  });

  /// Create initial state from post counts
  factory PostInteractionState.initial({
    required int likesCount,
    required int commentsCount,
    required int sharesCount,
  }) {
    return PostInteractionState(
      isLiked: false,
      isFavorited: false,
      likesCount: likesCount,
      commentsCount: commentsCount,
      sharesCount: sharesCount,
    );
  }

  /// Copy with method for updating state
  PostInteractionState copyWith({
    bool? isLiked,
    bool? isFavorited,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
  }) {
    return PostInteractionState(
      isLiked: isLiked ?? this.isLiked,
      isFavorited: isFavorited ?? this.isFavorited,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
    );
  }

  /// Toggle like status
  PostInteractionState toggleLike() {
    return copyWith(
      isLiked: !isLiked,
      likesCount: isLiked ? likesCount - 1 : likesCount + 1,
    );
  }

  /// Toggle favorite status
  PostInteractionState toggleFavorite() {
    return copyWith(
      isFavorited: !isFavorited,
    );
  }
}
