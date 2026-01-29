import 'package:literature/features/feed/bloc/feed_bloc.dart';
import 'package:literature/features/feed/bloc/feed_event.dart'; // for ContentFilter enum

class GlobalState {
  // Singleton
  GlobalState._privateConstructor();
  static final GlobalState instance = GlobalState._privateConstructor();

  // Global variable to store selected content filter
  ContentFilter selectedContentFilter = ContentFilter.all;
}
