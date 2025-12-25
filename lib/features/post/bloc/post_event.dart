import 'package:equatable/equatable.dart';
import 'dart:io';

/// Post events
abstract class PostEvent extends Equatable {
  const PostEvent();

  @override
  List<Object?> get props => [];
}

/// Create a new post
class CreatePostRequested extends PostEvent {
  final String title;
  final String content;
  final String category;
  final File? backgroundImage;

  const CreatePostRequested({
    required this.title,
    required this.content,
    required this.category,
    this.backgroundImage,
  });

  @override
  List<Object?> get props => [title, content, category, backgroundImage];
}

/// Save as draft
class SaveDraftRequested extends PostEvent {
  final String title;
  final String content;
  final String category;
  final File? backgroundImage;
  final String? draftId;

  const SaveDraftRequested({
    required this.title,
    required this.content,
    required this.category,
    this.backgroundImage,
    this.draftId,
  });

  @override
  List<Object?> get props => [title, content, category, backgroundImage, draftId];
}

/// Upload as story
class UploadStoryRequested extends PostEvent {
  final String title;
  final String content;
  final String category;
  final File? backgroundImage;
  final String backgroundColor;

  const UploadStoryRequested({
    required this.title,
    required this.content,
    required this.category,
    this.backgroundImage,
    this.backgroundColor = 'black',
  });

  @override
  List<Object?> get props => [title, content, category, backgroundImage, backgroundColor];
}

/// Reset post state
class ResetPostState extends PostEvent {
  const ResetPostState();
}

/// Load user's posts
class LoadUserPosts extends PostEvent {
  final String userId;

  const LoadUserPosts(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Update an existing post
class UpdatePostRequested extends PostEvent {
  final String postId;
  final String title;
  final String content;
  final String category;

  const UpdatePostRequested({
    required this.postId,
    required this.title,
    required this.content,
    required this.category,
  });

  @override
  List<Object?> get props => [postId, title, content, category];
}
