import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../widgets/common/custom_bottom_nav.dart';
import 'home_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../trip/trip_list.dart';
import '../chatbot/ai_chat.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    final screens = [
      const HomeScreen(),
      const WishlistScreen(),
      const TripListScreen(),
      const AIChatScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: const CustomBottomNav(),
    );
  }
}

