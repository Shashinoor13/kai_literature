import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:literature/core/theme/theme_model.dart';

/// Theme states
abstract class ThemeState extends Equatable {
  const ThemeState();

  @override
  List<Object?> get props => [];
}

/// Initial theme state
class ThemeInitial extends ThemeState {
  const ThemeInitial();
}

/// Theme loaded successfully
class ThemeLoaded extends ThemeState {
  final ThemeConfig config;
  final ThemeData themeData;

  const ThemeLoaded({
    required this.config,
    required this.themeData,
  });

  @override
  List<Object?> get props => [config, themeData];

  ThemeLoaded copyWith({
    ThemeConfig? config,
    ThemeData? themeData,
  }) {
    return ThemeLoaded(
      config: config ?? this.config,
      themeData: themeData ?? this.themeData,
    );
  }
}

/// Theme error
class ThemeError extends ThemeState {
  final String message;

  const ThemeError(this.message);

  @override
  List<Object?> get props => [message];
}
