import 'package:literature/features/feed/bloc/feed_event.dart';

/// Model representing feed filter configuration
class FeedFilterConfig {
  final FeedType feedType;
  final ContentFilter contentFilter;

  const FeedFilterConfig({
    required this.feedType,
    required this.contentFilter,
  });

  /// Create default filter config (recommended, all content)
  factory FeedFilterConfig.defaults() {
    return const FeedFilterConfig(
      feedType: FeedType.recommended,
      contentFilter: ContentFilter.all,
    );
  }

  /// Copy with method
  FeedFilterConfig copyWith({
    FeedType? feedType,
    ContentFilter? contentFilter,
  }) {
    return FeedFilterConfig(
      feedType: feedType ?? this.feedType,
      contentFilter: contentFilter ?? this.contentFilter,
    );
  }

  /// Check if showing following feed
  bool get isFollowingFeed => feedType == FeedType.following;

  /// Check if showing recommended feed
  bool get isRecommendedFeed => feedType == FeedType.recommended;

  /// Check if filtering by specific content type
  bool get hasContentFilter => contentFilter != ContentFilter.all;

  /// Get content type for filtering (null if showing all)
  String? get contentTypeFilter {
    switch (contentFilter) {
      case ContentFilter.poem:
        return 'poem';
      case ContentFilter.story:
        return 'story';
      case ContentFilter.joke:
        return 'joke';
      case ContentFilter.all:
        return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedFilterConfig &&
        other.feedType == feedType &&
        other.contentFilter == contentFilter;
  }

  @override
  int get hashCode => feedType.hashCode ^ contentFilter.hashCode;
}
