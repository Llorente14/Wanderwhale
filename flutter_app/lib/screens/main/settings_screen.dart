import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_providers.dart';
import '../main/welcome_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: userAsync.when(
        data: (user) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.gray1,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : const AssetImage('assets/images/avatar_placeholder.png')
                            as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.gray3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Settings Options
            _SettingsSection(
              title: 'Account',
              items: [
                _SettingsItem(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () {
                    // TODO: Navigate to edit profile
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit Profile - Coming Soon')),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {
                    // TODO: Navigate to notification settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification Settings - Coming Soon')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: 'General',
              items: [
                _SettingsItem(
                  icon: Icons.language_outlined,
                  title: 'Language',
                  trailing: const Text('Bahasa Indonesia'),
                  onTap: () {
                    // TODO: Language settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language Settings - Coming Soon')),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    // TODO: Help & Support
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help & Support - Coming Soon')),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    // TODO: About
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('About - Coming Soon')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Logout Button
            Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              child: ElevatedButton(
                onPressed: () => _showLogoutDialog(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat data',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: AppColors.gray3),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _handleLogout(context, ref);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      final controller = ref.read(authControllerProvider);
      await controller.signOut();
      
      if (context.mounted) {
        // Navigate to welcome screen after logout
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const WelcomeScreen(),
          ),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout berhasil'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal logout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray4,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray5,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.gray3,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
