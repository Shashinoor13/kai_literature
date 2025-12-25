/// Model representing all data needed to display a story avatar in the story bar
class StoryDisplayData {
  final String authorId;
  final String authorName;
  final String authorInitial;
  final int storyCount;
  final bool hasUnseen;
  final List<String> allAuthorIds;
  final int authorIndex;

  const StoryDisplayData({
    required this.authorId,
    required this.authorName,
    required this.authorInitial,
    required this.storyCount,
    required this.hasUnseen,
    required this.allAuthorIds,
    required this.authorIndex,
  });

  /// Factory constructor for creating from author data
  factory StoryDisplayData.fromAuthorData({
    required String authorId,
    required String authorName,
    required int storyCount,
    required List<String> allAuthorIds,
    required int authorIndex,
    bool hasUnseen = true,
  }) {
    return StoryDisplayData(
      authorId: authorId,
      authorName: authorName,
      authorInitial: authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
      storyCount: storyCount,
      hasUnseen: hasUnseen,
      allAuthorIds: allAuthorIds,
      authorIndex: authorIndex,
    );
  }

  /// Get border color based on seen/unseen status
  bool get shouldShowWhiteBorder => hasUnseen;
}
