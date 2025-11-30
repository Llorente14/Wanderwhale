// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wanderwhale/services/auth_service.dart';
import 'package:wanderwhale/providers/app_providers.dart';
import 'package:wanderwhale/services/fcm_service.dart';
import 'package:wanderwhale/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});

/// Stream provider for FirebaseAuth auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Simple controller to perform auth actions and coordinate profile sync
class AuthController {
  final Ref ref;
  final AuthService _authService;

  AuthController(this.ref) : _authService = ref.read(authServiceProvider);

  Future<void> signInWithEmail(String email, String password) async {
    await _authService.signInWithEmail(email, password);

    // Refresh user profile provider so UI can read fresh data
    ref.invalidate(userProvider);

    // Persist simple flag so app can remember login state across restarts
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
    } catch (_) {}

    // Try to register device FCM token after successful login
    try {
      final fcmService = ref.read(fcmServiceProvider);
      final token = await fcmService.getDeviceToken();
      if (token != null && token.isNotEmpty) {
        await sendFcmToken(token);
      }
    } catch (_) {}
  }

  Future<void> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
    String? photoURL,
  }) async {
    await _authService.signUpWithEmail(
      email,
      password,
      displayName: displayName,
      photoURL: photoURL,
    );

    // Try to create profile on backend (if not exists)
    try {
      if (displayName != null && displayName.isNotEmpty) {
        await _authService.createProfileAfterRegister(displayName, photoURL);
      } else {
        // Create profile with empty displayName to ensure document exists
        await _authService.createProfileAfterRegister('', photoURL);
      }
    } catch (_) {
      // ignore backend profile creation errors; user can retry later
    }

    // Refresh profile
    ref.invalidate(userProvider);
    // Persist login flag
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
    } catch (_) {}
    // After sign-up, register FCM token as well
    try {
      final fcmService = ref.read(fcmServiceProvider);
      final token = await fcmService.getDeviceToken();
      if (token != null && token.isNotEmpty) {
        await sendFcmToken(token);
      }
    } catch (_) {}
  }

  Future<void> signOut() async {
    await _authService.signOut();
    ref.invalidate(userProvider);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
    } catch (_) {}
  }

  Future<void> sendFcmToken(String fcmToken) async {
    await _authService.sendFcmTokenToBackend(fcmToken);
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  final controller = AuthController(ref);

  // Register ApiService unauthorized callback to force sign out when 401
  try {
    ApiService().setOnUnauthorizedCallback(() async {
      try {
        await controller.signOut();
      } catch (_) {}
    });
  } catch (_) {}

  return controller;
});
