import 'package:equatable/equatable.dart';

/// Primary feed filter type (top level)
enum FeedType {
  following, // Posts from users you follow
  recommended, // Posts from everyone
}

/// Content category filter (secondary level)
enum ContentFilter {
  all, // All content types
  poem, // Only poems
  story, // Only stories
  joke, // Only jokes
}

/// Feed events
abstract class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

/// Load feed posts with filters
class LoadFeedPosts extends FeedEvent {
  final FeedType feedType;
  final ContentFilter contentFilter;

  const LoadFeedPosts({
    this.feedType = FeedType.following,
    this.contentFilter = ContentFilter.all,
  });

  @override
  List<Object?> get props => [feedType, contentFilter];
}

/// Refresh feed posts
class RefreshFeedPosts extends FeedEvent {
  final FeedType feedType;
  final ContentFilter contentFilter;

  const RefreshFeedPosts({
    this.feedType = FeedType.following,
    this.contentFilter = ContentFilter.all,
  });

  @override
  List<Object?> get props => [feedType, contentFilter];
}

/// Change feed type (Following/Recommended)
class ChangeFeedType extends FeedEvent {
  final FeedType feedType;

  const ChangeFeedType(this.feedType);

  @override
  List<Object?> get props => [feedType];
}

/// Change content filter (All/Poem/Story/Joke)
class ChangeContentFilter extends FeedEvent {
  final ContentFilter contentFilter;

  const ChangeContentFilter(this.contentFilter);

  @override
  List<Object?> get props => [contentFilter];
}
