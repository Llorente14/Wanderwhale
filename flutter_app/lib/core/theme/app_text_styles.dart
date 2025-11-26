import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart'; // Impor warna Anda

// Kelas ini memegang semua text style untuk aplikasi
class AppTextStyles {
  // Font utama (ganti 'PlusJakartaSans' dengan font kustom Anda jika ada)
  static const String _fontFamily = 'PlusJakartaSans';

  // --- DEFINISI STYLE ---

  static const TextStyle headingXL = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.gray5,
  );

  static const TextStyle headingL = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.gray5,
  );

  static const TextStyle headingM = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.gray5,
  );

  static const TextStyle headingS = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600, // Semi-bold
    color: AppColors.gray5,
  );

  static const TextStyle baseM = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.gray4,
  );

  static const TextStyle baseS = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.gray4,
  );

  static const TextStyle baseXS = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.gray3,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.gray3,
  );

  static const TextStyle captionS = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 8,
    fontWeight: FontWeight.w400,
    color: AppColors.gray3,
  );
}
