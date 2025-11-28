import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/login_screen.dart'; // Arah ke Login
import '../auth/register_screen.dart'; // Arah ke Register
import '../../widgets/common/social_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primaryLight3,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER IMAGE
            Hero(
              tag: 'background_image',
              child: Container(
                height: size.height * 0.55,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.gray2,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  image: DecorationImage(
                    image: AssetImage('assets/beach_sign.jpg'),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // TOMBOL UTAMA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  // TOMBOL LOGIN -> KE LOGIN SCREEN
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(
                              milliseconds: 800,
                            ),
                            pageBuilder: (_, __, ___) => const LoginScreen(),
                            transitionsBuilder: (_, a, __, c) =>
                                FadeTransition(opacity: a, child: c),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
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
                  const SizedBox(width: 16),

                  // TOMBOL SIGN UP -> KE REGISTER SCREEN
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(
                              milliseconds: 800,
                            ),
                            pageBuilder: (_, __, ___) => const RegisterScreen(),
                            transitionsBuilder: (_, a, __, c) =>
                                FadeTransition(opacity: a, child: c),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight2,
                        foregroundColor: AppColors.white,
                        elevation: 0,
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
                ],
              ),
            ),

            const SizedBox(height: 25),

            // DIVIDER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Expanded(
                    child: Divider(thickness: 1, color: AppColors.gray2),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "or",
                      style: AppTextStyles.baseS.copyWith(
                        color: AppColors.gray3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(thickness: 1, color: AppColors.gray2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // SOCIAL BUTTONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SocialButton(
                    text: "Continue with Google",
                    imagePath: 'assets/logo_google.png',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  SocialButton(
                    text: "Continue with Facebook",
                    imagePath: 'assets/logo_facebook.png',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  SocialButton(
                    text: "Continue with Apple",
                    imagePath: 'assets/logo_apple.png',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
