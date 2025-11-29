import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../user/edit_profile.dart';
import 'about_us_screen.dart';
import 'privacy_notice_screen.dart';
import 'terms_and_conditions_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          'Settings',
          style: TextStyle(
            color: AppColors.gray5,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('ACCOUNT & SECURITY'),
            _buildSettingsTile(
              context,
              icon: Icons.person_outline,
              title: 'Account Information',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.lock_outline,
              title: 'Password & Security',
              onTap: () {
                // TODO: Implement Password & Security
              },
            ),

            _buildSectionHeader('CONTACT SERVICE'),
            _buildSettingsTile(
              context,
              icon: Icons.headset_mic_outlined,
              title: 'Customer Service',
              onTap: () {
                // TODO: Implement Customer Service
              },
            ),

            const SizedBox(height: 12),
            _buildSettingsTile(
              context,
              title: 'App Version',
              trailingText: '1.0.0',
              showChevron: false,
            ),
            _buildSettingsTile(
              context,
              title: 'Terms & Conditions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TermsAndConditionsScreen(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context,
              title: 'Privacy Notice',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyNoticeScreen(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              context,
              title: 'About Us',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutUsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildSettingsTile(
              context,
              icon: Icons.power_settings_new,
              title: 'Log Out',
              textColor: AppColors.error,
              iconColor: AppColors.error,
              showChevron: true, // Or false if we want it to look like a button
              onTap: () {
                // TODO: Implement Logout
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.gray3,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    IconData? icon,
    required String title,
    String? trailingText,
    Color? textColor,
    Color? iconColor,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: iconColor ?? AppColors.gray4,
                  size: 24,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor ?? AppColors.gray5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gray3,
                  ),
                ),
              if (showChevron) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.gray3,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
