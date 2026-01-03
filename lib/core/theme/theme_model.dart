import 'package:flutter/material.dart';

/// Sentinel class for distinguishing between null and unset values in copyWith
class _Sentinel {
  const _Sentinel();
}

/// Theme mode enum
enum AppThemeMode {
  light,
  dark,
  custom,
}

/// Theme configuration model
class ThemeConfig {
  final AppThemeMode mode;
  final Color? primaryColor;
  final Color? backgroundColor;
  final Color? textColor;
  final String? backgroundImagePath;

  const ThemeConfig({
    required this.mode,
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
    this.backgroundImagePath,
  });

  /// Create default dark theme config
  factory ThemeConfig.defaultDark() {
    return const ThemeConfig(
      mode: AppThemeMode.dark,
    );
  }

  /// Create default light theme config
  factory ThemeConfig.defaultLight() {
    return const ThemeConfig(
      mode: AppThemeMode.light,
    );
  }

  /// Create custom theme config
  factory ThemeConfig.custom({
    required Color primaryColor,
    required Color backgroundColor,
    required Color textColor,
    String? backgroundImagePath,
  }) {
    return ThemeConfig(
      mode: AppThemeMode.custom,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      textColor: textColor,
      backgroundImagePath: backgroundImagePath,
    );
  }

  /// Copy with method
  ThemeConfig copyWith({
    AppThemeMode? mode,
    Color? primaryColor,
    Color? backgroundColor,
    Color? textColor,
    Object? backgroundImagePath = const _Sentinel(),
  }) {
    return ThemeConfig(
      mode: mode ?? this.mode,
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      backgroundImagePath: backgroundImagePath == const _Sentinel()
          ? this.backgroundImagePath
          : backgroundImagePath as String?,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'primaryColor': primaryColor?.toARGB32(),
      'backgroundColor': backgroundColor?.toARGB32(),
      'textColor': textColor?.toARGB32(),
      'backgroundImagePath': backgroundImagePath,
    };
  }

  /// Create from JSON
  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    final imagePath = json['backgroundImagePath'] as String?;
    return ThemeConfig(
      mode: AppThemeMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => AppThemeMode.dark,
      ),
      primaryColor: json['primaryColor'] != null
          ? Color(json['primaryColor'] as int)
          : null,
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : null,
      textColor:
          json['textColor'] != null ? Color(json['textColor'] as int) : null,
      // Convert empty string to null
      backgroundImagePath: imagePath?.isEmpty == true ? null : imagePath,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeConfig &&
        other.mode == mode &&
        other.primaryColor == primaryColor &&
        other.backgroundColor == backgroundColor &&
        other.textColor == textColor &&
        other.backgroundImagePath == backgroundImagePath;
  }

  @override
  int get hashCode => Object.hash(
        mode,
        primaryColor,
        backgroundColor,
        textColor,
        backgroundImagePath,
      );
}
