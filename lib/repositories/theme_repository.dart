import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:literature/core/theme/theme_model.dart';

/// Repository for theme persistence
class ThemeRepository {
  static const String _themeKey = 'app_theme_config';

  /// Save theme configuration
  Future<void> saveThemeConfig(ThemeConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(config.toJson());
      await prefs.setString(_themeKey, jsonString);
    } catch (e) {
      throw Exception('Failed to save theme: $e');
    }
  }

  /// Load theme configuration
  Future<ThemeConfig?> loadThemeConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_themeKey);

      if (jsonString == null) {
        return null;
      }

      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return ThemeConfig.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Failed to load theme: $e');
    }
  }

  /// Clear saved theme
  Future<void> clearThemeConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);
    } catch (e) {
      throw Exception('Failed to clear theme: $e');
    }
  }
}
