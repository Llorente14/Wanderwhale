import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart'; // Import warna
import '../../core/theme/app_text_styles.dart'; // Import text style

class GlassTextField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;

  const GlassTextField({
    super.key,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.9), // Putih Tebal
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.white),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: AppTextStyles.baseM.copyWith(
          color: AppColors.black,
        ), // Teks Hitam
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.baseM.copyWith(
            color: AppColors.gray3,
          ), // Hint Abu
          prefixIcon: Icon(icon, color: AppColors.gray3),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          filled:
              false, // Matikan filled bawaan tema karena kita pakai Container
        ),
      ),
    );
  }
}
