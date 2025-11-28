// lib/models/flight_model.dart

class FlightModel {
  final String flightId;
  final String userId;
  final String tripId;
  final String bookingId; // Link ke BookingModel
  final String airline;
  final String flightNumber;
  final String departureAirport;
  final String arrivalAirport;
  final DateTime departureDate;
  final DateTime arrivalDate;
  final double price;
  final String currency;
  final String flightClass; // economy, business, first
  final int passengers;
  final String status; // booked, completed, cancelled

  FlightModel({
    required this.flightId,
    required this.userId,
    required this.tripId,
    required this.bookingId,
    required this.airline,
    required this.flightNumber,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.departureDate,
    required this.arrivalDate,
    required this.price,
    required this.currency,
    required this.flightClass,
    required this.passengers,
    required this.status,
  });

  factory FlightModel.fromJson(Map<String, dynamic> json) {
    return FlightModel(
      flightId: json['flightId'] ?? '',
      userId: json['userId'] ?? '',
      tripId: json['tripId'] ?? '',
      bookingId: json['bookingId'] ?? '',
      airline: json['airline'] ?? 'Unknown Airline',
      flightNumber: json['flightNumber'] ?? '',
      departureAirport: json['departureAirport'] ?? '',
      arrivalAirport: json['arrivalAirport'] ?? '',
      departureDate: _parseTimestamp(json['departureDate']),
      arrivalDate: _parseTimestamp(json['arrivalDate']),
      price: (json['price'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'IDR',
      flightClass: json['class'] ?? 'economy',
      passengers: json['passengers'] ?? 1,
      status: json['status'] ?? 'booked',
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
