// lib/models/booking_model.dart

class BookingModel {
  final String bookingId;
  final String userId;
  final String tripId;
  final String bookingType; // 'flight', 'hotel', 'activity'
  final String referenceId; // offerId dari Amadeus
  final DateTime bookingDate;
  final String status; // pending, confirmed, completed, cancelled
  final double totalAmount;
  final String currency;
  final String paymentStatus; // pending, paid, refunded
  final String? paymentMethod;
  final String? confirmationNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? details;
  // Anda bisa tambahkan Map<String, dynamic> details di sini

  BookingModel({
    required this.bookingId,
    required this.userId,
    required this.tripId,
    required this.bookingType,
    required this.referenceId,
    required this.bookingDate,
    required this.status,
    required this.totalAmount,
    required this.currency,
    required this.paymentStatus,
    this.paymentMethod,
    this.confirmationNumber,
    required this.createdAt,
    required this.updatedAt,
    this.details,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['bookingId'] ?? '',
      userId: json['userId'] ?? '',
      tripId: json['tripId'] ?? '',
      bookingType: json['bookingType'] ?? 'unknown',
      referenceId: json['referenceId'] ?? '',
      bookingDate: _parseTimestamp(json['bookingDate']),
      status: json['status'] ?? 'pending',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'IDR',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      paymentMethod: json['paymentMethod'],
      confirmationNumber: json['confirmationNumber'],
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      details: json['details'] as Map<String, dynamic>?,
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
