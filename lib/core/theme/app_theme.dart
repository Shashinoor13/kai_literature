import 'package:flutter/material.dart';
import 'package:literature/core/constants/colors.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/constants/text_styles.dart';

/// App theme configuration following monochrome design system
/// Dark mode is default (See CLAUDE.md Design System)
class AppTheme {
  AppTheme._();

  // Dark theme (DEFAULT)
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.black,
    primaryColor: AppColors.white,
    fontFamily: 'Inter',
    useMaterial3: true,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.white,
      secondary: AppColors.gray300,
      surface: AppColors.black,
      onPrimary: AppColors.black,
      onSecondary: AppColors.white,
      onSurface: AppColors.white,
    ),

    textTheme: const TextTheme(
      displayLarge: AppTextStyles.display,
      headlineLarge: AppTextStyles.h1,
      headlineMedium: AppTextStyles.h2,
      bodyLarge: AppTextStyles.bodyLg,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.bodySm,
      labelSmall: AppTextStyles.caption,
    ).apply(
      bodyColor: AppColors.white,
      displayColor: AppColors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
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
        foregroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.white, width: AppSizes.borderWidth),
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        textStyle: AppTextStyles.button.copyWith(color: AppColors.white),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.white,
        textStyle: AppTextStyles.button.copyWith(
          decoration: TextDecoration.underline,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.black,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide: const BorderSide(color: AppColors.gray700, width: AppSizes.borderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide: const BorderSide(color: AppColors.gray700, width: AppSizes.borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide: const BorderSide(color: AppColors.white, width: AppSizes.borderWidth),
      ),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.gray500),
      contentPadding: const EdgeInsets.symmetric(
        vertical: AppSizes.sm,
        horizontal: AppSizes.md,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.gray900,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: const BorderSide(color: AppColors.gray700, width: AppSizes.borderWidth),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.gray700,
      thickness: AppSizes.borderWidth,
    ),

    iconTheme: const IconThemeData(
      color: AppColors.white,
      size: AppSizes.iconMd,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.black,
      selectedItemColor: AppColors.white,
      unselectedItemColor: AppColors.gray500,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );

  // Light theme (exact inversion of dark theme)
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.white,
    primaryColor: AppColors.black,
    fontFamily: 'Inter',
    useMaterial3: true,

    colorScheme: const ColorScheme.light(
      primary: AppColors.black,
      secondary: AppColors.gray300,
      surface: AppColors.white,
      onPrimary: AppColors.white,
      onSecondary: AppColors.black,
      onSurface: AppColors.black,
    ),

    textTheme: const TextTheme(
      displayLarge: AppTextStyles.display,
      headlineLarge: AppTextStyles.h1,
      headlineMedium: AppTextStyles.h2,
      bodyLarge: AppTextStyles.bodyLg,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.bodySm,
      labelSmall: AppTextStyles.caption,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.black,
      elevation: 0,
      centerTitle: true,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
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
        foregroundColor: AppColors.black,
        side: const BorderSide(color: AppColors.black, width: AppSizes.borderWidth),
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        textStyle: AppTextStyles.button.copyWith(color: AppColors.black),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.black,
        textStyle: AppTextStyles.button.copyWith(
          color: AppColors.black,
          decoration: TextDecoration.underline,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide: const BorderSide(color: AppColors.gray300, width: AppSizes.borderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide: const BorderSide(color: AppColors.gray300, width: AppSizes.borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        borderSide: const BorderSide(color: AppColors.black, width: AppSizes.borderWidth),
      ),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.gray500),
      contentPadding: const EdgeInsets.symmetric(
        vertical: AppSizes.sm,
        horizontal: AppSizes.md,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: const BorderSide(color: AppColors.gray300, width: AppSizes.borderWidth),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.gray300,
      thickness: AppSizes.borderWidth,
    ),

    iconTheme: const IconThemeData(
      color: AppColors.black,
      size: AppSizes.iconMd,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.black,
      unselectedItemColor: AppColors.gray500,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
