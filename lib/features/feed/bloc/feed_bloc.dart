import 'package:bloc/bloc.dart';
import 'package:literature/features/feed/bloc/feed_event.dart';
import 'package:literature/features/feed/bloc/feed_state.dart';
import 'package:literature/repositories/post_repository.dart';
import 'package:literature/repositories/auth_repository.dart';

/// Feed BLoC for handling feed posts
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final PostRepository _postRepository;
  final AuthRepository _authRepository;
  final String? currentUserId;

  FeedBloc({
    required PostRepository postRepository,
    required AuthRepository authRepository,
    this.currentUserId,
  })  : _postRepository = postRepository,
        _authRepository = authRepository,
        super(FeedInitial()) {
    on<LoadFeedPosts>(_onLoadFeedPosts);
    on<RefreshFeedPosts>(_onRefreshFeedPosts);
  }

  /// Load feed posts (filtered by blocked users)
  Future<void> _onLoadFeedPosts(
    LoadFeedPosts event,
    Emitter<FeedState> emit,
  ) async {
    emit(FeedLoading());
    await _loadPosts(emit);
  }

  /// Refresh feed posts
  Future<void> _onRefreshFeedPosts(
    RefreshFeedPosts event,
    Emitter<FeedState> emit,
  ) async {
    await _loadPosts(emit);
  }

  /// Load posts with blocked user filtering
  Future<void> _loadPosts(Emitter<FeedState> emit) async {
    try {
      // Get blocked user IDs
      final blockedUserIds = currentUserId != null
          ? await _authRepository.getBlockedUserIds(currentUserId!)
          : <String>[];

      // Listen to feed posts stream
      await emit.forEach(
        _postRepository.getFeedPosts(),
        onData: (posts) {
          // Filter out posts from blocked users AND current user's own posts
          final filteredPosts = posts.where((post) {
            // Filter out blocked users
            if (blockedUserIds.contains(post.authorId)) return false;

            // Filter out current user's posts
            if (currentUserId != null && post.authorId == currentUserId) return false;

            return true;
          }).toList();
          return FeedLoaded(filteredPosts);
        },
        onError: (error, stackTrace) => FeedError(error.toString()),
      );
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }
}
