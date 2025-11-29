import 'package:flutter/material.dart';
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
  final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    final screens = [
      Navigator(
        key: _homeNavigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          );
        },
      ),
      const WishlistScreen(),
      const TripListScreen(),
      const AIChatScreen(),
      const SettingsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (currentIndex == 0) {
          final navigator = _homeNavigatorKey.currentState;
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
            return;
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
        bottomNavigationBar: CustomBottomNav(
          onIndexChanged: (index) {
            if (currentIndex == index && index == 0) {
              // If tapping Home while on Home, reset stack
              _homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
            } else {
              ref.read(bottomNavIndexProvider.notifier).state = index;
            }
          },
        ),
      ),
    );
  }
}
