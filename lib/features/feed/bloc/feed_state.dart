import 'package:equatable/equatable.dart';
import 'package:literature/models/post_model.dart';

/// Feed states
abstract class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class FeedInitial extends FeedState {}

/// Loading feed
class FeedLoading extends FeedState {}

/// Feed loaded successfully
class FeedLoaded extends FeedState {
  final List<PostModel> posts;

  const FeedLoaded(this.posts);

  @override
  List<Object?> get props => [posts];
}

/// Feed error
class FeedError extends FeedState {
  final String message;

  const FeedError(this.message);

  @override
  List<Object?> get props => [message];
}
