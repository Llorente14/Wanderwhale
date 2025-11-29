// lib/services/fcm_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Request permission (iOS) and return the current device token
  Future<String?> getDeviceToken() async {
    try {
      // Request permission on iOS/macOS
      await _messaging.requestPermission();
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      return null;
    }
  }

  /// Listen to token refresh stream
  Stream<String?> onTokenRefresh() => _messaging.onTokenRefresh;
}
