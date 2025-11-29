// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_app/models/user_model.dart';
import 'package:flutter_app/services/api_service.dart';

/// AuthService: wrapper yang menyederhanakan penggunaan FirebaseAuth
/// dan pemanggilan backend terkait profil / fcm token.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _api = ApiService();

  AuthService._internal();

  // ------------------ Firebase Auth (Client-side) ------------------
  Future<UserCredential> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
    String? photoURL,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Update profile if provided
    try {
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }
      if (photoURL != null && photoURL.isNotEmpty) {
        await credential.user?.updatePhotoURL(photoURL);
      }
      // Force refresh token/profile
      await credential.user?.reload();
    } catch (_) {
      // Non-fatal: ignore profile update errors here
    }

    return credential;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential;
  }

  Future<void> signOut() async {
    // Only sign out from Firebase here. If you integrate social sign-in packages,
    // add their signOut logic as well.
    await _auth.signOut();
  }

  /// Google sign-in implementation using `google_sign_in` package.
  Future<UserCredential?> signInWithGoogle() async {
    final google = GoogleSignIn();
    final account = await google.signIn();
    if (account == null) return null; // cancelled by user

    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  /// Facebook sign-in implementation using `flutter_facebook_auth`.
  Future<UserCredential?> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login();
    if (result.status != LoginStatus.success) return null;

    final accessToken = result.accessToken?.token;
    if (accessToken == null) return null;

    final credential = FacebookAuthProvider.credential(accessToken);
    return await _auth.signInWithCredential(credential);
  }

  // Apple Sign In removed — social buttons are decorative only.

  // ------------------ Backend related helpers ------------------
  /// Panggil backend untuk membuat profil setelah registrasi
  Future<UserModel> createProfileAfterRegister(
    String displayName,
    String? photoURL,
  ) async {
    return await _api.createProfileAfterRegister(displayName, photoURL);
  }

  /// Ambil profil user dari backend
  Future<UserModel> fetchUserProfile() async {
    return await _api.getUserProfile();
  }

  /// Kirim FCM token ke backend
  Future<void> sendFcmTokenToBackend(String fcmToken) async {
    await _api.updateFcmToken(fcmToken);
  }
}
