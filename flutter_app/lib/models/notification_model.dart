// lib/models/notification_model.dart

class NotificationModel {
  final String id; // ID Dokumen
  final String userId;
  final String title;
  final String body;
  final String type; // booking, payment, reminder, promotion
  final String? referenceId; // ID booking, trip, atau promo
  final bool isRead;
  final String? imageUrl;
  final String? actionUrl; // Link deep-link di dalam aplikasi
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    required this.isRead,
    this.imageUrl,
    this.actionUrl,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(String id, Map<String, dynamic> json) {
    return NotificationModel(
      id: id,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'general',
      referenceId: json['referenceId'],
      isRead: json['isRead'] ?? false,
      imageUrl: json['imageUrl'],
      actionUrl: json['actionUrl'],
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }

  // --- Timestamp Helper (Non-Nullable) ---
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Map && timestamp.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.now();
  }
}
