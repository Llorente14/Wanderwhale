// lib/models/flight_booking_model.dart

class FlightBookingModel {
  final String bookingId;
  final String userId;
  final String tripId;
  final String bookingType;
  final String confirmationNumber;
  final String bookingStatus;
  final String origin;
  final String destination;
  final DateTime? departureDate;
  final DateTime? arrivalDate;
  final String airline;
  final String flightNumber;
  final int numberOfPassengers;
  final String primaryPassengerName;
  final String primaryPassengerEmail;
  final double totalPrice;
  final double basePrice;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Map<String, dynamic>> passengers;
  final List<Map<String, dynamic>> segments;
  final List<Map<String, dynamic>>? selectedSeats;

  FlightBookingModel({
    required this.bookingId,
    required this.userId,
    required this.tripId,
    required this.bookingType,
    required this.confirmationNumber,
    required this.bookingStatus,
    required this.origin,
    required this.destination,
    this.departureDate,
    this.arrivalDate,
    required this.airline,
    required this.flightNumber,
    required this.numberOfPassengers,
    required this.primaryPassengerName,
    required this.primaryPassengerEmail,
    required this.totalPrice,
    required this.basePrice,
    required this.currency,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.passengers,
    required this.segments,
    this.selectedSeats,
  });

  factory FlightBookingModel.fromJson(Map<String, dynamic> json) {
    return FlightBookingModel(
      bookingId: json['bookingId'] ?? '',
      userId: json['userId'] ?? '',
      tripId: json['tripId'] ?? '',
      bookingType: json['bookingType'] ?? 'flight',
      confirmationNumber: json['confirmationNumber'] ?? '',
      bookingStatus: json['bookingStatus'] ?? json['status'] ?? 'PENDING',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      departureDate: _parseTimestamp(json['departureDate']),
      arrivalDate: _parseTimestamp(json['arrivalDate']),
      airline: json['airline'] ?? '',
      flightNumber: json['flightNumber'] ?? '',
      numberOfPassengers: json['numberOfPassengers'] ?? 1,
      primaryPassengerName: json['primaryPassengerName'] ?? '',
      primaryPassengerEmail: json['primaryPassengerEmail'] ?? '',
      totalPrice:
          double.tryParse(json['totalPrice']?.toString() ?? '0') ?? 0,
      basePrice: double.tryParse(json['basePrice']?.toString() ?? '0') ?? 0,
      currency: json['currency'] ?? 'IDR',
      paymentMethod: json['paymentMethod'] ?? 'unknown',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      createdAt: _parseTimestamp(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(json['updatedAt']) ?? DateTime.now(),
      passengers: List<Map<String, dynamic>>.from(json['passengers'] ?? []),
      segments: List<Map<String, dynamic>>.from(json['segments'] ?? []),
      selectedSeats: json['selectedSeats'] != null
          ? List<Map<String, dynamic>>.from(json['selectedSeats'])
          : null,
    );
  }
}

DateTime? _parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is Map && value.containsKey('_seconds')) {
    return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return null;
}

