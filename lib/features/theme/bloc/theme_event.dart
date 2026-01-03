import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:literature/core/theme/theme_model.dart';

/// Theme events
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

/// Load saved theme
class LoadTheme extends ThemeEvent {
  const LoadTheme();
}

/// Change theme mode (light/dark/custom)
class ChangeThemeMode extends ThemeEvent {
  final AppThemeMode mode;

  const ChangeThemeMode(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Update custom theme colors
class UpdateCustomTheme extends ThemeEvent {
  final Color? primaryColor;
  final Color? backgroundColor;
  final Color? textColor;

  const UpdateCustomTheme({
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
  });

  @override
  List<Object?> get props => [primaryColor, backgroundColor, textColor];
}

/// Set background image for feed
class SetBackgroundImage extends ThemeEvent {
  final String? imagePath;

  const SetBackgroundImage(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

/// Reset theme to default
class ResetTheme extends ThemeEvent {
  const ResetTheme();
}
