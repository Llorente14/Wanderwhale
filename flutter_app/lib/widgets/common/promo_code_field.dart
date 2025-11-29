import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PromoCodeField extends StatefulWidget {
  final TextEditingController controller;
  final String? initialValue;
  final void Function(String code) onApply;

  const PromoCodeField({
    super.key,
    required this.controller,
    this.initialValue,
    required this.onApply,
  });

  @override
  State<PromoCodeField> createState() => _PromoCodeFieldState();
}

class _PromoCodeFieldState extends State<PromoCodeField> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
      _hasText = widget.initialValue!.trim().isNotEmpty;
    }
    // Listen to text changes
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

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
              controller: widget.controller,
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
            onPressed: _hasText
                ? () {
                    widget.onApply(widget.controller.text.trim());
                  }
                : null,
            child: Text(
              "Apply",
              style: AppTextStyles.baseS.copyWith(
                fontWeight: FontWeight.bold,
                color: _hasText ? AppColors.primary : AppColors.gray3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
