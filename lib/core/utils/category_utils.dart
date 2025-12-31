import 'package:flutter/material.dart';

/// Utility functions for post category handling
class CategoryUtils {
  /// Get background color for category badge (monochrome design)
  static Color getCategoryColor(String category) {
    // Monochrome design: all categories use white background
    return Colors.white70;
  }

  /// Get text color for category badge (monochrome design)
  static Color getCategoryTextColor(String category) {
    // Monochrome design: all categories use black text
    return Colors.black87;
  }

  /// Get formatted category name for display
  static String getFormattedCategoryName(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }

  /// Valid categories
  static const List<String> validCategories = [
    'poem',
    'story',
    'book',
    'joke',
    'reflection',
    'research',
    'novel',
    'other'
  ];
}
