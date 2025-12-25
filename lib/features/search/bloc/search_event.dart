import 'package:equatable/equatable.dart';

/// Search events
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// Search query changed
class SearchQueryChanged extends SearchEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Clear search
class ClearSearch extends SearchEvent {
  const ClearSearch();
}
