import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray0,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray5),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About Us',
          style: TextStyle(
            color: AppColors.gray5,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'About Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.gray5,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Wanderwhale is your ultimate travel companion. We help you discover new places, plan your trips, and connect with other travelers.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray4,
                height: 1.5,
              ),
            ),
            // Add more content as needed
          ],
        ),
      ),
    );
  }
}
