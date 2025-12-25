import 'package:equatable/equatable.dart';

/// Feed events
abstract class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

/// Load feed posts
class LoadFeedPosts extends FeedEvent {
  const LoadFeedPosts();
}

/// Refresh feed posts
class RefreshFeedPosts extends FeedEvent {
  const RefreshFeedPosts();
}
