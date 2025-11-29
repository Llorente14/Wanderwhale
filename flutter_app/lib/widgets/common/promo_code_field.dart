import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PromoCodeField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onApply;

  const PromoCodeField({
    super.key,
    required this.controller,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.confirmation_number_outlined,
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.baseS,
              decoration: InputDecoration(
                hintText: "Have a promo code?",
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintStyle: AppTextStyles.baseS.copyWith(color: AppColors.gray3),
              ),
            ),
          ),
          TextButton(
            onPressed: onApply,
            child: Text(
              "Apply",
              style: AppTextStyles.baseS.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
