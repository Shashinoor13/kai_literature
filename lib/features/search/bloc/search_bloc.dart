import 'package:bloc/bloc.dart';
import 'package:literature/features/search/bloc/search_event.dart';
import 'package:literature/features/search/bloc/search_state.dart';
import 'package:literature/repositories/auth_repository.dart';
import 'package:literature/repositories/post_repository.dart';

/// Search BLoC for handling user and post searches
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final AuthRepository _authRepository;
  final PostRepository _postRepository;
  final String? currentUserId;

  SearchBloc({
    required AuthRepository authRepository,
    required PostRepository postRepository,
    this.currentUserId,
  })  : _authRepository = authRepository,
        _postRepository = postRepository,
        super(SearchInitial()) {
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<ClearSearch>(_onClearSearch);
  }

  /// Handle search query change
  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());

    try {
      // Get blocked user IDs
      final blockedUserIds = currentUserId != null
          ? await _authRepository.getBlockedUserIds(currentUserId!)
          : <String>[];

      // Search both users and posts (filtering out blocked users)
      final users = await _authRepository.searchUsers(query, currentUserId: currentUserId);
      final posts = await _postRepository.searchPosts(query, blockedUserIds: blockedUserIds);

      emit(SearchSuccess(
        users: users,
        posts: posts,
        query: query,
      ));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  /// Handle clear search
  void _onClearSearch(
    ClearSearch event,
    Emitter<SearchState> emit,
  ) {
    emit(SearchInitial());
  }
}
