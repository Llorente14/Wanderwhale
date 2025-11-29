import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../main/home_screen.dart'; // Navigate to Home after register
import 'login_screen.dart'; // keep Login import for manual navigation link
import '../../widgets/common/glass_text_field.dart';
import '../../widgets/common/circular_social_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Hero(
            tag: 'background_image',
            child: Container(
              height: double.infinity,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/beach_sign.jpg'),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(color: AppColors.black.withOpacity(0.3)),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          "WELCOME",
                          style: AppTextStyles.headingXL.copyWith(
                            color: AppColors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: AppColors.black.withOpacity(0.5),
                                offset: const Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Form Input
                        GlassTextField(
                          hintText: "Nama Lengkap",
                          icon: Icons.person_outline,
                          controller: _nameController,
                        ),
                        const SizedBox(height: 12),
                        GlassTextField(
                          hintText: "Email",
                          icon: Icons.email_outlined,
                          controller: _emailController,
                        ),
                        const SizedBox(height: 12),
                        const GlassTextField(
                          hintText: "Username",
                          icon: Icons.account_circle_outlined,
                        ),
                        const SizedBox(height: 12),
                        GlassTextField(
                          hintText: "Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 12),
                        GlassTextField(
                          hintText: "Confirm Password",
                          icon: Icons.lock_reset_outlined,
                          isPassword: true,
                          controller: _confirmController,
                        ),
                        const SizedBox(height: 12),
                        const GlassTextField(
                          hintText: "Tanggal Lahir",
                          icon: Icons.calendar_today_outlined,
                        ),
                        const SizedBox(height: 12),
                        const GlassTextField(
                          hintText: "Nomor Handphone",
                          icon: Icons.phone_android_outlined,
                        ),

                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    final name = _nameController.text.trim();
                                    final email = _emailController.text.trim();
                                    final password = _passwordController.text;
                                    final confirm = _confirmController.text;

                                    if (password != confirm) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Passwords do not match',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => _isLoading = true);
                                    try {
                                      await ref
                                          .read(authControllerProvider)
                                          .signUpWithEmail(
                                            email,
                                            password,
                                            displayName: name,
                                          );

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Register Success! You are now signed in.",
                                          ),
                                        ),
                                      );

                                      // User is created and signed-in by FirebaseAuth;
                                      // navigate directly to HomeScreen instead of Login.
                                      Navigator.pushReplacement(
                                        context,
                                        PageRouteBuilder(
                                          transitionDuration: const Duration(
                                            milliseconds: 800,
                                          ),
                                          pageBuilder: (_, __, ___) =>
                                              const HomeScreen(),
                                          transitionsBuilder: (_, a, __, c) =>
                                              FadeTransition(
                                                opacity: a,
                                                child: c,
                                              ),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Register failed: ${e.toString()}',
                                          ),
                                        ),
                                      );
                                    } finally {
                                      if (mounted)
                                        setState(() => _isLoading = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              "Sign Up",
                              style: AppTextStyles.baseM.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // NAVIGASI: Register -> Login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: AppTextStyles.baseS.copyWith(
                                color: AppColors.white,
                                shadows: [
                                  Shadow(
                                    color: AppColors.black.withOpacity(0.5),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                // PINDAH KE LOGIN SCREEN
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(
                                      milliseconds: 800,
                                    ),
                                    pageBuilder: (_, __, ___) =>
                                        const LoginScreen(),
                                    transitionsBuilder: (_, a, __, c) =>
                                        FadeTransition(opacity: a, child: c),
                                  ),
                                );
                              },
                              child: Text(
                                "Login",
                                style: AppTextStyles.baseS.copyWith(
                                  color: AppColors.primaryLight1,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.black.withOpacity(0.5),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.white),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularSocialButton(
                              imagePath: 'assets/logo_google.png',
                              onTap: () {},
                            ),
                            const SizedBox(width: 20),
                            CircularSocialButton(
                              imagePath: 'assets/logo_facebook.png',
                              onTap: () {},
                            ),
                            const SizedBox(width: 20),
                            CircularSocialButton(
                              imagePath: 'assets/logo_apple.png',
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
