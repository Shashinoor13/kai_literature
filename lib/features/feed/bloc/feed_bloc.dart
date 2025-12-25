import 'package:bloc/bloc.dart';
import 'package:literature/features/feed/bloc/feed_event.dart';
import 'package:literature/features/feed/bloc/feed_state.dart';
import 'package:literature/repositories/post_repository.dart';
import 'package:literature/repositories/auth_repository.dart';

/// Feed BLoC for handling feed posts with hierarchical filtering
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final PostRepository _postRepository;
  final AuthRepository _authRepository;
  final String? currentUserId;
  FeedType _currentFeedType = FeedType.following;
  ContentFilter _currentContentFilter = ContentFilter.all;

  FeedBloc({
    required PostRepository postRepository,
    required AuthRepository authRepository,
    this.currentUserId,
  }) : _postRepository = postRepository,
       _authRepository = authRepository,
       super(FeedInitial()) {
    on<LoadFeedPosts>(_onLoadFeedPosts);
    on<RefreshFeedPosts>(_onRefreshFeedPosts);
    on<ChangeFeedType>(_onChangeFeedType);
    on<ChangeContentFilter>(_onChangeContentFilter);
  }

  /// Load feed posts with filters
  Future<void> _onLoadFeedPosts(
    LoadFeedPosts event,
    Emitter<FeedState> emit,
  ) async {
    _currentFeedType = event.feedType;
    _currentContentFilter = event.contentFilter;
    emit(FeedLoading());
    await _loadPosts(emit, event.feedType, event.contentFilter);
  }

  /// Refresh feed posts
  Future<void> _onRefreshFeedPosts(
    RefreshFeedPosts event,
    Emitter<FeedState> emit,
  ) async {
    _currentFeedType = event.feedType;
    _currentContentFilter = event.contentFilter;
    await _loadPosts(emit, event.feedType, event.contentFilter);
  }

  /// Change feed type (Following/Recommended)
  Future<void> _onChangeFeedType(
    ChangeFeedType event,
    Emitter<FeedState> emit,
  ) async {
    _currentFeedType = event.feedType;
    emit(FeedLoading());
    await _loadPosts(emit, event.feedType, _currentContentFilter);
    // print('Feed type changed to: ${event.feedType}'); // Debug log
  }

  /// Change content filter (All/Poem/Story/Joke)
  Future<void> _onChangeContentFilter(
    ChangeContentFilter event,
    Emitter<FeedState> emit,
  ) async {
    _currentContentFilter = event.contentFilter;
    emit(FeedLoading());
    await _loadPosts(emit, _currentFeedType, event.contentFilter);
  }

  /// Load posts based on filters with blocked user filtering
  Future<void> _loadPosts(
    Emitter<FeedState> emit,
    FeedType feedType,
    ContentFilter contentFilter,
  ) async {
    try {
      // Get blocked user IDs
      final blockedUserIds = currentUserId != null
          ? await _authRepository.getBlockedUserIds(currentUserId!)
          : <String>[];

      // Get appropriate stream based on feed type and content filter
      Stream postsStream;

      // First, determine feed type (Following vs Recommended)
      if (feedType == FeedType.following) {
        if (currentUserId == null) {
          emit(const FeedError('Please log in to see posts from following'));
          return;
        }

        // Then apply content filter
        if (contentFilter == ContentFilter.all) {
          postsStream = _postRepository.getFollowingFeedPosts(currentUserId!);
        } else {
          // Get category-specific posts from following
          postsStream = _postRepository.getFollowingPostsByCategory(
            currentUserId!,
            _getCategoryString(contentFilter),
          );
        }
      } else {
        // Recommended feed
        if (contentFilter == ContentFilter.all) {
          postsStream = _postRepository.getFeedPosts();
        } else {
          // Get category-specific posts from all users
          postsStream = _postRepository.getPostsByCategory(
            _getCategoryString(contentFilter),
          );
        }
      }

      // Listen to feed posts stream
      await emit.forEach(
        postsStream,
        onData: (posts) {
          // Filter out posts from blocked users AND current user's own posts
          final filteredPosts = posts.where((post) {
            // Filter out blocked users
            if (blockedUserIds.contains(post.authorId)) return false;

            // Filter out current user's posts
            if (currentUserId != null && post.authorId == currentUserId) {
              return false;
            }

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

  String _getCategoryString(ContentFilter filter) {
    switch (filter) {
      case ContentFilter.poem:
        return 'poem';
      case ContentFilter.story:
        return 'story';
      case ContentFilter.joke:
        return 'joke';
      case ContentFilter.all:
        return '';
    }
  }

  FeedType get currentFeedType => _currentFeedType;
  ContentFilter get currentContentFilter => _currentContentFilter;
}
