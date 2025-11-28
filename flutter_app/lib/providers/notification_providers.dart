// lib/providers/notification_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import '../services/api_service.dart';
import 'app_providers.dart';

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getNotifications();
});

final unreadNotificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getNotifications(unreadOnly: true);
});

final notificationControllerProvider =
    Provider<NotificationController>((ref) {
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
}

