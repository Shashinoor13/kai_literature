import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:literature/features/feed/bloc/feed_event.dart';

class ContentTheme {
  static const Color parchmentLight = Color.fromRGBO(240, 215, 181, 1);
  static const Color parchmentBase = Color.fromRGBO(226, 194, 151, 1);
  static const Color parchmentDark = Color.fromRGBO(212, 171, 117, 1);

  // Background color for the selected tab
  static Color backgroundForFilter(ContentFilter filter) {
    switch (filter) {
      case ContentFilter.all:
        return parchmentBase;
      case ContentFilter.poem:
        return parchmentBase;
      case ContentFilter.story:
        return parchmentLight;
      default:
        return Colors.black; // default dark theme
    }
  }

  // Text color for the selected tab (contrast with background)
  static Color textForFilter(ContentFilter filter) {
    switch (filter) {
      case ContentFilter.poem:
      case ContentFilter.story:
        return Colors.black;
      case ContentFilter.all:
      default:
        return Colors.white; // default dark theme
    }
  }
}
