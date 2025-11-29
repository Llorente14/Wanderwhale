import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'register_screen.dart'; // Import Register (Satu folder)
import '../main/home_screen.dart';
import '../../widgets/common/glass_text_field.dart';
import '../../widgets/common/social_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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
    _emailController.dispose();
    _passwordController.dispose();
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
                        const SizedBox(height: 40),

                        GlassTextField(
                          hintText: "Email / Username",
                          icon: Icons.person_outline,
                          controller: _emailController,
                        ),
                        const SizedBox(height: 16),
                        GlassTextField(
                          hintText: "Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: _passwordController,
                        ),

                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    setState(() => _isLoading = true);
                                    final email = _emailController.text.trim();
                                    final password = _passwordController.text;
                                    try {
                                      await ref
                                          .read(authControllerProvider)
                                          .signInWithEmail(email, password);

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Login successful"),
                                        ),
                                      );

                                      // Navigate to Home after successful login
                                      Navigator.pushReplacement(
                                        context,
                                        PageRouteBuilder(
                                          transitionDuration: const Duration(
                                            milliseconds: 600,
                                          ),
                                          pageBuilder: (_, __, ___) =>
                                              const HomeScreen(),
                                          transitionsBuilder:
                                              (_, animation, __, child) =>
                                                  FadeTransition(
                                                    opacity: animation,
                                                    child: child,
                                                  ),
                                        ),
                                      );
                                    } catch (e) {
                                      if (e is FirebaseAuthException) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Login failed: ${e.code} - ${e.message}',
                                            ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Login failed: ${e.toString()}',
                                            ),
                                          ),
                                        );
                                      }
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
                              "Login",
                              style: AppTextStyles.baseM.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // NAVIGASI: Login -> Register
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have any account yet? ",
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
                                // PINDAH KE REGISTER SCREEN
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(
                                      milliseconds: 800,
                                    ),
                                    pageBuilder: (_, __, ___) =>
                                        const RegisterScreen(),
                                    transitionsBuilder: (_, a, __, c) =>
                                        FadeTransition(opacity: a, child: c),
                                  ),
                                );
                              },
                              child: Text(
                                "Create Account",
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
                        const SizedBox(height: 30),
                        const Divider(color: AppColors.white),
                        const SizedBox(height: 30),

                        SocialButton(
                          text: "Continue with Google",
                          imagePath: 'assets/logo_google.png',
                          onTap: () async {
                            setState(() => _isLoading = true);
                            try {
                              await ref
                                  .read(authControllerProvider)
                                  .signInWithGoogle();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Signed in with Google'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Google sign-in failed: ${e.toString()}',
                                  ),
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        SocialButton(
                          text: "Continue with Facebook",
                          imagePath: 'assets/logo_facebook.png',
                          onTap: () async {
                            setState(() => _isLoading = true);
                            try {
                              await ref
                                  .read(authControllerProvider)
                                  .signInWithFacebook();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Signed in with Facebook'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Facebook sign-in failed: ${e.toString()}',
                                  ),
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        SocialButton(
                          text: "Continue with Apple",
                          imagePath: 'assets/logo_apple.png',
                          onTap: () async {
                            setState(() => _isLoading = true);
                            try {
                              await ref
                                  .read(authControllerProvider)
                                  .signInWithApple();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Signed in with Apple'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Apple sign-in failed: ${e.toString()}',
                                  ),
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                        ),
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
