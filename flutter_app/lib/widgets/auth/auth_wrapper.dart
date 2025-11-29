// lib/widgets/auth/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../screens/main/home_screen.dart';
import '../../screens/main/welcome_screen.dart';

/// Widget wrapper yang mengecek auth state dan menampilkan screen yang sesuai
/// Jika user sudah login -> HomeScreen
/// Jika user belum login -> WelcomeScreen
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        // Jika user sudah login, tampilkan HomeScreen
        if (user != null) {
          return const HomeScreen();
        }
        // Jika user belum login, tampilkan WelcomeScreen
        return const WelcomeScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error checking authentication'),
              const SizedBox(height: 16),
              Text(error.toString()),
            ],
          ),
        ),
      ),
    );
  }
}

