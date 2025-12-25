import 'package:flutter/material.dart';
import 'package:literature/core/constants/colors.dart';

/// Typography system (See CLAUDE.md Design System)
/// Primary: Inter (fallback: system-ui)
/// Secondary: Playfair Display (serif, user-selectable in settings)
class AppTextStyles {
  AppTextStyles._();

  // Type Scale
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.black,
  ); // Titles, Profile names

  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.black,
  ); // Section headers

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: AppColors.black,
  ); // Card titles

  static const TextStyle bodyLg = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.black,
  ); // Poems, stories

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.black,
  ); // Default text

  static const TextStyle bodySm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.black,
  ); // Meta

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.gray500,
  ); // Timestamps

  // Button text
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  );
}
