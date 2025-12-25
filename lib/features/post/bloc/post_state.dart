import 'package:equatable/equatable.dart';
import 'package:literature/models/post_model.dart';

/// Post states
abstract class PostState extends Equatable {
  const PostState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PostInitial extends PostState {}

/// Loading state
class PostLoading extends PostState {}

/// Post created successfully
class PostCreated extends PostState {
  final String postId;

  const PostCreated(this.postId);

  @override
  List<Object?> get props => [postId];
}

/// Draft saved successfully
class DraftSaved extends PostState {
  final String draftId;

  const DraftSaved(this.draftId);

  @override
  List<Object?> get props => [draftId];
}

/// Story uploaded successfully
class StoryUploaded extends PostState {
  final String storyId;

  const StoryUploaded(this.storyId);

  @override
  List<Object?> get props => [storyId];
}

/// Error state
class PostError extends PostState {
  final String message;

  const PostError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Posts loaded successfully
class PostsLoaded extends PostState {
  final List<PostModel> posts;

  const PostsLoaded(this.posts);

  @override
  List<Object?> get props => [posts];
}
