// lib/models/trip_destination_model.dart

class TripDestinationModel {
  final String destinationId;
  final String tripId;
  final String destinationName;
  final String country;
  final String city;
  final double latitude;
  final double longitude;
  final DateTime arrivalDate;
  final DateTime departureDate;
  final int dayNumber;
  final String notes;
  final String? imageUrl;
  final List<String> activities;
  final int order;

  TripDestinationModel({
    required this.destinationId,
    required this.tripId,
    required this.destinationName,
    required this.country,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.arrivalDate,
    required this.departureDate,
    required this.dayNumber,
    required this.notes,
    this.imageUrl,
    required this.activities,
    required this.order,
  });

  // From JSON (Firebase Timestamp)
  factory TripDestinationModel.fromJson(Map<String, dynamic> json) {
    return TripDestinationModel(
      destinationId: json['destinationId'] ?? '',
      tripId: json['tripId'] ?? '',
      destinationName: json['destinationName'] ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      arrivalDate: _parseTimestamp(json['arrivalDate']),
      departureDate: _parseTimestamp(json['departureDate']),
      dayNumber: json['dayNumber'] ?? 0,
      notes: json['notes'] ?? '',
      imageUrl: json['imageUrl'],
      activities: List<String>.from(json['activities'] ?? []),
      order: json['order'] ?? 0,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'destinationId': destinationId,
      'tripId': tripId,
      'destinationName': destinationName,
      'country': country,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'arrivalDate': arrivalDate.toIso8601String(),
      'departureDate': departureDate.toIso8601String(),
      'dayNumber': dayNumber,
      'notes': notes,
      'imageUrl': imageUrl,
      'activities': activities,
      'order': order,
    };
  }

  // Helper untuk durasi
  int get durationInDays => departureDate.difference(arrivalDate).inDays;
}

// --- Helper Parser Timestamp (dicopy dari TripModel) ---

DateTime _parseTimestamp(dynamic timestamp) {
  if (timestamp == null) return DateTime.now();

  if (timestamp is Map && timestamp.containsKey('_seconds')) {
    // Format Timestamp Firestore dari Backend (saat di-serialize ke JSON)
    return DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
  } else if (timestamp is String) {
    // Format ISO String
    return DateTime.parse(timestamp);
  } else if (timestamp is int) {
    // Format Milliseconds
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // Fallback
  return DateTime.now();
}
