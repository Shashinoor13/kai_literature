import 'package:flutter/material.dart';

/// Monochrome color system - STRICT (See CLAUDE.md Design System)
/// NO accent colors allowed - reactions use icons, not color
class AppColors {
  AppColors._();

  // Core Palette (ONLY these colors allowed)
  static const Color black = Color(0xFF000000); // Primary text, icons
  static const Color white = Color(0xFFFFFFFF); // Backgrounds
  static const Color gray900 = Color(0xFF111111); // Headers, dividers
  static const Color gray700 = Color(0xFF3A3A3A); // Secondary text
  static const Color gray500 = Color(0xFF7A7A7A); // Meta text, timestamps
  static const Color gray300 = Color(0xFFD1D1D1); // Borders
  static const Color gray100 = Color(0xFFF4F4F4); // Surface backgrounds

  // Semantic Usage
  static const Color primaryAction = black;
  static const Color primaryActionText = white;
  static const Color secondaryAction = white;
  static const Color secondaryActionBorder = black;
  static const Color disabled = gray300;
  static const Color disabledText = gray500;
}
