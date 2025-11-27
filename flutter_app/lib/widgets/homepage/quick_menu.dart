// lib/widgets/home/quick_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

class QuickMenu extends ConsumerWidget {
  const QuickMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _QuickMenuItem(
            icon: Icons.flight_takeoff,
            label: 'Trip',
            color: AppColors.primary,
            onTap: () {
              // TODO: Navigasi ke halaman daftar penerbangan / trip
            },
          ),
          _QuickMenuItem(
            icon: Icons.hotel,
            label: 'Hotel',
            color: AppColors.primaryLight1,
            onTap: () {
              // TODO: Navigasi ke halaman pencarian hotel
            },
          ),
          _QuickMenuItem(
            icon: Icons.favorite,
            label: 'Wishlist',
            color: AppColors.primaryDark1,
            onTap: () {
              // TODO: Navigasi ke halaman wishlist
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
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 8),

          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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
