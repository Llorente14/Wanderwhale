// lib/widgets/common/custom_bottom_nav.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

class CustomBottomNav extends ConsumerWidget {
  const CustomBottomNav({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            index: 0,
            currentIndex: currentIndex,
            onTap: () {
              ref.read(bottomNavIndexProvider.notifier).state = 0;
            },
          ),
          _NavItem(
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
            label: 'Favorite',
            index: 1,
            currentIndex: currentIndex,
            onTap: () {
              ref.read(bottomNavIndexProvider.notifier).state = 1;
            },
          ),
          _NavItem(
            icon: Icons.add_circle_outline_outlined,
            activeIcon: Icons.add_circle_outline,
            label: 'Trip',
            index: 2,
            currentIndex: currentIndex,
            onTap: () {
              ref.read(bottomNavIndexProvider.notifier).state = 2;
            },
          ),
          _NavItem(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'AI Chat',
            index: 3,
            currentIndex: currentIndex,
            onTap: () {
              ref.read(bottomNavIndexProvider.notifier).state = 3;
            },
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Settings',
            index: 4,
            currentIndex: currentIndex,
            onTap: () {
              ref.read(bottomNavIndexProvider.notifier).state = 4;
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavItem({
    Key? key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.gray2,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? AppColors.primary : AppColors.gray2,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
