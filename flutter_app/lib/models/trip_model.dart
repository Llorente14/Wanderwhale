// lib/models/trip_model.dart

class TripModel {
  final String tripId;
  final String userId;
  final String tripName;
  final double budget;
  final String currency;
  final String? coverImage;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // draft, confirmed, completed
  final int totalDestinations;
  final int totalHotels;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripModel({
    required this.tripId,
    required this.userId,
    required this.tripName,
    required this.budget,
    required this.currency,
    this.coverImage,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalDestinations,
    required this.totalHotels,
    required this.createdAt,
    required this.updatedAt,
  });

  // From JSON (Firebase Timestamp)
  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      tripId: json['tripId'] ?? '',
      userId: json['userId'] ?? '',
      tripName: json['tripName'] ?? '',
      budget: (json['budget'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'IDR',
      coverImage: json['coverImage'],
      startDate: _parseTimestamp(json['startDate']),
      endDate: _parseTimestamp(json['endDate']),
      status: json['status'] ?? 'draft',
      totalDestinations: json['totalDestinations'] ?? 0,
      totalHotels: json['totalHotels'] ?? 0,
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
    );
  }

  // Parse Firestore Timestamp atau ISO String
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is Map && timestamp.containsKey('_seconds')) {
      // Firestore Timestamp format
      return DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    } else if (timestamp is String) {
      // ISO String format
      return DateTime.parse(timestamp);
    } else if (timestamp is int) {
      // Milliseconds
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    return DateTime.now();
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'userId': userId,
      'tripName': tripName,
      'budget': budget,
      'currency': currency,
      'coverImage': coverImage,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'totalDestinations': totalDestinations,
      'totalHotels': totalHotels,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helpers
  int get durationInDays => endDate.difference(startDate).inDays;
  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isOngoing =>
      DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
  bool get isCompleted => DateTime.now().isAfter(endDate);
}
