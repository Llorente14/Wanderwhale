import 'package:flutter/material.dart';
import 'package:wanderwhale/core/theme/app_colors.dart';
import 'package:wanderwhale/core/theme/app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,

      scaffoldBackgroundColor: AppColors.gray0,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.white,

        surface: AppColors.white,
        onSurface: AppColors.gray5,
        error: AppColors.error,
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.headingXL,
        displayMedium: AppTextStyles.headingL,
        displaySmall: AppTextStyles.headingM,
        headlineMedium: AppTextStyles.headingS,
        titleLarge: AppTextStyles.headingS.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: AppTextStyles.baseM,
        bodyMedium: AppTextStyles.baseS,
        labelLarge: AppTextStyles.baseM.copyWith(fontWeight: FontWeight.w600),
        bodySmall: AppTextStyles.baseXS,
        labelSmall: AppTextStyles.caption,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.gray5),
        titleTextStyle: AppTextStyles.headingS,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          textStyle: AppTextStyles.baseM.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: AppTextStyles.baseS.copyWith(color: AppColors.gray3),
        hintStyle: AppTextStyles.baseS.copyWith(color: AppColors.gray2),
      ),
    );
  }
}
