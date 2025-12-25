import 'package:flutter/material.dart';

/// Utility functions for post category handling
class CategoryUtils {
  /// Get background color for category badge
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'poem':
        return const Color(0xFF90EE90); // Light green
      case 'joke':
        return const Color(0xFFFFD700); // Yellow/Gold
      case 'story':
        return const Color(0xFFADD8E6); // Light blue
      default:
        return Colors.white70; // Default gray
    }
  }

  /// Get text color for category badge
  static Color getCategoryTextColor(String category) {
    switch (category.toLowerCase()) {
      case 'poem':
      case 'joke':
      case 'story':
        return Colors.black87; // Dark text for light backgrounds
      default:
        return Colors.white; // White text for gray background
    }
  }
}
