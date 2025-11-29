import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../widgets/common/custom_bottom_nav.dart';
import 'home_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../trip/trip_list.dart';
import '../chatbot/ai_chat.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  DateTime? _lastBackPressed;

  Future<bool> _onWillPop() async {
    final currentIndex = ref.read(bottomNavIndexProvider);

    // Jika tidak di home screen (index 0), kembali ke home screen
    if (currentIndex != 0) {
      ref.read(bottomNavIndexProvider.notifier).state = 0;
      return false; // Mencegah keluar dari aplikasi
    }

    // Jika di home screen, cek apakah user menekan back dua kali untuk keluar
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tekan kembali sekali lagi untuk keluar'),
          duration: Duration(seconds: 2),
        ),
      );
      return false; // Mencegah keluar dari aplikasi
    }

    // Jika sudah menekan back dua kali, keluar dari aplikasi
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    final screens = [
      const HomeScreen(),
      const WishlistScreen(),
      const TripListScreen(),
      const AIChatScreen(),
      const SettingsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _onWillPop().then((shouldPop) {
          if (shouldPop) {
            SystemNavigator.pop();
          }
        });
      },
      child: Scaffold(
        body: IndexedStack(index: currentIndex, children: screens),
        bottomNavigationBar: const CustomBottomNav(),
      ),
    );
  }
}
