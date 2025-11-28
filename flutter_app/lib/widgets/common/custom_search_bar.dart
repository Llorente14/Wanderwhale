// lib/widgets/common/custom_search_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../utils/constants.dart';

class CustomSearchBar extends ConsumerStatefulWidget {
  const CustomSearchBar({Key? key}) : super(key: key);

  @override
  ConsumerState<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends ConsumerState<CustomSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.gray1, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: AppColors.gray3, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: AppStrings.searchPlaceholder,
                  hintStyle: TextStyle(color: AppColors.gray2, fontSize: 14),
                  border: InputBorder.none,
                  focusedBorder:
                      InputBorder.none, // Menghilangkan border saat focus
                  enabledBorder:
                      InputBorder.none, // Menghilangkan border saat enabled
                  errorBorder:
                      InputBorder.none, // Menghilangkan border saat error
                  disabledBorder:
                      InputBorder.none, // Menghilangkan border saat disabled
                  focusedErrorBorder: InputBorder
                      .none, // Menghilangkan border saat focused error
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 14, color: AppColors.gray5),
                onSubmitted: (value) {
                  // Navigate to search results screen
                  if (value.isNotEmpty) {
                    // TODO: Navigate to search screen with query
                    print('Search query: $value');
                  }
                },
              ),
            ),
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 5),
              decoration: const BoxDecoration(
                color: AppColors.gray0,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.tune, size: 20),
                color: AppColors.gray5,
                onPressed: () {
                  // Open filter options
                },
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
