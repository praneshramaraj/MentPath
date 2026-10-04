import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        color: AppColors.darkBlue,
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        color: AppColors.darkBlue,
        fontWeight: FontWeight.bold,
        fontSize: 28,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        color: AppColors.darkBlue,
        fontWeight: FontWeight.w700,
        fontSize: 24,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        color: AppColors.darkBlue,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: AppColors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: AppColors.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: AppColors.primaryText,
        fontSize: 16,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.secondaryText,
        fontSize: 14,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: AppColors.primaryBlue,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        color: AppColors.secondaryText,
        fontSize: 12,
      ),
    );
  }
}
