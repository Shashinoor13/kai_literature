import 'package:equatable/equatable.dart';
import 'package:literature/models/user_model.dart';
import 'package:literature/models/post_model.dart';

/// Search states
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SearchInitial extends SearchState {}

/// Searching in progress
class SearchLoading extends SearchState {}

/// Search completed successfully
class SearchSuccess extends SearchState {
  final List<UserModel> users;
  final List<PostModel> posts;
  final String query;

  const SearchSuccess({
    required this.users,
    required this.posts,
    required this.query,
  });

  @override
  List<Object?> get props => [users, posts, query];
}

/// Search error
class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}
