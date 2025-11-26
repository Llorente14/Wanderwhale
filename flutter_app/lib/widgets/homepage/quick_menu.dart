// lib/widgets/home/quick_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

class QuickMenu extends ConsumerWidget {
  const QuickMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _QuickMenuItem(
            icon: Icons.flight,
            label: 'Home',
            color: AppColors.primaryLight2,
            onTap: () {
              ref.read(bottomNavIndexProvider.notifier).state = 0;
            },
          ),
          _QuickMenuItem(
            icon: Icons.favorite,
            label: 'Favorite',
            color: AppColors.primary,
            onTap: () {
              ref.read(bottomNavIndexProvider.notifier).state = 1;
            },
          ),
          _QuickMenuItem(
            icon: Icons.add_circle,
            label: 'Planning',
            color: AppColors.primaryDark1,
            onTap: () {
              ref.read(bottomNavIndexProvider.notifier).state = 2;
            },
          ),
        ],
      ),
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickMenuItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
