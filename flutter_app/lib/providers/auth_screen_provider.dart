// lib/providers/auth_screen_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider untuk mengelola state screen auth (welcome/login/register)
enum AuthScreenType {
  welcome,
  login,
  register,
}

final authScreenProvider = StateProvider<AuthScreenType>((ref) {
  return AuthScreenType.welcome;
});

