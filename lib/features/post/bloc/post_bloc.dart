import 'package:bloc/bloc.dart';
import 'package:literature/features/post/bloc/post_event.dart';
import 'package:literature/features/post/bloc/post_state.dart';
import 'package:literature/repositories/post_repository.dart';

/// Post BLoC for handling post creation, drafts, and stories
class PostBloc extends Bloc<PostEvent, PostState> {
  final PostRepository _postRepository;
  final String userId;

  PostBloc({
    required PostRepository postRepository,
    required this.userId,
  })  : _postRepository = postRepository,
        super(PostInitial()) {
    on<CreatePostRequested>(_onCreatePostRequested);
    on<SaveDraftRequested>(_onSaveDraftRequested);
    on<UploadStoryRequested>(_onUploadStoryRequested);
    on<ResetPostState>(_onResetPostState);
    on<LoadUserPosts>(_onLoadUserPosts);
  }

  /// Handle create post
  Future<void> _onCreatePostRequested(
    CreatePostRequested event,
    Emitter<PostState> emit,
  ) async {
    emit(PostLoading());
    try {
      String? backgroundImageUrl;

      // Upload background image if provided
      if (event.backgroundImage != null) {
        backgroundImageUrl = await _postRepository.uploadBackgroundImage(
          userId: userId,
          imageFile: event.backgroundImage!,
        );
      }

      // Create post
      final postId = await _postRepository.createPost(
        authorId: userId,
        title: event.title,
        content: event.content,
        category: event.category,
        backgroundImageUrl: backgroundImageUrl,
      );

      emit(PostCreated(postId));
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }

  /// Handle save draft
  Future<void> _onSaveDraftRequested(
    SaveDraftRequested event,
    Emitter<PostState> emit,
  ) async {
    emit(PostLoading());
    try {
      String? backgroundImageUrl;

      // Upload background image if provided
      if (event.backgroundImage != null) {
        backgroundImageUrl = await _postRepository.uploadBackgroundImage(
          userId: userId,
          imageFile: event.backgroundImage!,
        );
      }

      // Save draft
      final draftId = await _postRepository.saveDraft(
        authorId: userId,
        title: event.title,
        content: event.content,
        category: event.category,
        backgroundImageUrl: backgroundImageUrl,
        draftId: event.draftId,
      );

      emit(DraftSaved(draftId));
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }

  /// Handle upload story
  Future<void> _onUploadStoryRequested(
    UploadStoryRequested event,
    Emitter<PostState> emit,
  ) async {
    emit(PostLoading());
    try {
      String? backgroundImageUrl;

      // Upload background image if provided
      if (event.backgroundImage != null) {
        backgroundImageUrl = await _postRepository.uploadBackgroundImage(
          userId: userId,
          imageFile: event.backgroundImage!,
        );
      }

      // Create story
      final storyId = await _postRepository.createStory(
        authorId: userId,
        title: event.title,
        content: event.content,
        category: event.category,
        backgroundImageUrl: backgroundImageUrl,
        backgroundColor: event.backgroundColor,
      );

      emit(StoryUploaded(storyId));
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }

  /// Reset state
  void _onResetPostState(
    ResetPostState event,
    Emitter<PostState> emit,
  ) {
    emit(PostInitial());
  }

  /// Load user's posts
  Future<void> _onLoadUserPosts(
    LoadUserPosts event,
    Emitter<PostState> emit,
  ) async {
    await emit.forEach(
      _postRepository.getUserPosts(event.userId),
      onData: (posts) => PostsLoaded(posts),
      onError: (error, stackTrace) => PostError(error.toString()),
    );
  }
}
