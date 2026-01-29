import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:literature/core/storages/gloabl/value.dart';
import 'package:literature/core/theme/app_theme.dart';
import 'package:literature/core/theme/theme_model.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/constants/text_styles.dart';
import 'package:literature/features/feed/bloc/feed_event.dart';
import 'package:literature/features/theme/bloc/theme_event.dart';
import 'package:literature/features/theme/bloc/theme_state.dart';
import 'package:literature/repositories/theme_repository.dart';

/// BLoC for managing app theme
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeRepository themeRepository;

  ThemeBloc({required this.themeRepository}) : super(const ThemeInitial()) {
    on<LoadTheme>(_onLoadTheme);
    on<ChangeThemeMode>(_onChangeThemeMode);
    on<UpdateCustomTheme>(_onUpdateCustomTheme);
    on<SetBackgroundImage>(_onSetBackgroundImage);
    on<ResetTheme>(_onResetTheme);
  }
  Color _getDefaultBackgroundColor(BuildContext context) {
    final filter = GlobalState.instance.selectedContentFilter;
    const Color parchmentLight = Color.fromRGBO(240, 215, 181, 1);
    const Color parchmentBase = Color.fromRGBO(226, 194, 151, 1);
    const Color parchmentDark = Color.fromRGBO(212, 171, 117, 1);

    switch (filter) {
      case ContentFilter.poem:
        // Return a single color from the gradient, e.g., the base color
        return parchmentBase;
      case ContentFilter.novel:
        return Colors.green.shade50;
      case ContentFilter.all:
      default:
        return Theme.of(context).colorScheme.surface;
    }
  }

  /// Load saved theme or use default
  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    try {
      final savedConfig = await themeRepository.loadThemeConfig();
      final config = savedConfig ?? ThemeConfig.defaultDark();
      final themeData = _generateThemeData(config);

      emit(ThemeLoaded(config: config, themeData: themeData));
    } catch (e) {
      emit(ThemeError(e.toString()));
    }
  }

  /// Change theme mode
  Future<void> _onChangeThemeMode(
    ChangeThemeMode event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! ThemeLoaded) return;

      ThemeConfig newConfig;

      // Preserve background image path when switching themes
      final backgroundImagePath = currentState.config.backgroundImagePath;

      switch (event.mode) {
        case AppThemeMode.light:
          newConfig = ThemeConfig.defaultLight().copyWith(
            backgroundImagePath: backgroundImagePath,
          );
          break;
        case AppThemeMode.dark:
          newConfig = ThemeConfig.defaultDark().copyWith(
            backgroundImagePath: backgroundImagePath,
          );
          break;
        case AppThemeMode.custom:
          // Keep existing custom colors or use defaults
          newConfig = currentState.config.mode == AppThemeMode.custom
              ? currentState.config.copyWith(mode: AppThemeMode.custom)
              : ThemeConfig.custom(
                  primaryColor: Colors.white,
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  backgroundImagePath: backgroundImagePath,
                );
          break;
      }

      final themeData = _generateThemeData(newConfig);
      await themeRepository.saveThemeConfig(newConfig);

      emit(ThemeLoaded(config: newConfig, themeData: themeData));
    } catch (e) {
      emit(ThemeError(e.toString()));
    }
  }

  /// Update custom theme colors
  Future<void> _onUpdateCustomTheme(
    UpdateCustomTheme event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! ThemeLoaded) return;

      final newConfig = currentState.config.copyWith(
        mode: AppThemeMode.custom,
        primaryColor: event.primaryColor,
        backgroundColor: event.backgroundColor,
        textColor: event.textColor,
      );

      final themeData = _generateThemeData(newConfig);
      await themeRepository.saveThemeConfig(newConfig);

      emit(ThemeLoaded(config: newConfig, themeData: themeData));
    } catch (e) {
      emit(ThemeError(e.toString()));
    }
  }

  /// Set background image
  Future<void> _onSetBackgroundImage(
    SetBackgroundImage event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! ThemeLoaded) return;

      // Convert empty string to null
      final imagePath = event.imagePath?.isEmpty == true
          ? null
          : event.imagePath;

      final newConfig = currentState.config.copyWith(
        backgroundImagePath: imagePath,
      );

      await themeRepository.saveThemeConfig(newConfig);

      emit(currentState.copyWith(config: newConfig));
    } catch (e) {
      emit(ThemeError(e.toString()));
    }
  }

  /// Reset theme to default dark
  Future<void> _onResetTheme(ResetTheme event, Emitter<ThemeState> emit) async {
    try {
      await themeRepository.clearThemeConfig();
      final config = ThemeConfig.defaultDark();
      final themeData = _generateThemeData(config);

      emit(ThemeLoaded(config: config, themeData: themeData));
    } catch (e) {
      emit(ThemeError(e.toString()));
    }
  }

  /// Generate ThemeData from ThemeConfig
  ThemeData _generateThemeData(ThemeConfig config) {
    switch (config.mode) {
      case AppThemeMode.light:
        return AppTheme.lightTheme;
      case AppThemeMode.dark:
        return AppTheme.darkTheme;
      case AppThemeMode.custom:
        return _buildCustomTheme(config);
    }
  }

  /// Build custom theme from config
  ThemeData _buildCustomTheme(ThemeConfig config) {
    final bgColor = config.backgroundColor ?? Colors.black;
    final primaryColor = config.primaryColor ?? Colors.white;
    final txtColor = config.textColor ?? Colors.white;
    final isLight = bgColor.computeLuminance() > 0.5;

    return ThemeData(
      brightness: isLight ? Brightness.light : Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      primaryColor: primaryColor,
      fontFamily: 'OpenSans',
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: isLight ? Brightness.light : Brightness.dark,
        primary: primaryColor,
        onPrimary: bgColor,
        secondary: primaryColor.withValues(alpha: 0.7),
        onSecondary: bgColor,
        surface: bgColor,
        onSurface: txtColor,
        error: Colors.red,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(color: txtColor),
        headlineLarge: AppTextStyles.h1.copyWith(color: txtColor),
        headlineMedium: AppTextStyles.h2.copyWith(color: txtColor),
        bodyLarge: AppTextStyles.bodyLg.copyWith(color: txtColor),
        bodyMedium: AppTextStyles.body.copyWith(color: txtColor),
        bodySmall: AppTextStyles.bodySm.copyWith(color: txtColor),
        labelSmall: AppTextStyles.caption.copyWith(color: txtColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: txtColor,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: bgColor,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: AppSizes.borderWidth),
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: AppTextStyles.button.copyWith(
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: BorderSide(
            color: txtColor.withValues(alpha: 0.3),
            width: AppSizes.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: BorderSide(
            color: txtColor.withValues(alpha: 0.3),
            width: AppSizes.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: BorderSide(
            color: primaryColor,
            width: AppSizes.borderWidth,
          ),
        ),
        hintStyle: AppTextStyles.body.copyWith(
          color: txtColor.withValues(alpha: 0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppSizes.sm,
          horizontal: AppSizes.md,
        ),
      ),
      cardTheme: CardThemeData(
        color: bgColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          side: BorderSide(
            color: txtColor.withValues(alpha: 0.2),
            width: AppSizes.borderWidth,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: txtColor.withValues(alpha: 0.2),
        thickness: AppSizes.borderWidth,
      ),
      iconTheme: IconThemeData(color: txtColor, size: AppSizes.iconMd),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: txtColor.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
