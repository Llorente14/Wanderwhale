import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_screen_provider.dart';
import '../providers/providers.dart';
import 'main/main_navigation_screen.dart';
import 'main/welcome_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Max 4 seconds
    );

    // Listen to animation status
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Check auth state and navigate accordingly
        _navigateAfterSplash();
      }
    });

    // Start animation
    _animationController.forward();
  }

  void _navigateAfterSplash() {
    // Check current user directly from FirebaseAuth
    final user = ref.read(authStateProvider).valueOrNull;

    if (mounted) {
      if (user == null) {
        // User belum login, redirect ke welcome screen dengan login state
        ref.read(authScreenProvider.notifier).state = AuthScreenType.login;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      } else {
        // User sudah login, redirect ke main navigation
        // Pastikan index bottom nav diatur ke 0 (Home) sebelum navigasi
        ref.read(bottomNavIndexProvider.notifier).state = 0;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final animationWidth = screenWidth * 0.7; // 70% of screen width

    return Scaffold(
      backgroundColor: AppColors.primaryLight3,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation
              SizedBox(
                width: animationWidth,
                height: animationWidth, // Square aspect ratio
                child: Lottie.asset(
                  'assets/animations/splash_animation.json',
                  controller: _animationController,
                  fit: BoxFit.contain,
                  onLoaded: (composition) {
                    // Set animation duration based on actual Lottie file duration
                    // But cap it at 4 seconds max
                    final actualDuration = composition.duration;
                    if (actualDuration.inSeconds < 4) {
                      _animationController.duration = actualDuration;
                    } else {
                      _animationController.duration = const Duration(
                        seconds: 4,
                      );
                    }
                    // Restart animation with correct duration
                    _animationController.reset();
                    _animationController.forward();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback jika file tidak ditemukan
                    return const Icon(
                      Icons.travel_explore,
                      size: 120,
                      color: AppColors.primary,
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              // App Name Text (Optional)
              const Text(
                'WanderWhale',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
