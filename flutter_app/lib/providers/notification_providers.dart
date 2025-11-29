// lib/providers/notification_providers.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import '../services/api_service.dart';
import 'app_providers.dart';
import 'auth_provider.dart';

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((
  ref,
) async {
  // Check auth state first
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;

  if (user == null) {
    // User belum login, throw error yang jelas
    throw DioException(
      requestOptions: RequestOptions(path: '/notifications'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/notifications'),
        statusCode: 401,
      ),
      message: 'Silakan login terlebih dahulu untuk mengakses notifikasi.',
    );
  }

  try {
    final api = ref.watch(apiServiceProvider);
    return await api.getNotifications();
  } on DioException catch (e) {
    // Handle 404 - endpoint belum tersedia atau user belum memiliki notifications
    if (e.response?.statusCode == 404) {
      // Return empty list jika 404 (normal jika user belum punya notifications)
      return [];
    }
    // Re-throw error lainnya (401, 500, dll)
    rethrow;
  }
});

final unreadNotificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
      // Check auth state first
      final authState = ref.watch(authStateProvider);
      final user = authState.valueOrNull;

      if (user == null) {
        // User belum login, return empty list untuk unread (tidak perlu error)
        return [];
      }

      try {
        final api = ref.watch(apiServiceProvider);
        return await api.getNotifications(unreadOnly: true);
      } on DioException catch (e) {
        // Handle 404 atau 500 - return empty list
        if (e.response?.statusCode == 404 || e.response?.statusCode == 500) {
          return [];
        }
        // Re-throw error lainnya (401, dll)
        rethrow;
      }
    });

final notificationControllerProvider = Provider<NotificationController>((ref) {
  final api = ref.watch(apiServiceProvider);
  return NotificationController(api);
});

class NotificationController {
  NotificationController(this._api);

  final ApiService _api;

  Future<void> markRead(String notificationId) {
    return _api.markNotificationRead(notificationId);
  }

  Future<void> markAllRead() {
    return _api.markAllNotificationsRead();
  }

  Future<void> delete(String notificationId) {
    return _api.deleteNotification(notificationId);
  }
}
