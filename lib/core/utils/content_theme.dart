import 'package:flutter/material.dart';
import 'package:literature/core/storages/gloabl/value.dart';
import 'package:literature/features/feed/bloc/feed_event.dart';

class ContentTheme {
  static Color getDefaultBackgroundColor(BuildContext context) {
    final filter = GlobalState.instance.selectedContentFilter;

    const Color parchmentLight = Color.fromRGBO(240, 215, 181, 1);
    const Color parchmentBase = Color.fromRGBO(226, 194, 151, 1);
    const Color parchmentDark = Color.fromRGBO(212, 171, 117, 1);

    switch (filter) {
      case ContentFilter.poem:
        return parchmentBase;
      case ContentFilter.story:
        return parchmentLight;
      case ContentFilter.all:
      default:
        return Theme.of(context).colorScheme.surface;
    }
  }
}
