import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/theme/app_colors.dart';
import 'main/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
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
        // Navigate to MainNavigationScreen when animation completes
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainNavigationScreen(),
          ),
        );
      }
    });

    // Start animation
    _animationController.forward();
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
                      _animationController.duration = const Duration(seconds: 4);
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

