// lib/models/hotel_booking_model.dart

class HotelBookingModel {
  final String bookingId;
  final String userId;
  final String tripId;
  final String offerId;
  final String? providerConfirmationId;
  final String bookingStatus;
  final String hotelName;
  final String? hotelAddress;
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? continent;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final String? roomType;
  final String? roomDescription;
  final int numberOfGuests;
  final String primaryGuestName;
  final double totalPrice;
  final double basePrice;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? bookedAt;
  final Map<String, dynamic>? policies;
  final List<Map<String, dynamic>> guests;

  HotelBookingModel({
    required this.bookingId,
    required this.userId,
    required this.tripId,
    required this.offerId,
    this.providerConfirmationId,
    required this.bookingStatus,
    required this.hotelName,
    this.hotelAddress,
    this.city,
    this.country,
    this.latitude,
    this.longitude,
    this.continent,
    this.checkInDate,
    this.checkOutDate,
    this.roomType,
    this.roomDescription,
    required this.numberOfGuests,
    required this.primaryGuestName,
    required this.totalPrice,
    required this.basePrice,
    required this.currency,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
    this.bookedAt,
    this.policies,
    required this.guests,
  });

  factory HotelBookingModel.fromJson(Map<String, dynamic> json) {
    return HotelBookingModel(
      bookingId: json['bookingId'] ?? '',
      userId: json['userId'] ?? '',
      tripId: json['tripId'] ?? '',
      offerId: json['offerId'] ?? json['referenceId'] ?? '',
      providerConfirmationId: json['providerConfirmationId'],
      bookingStatus: json['bookingStatus'] ?? json['status'] ?? 'PENDING',
      hotelName: json['hotelName'] ?? '',
      hotelAddress: json['hotelAddress'],
      city: json['city'],
      country: json['country'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      continent: json['continent'],
      checkInDate: _parseTimestamp(json['checkInDate']),
      checkOutDate: _parseTimestamp(json['checkOutDate']),
      roomType: json['roomType'],
      roomDescription: json['roomDescription'],
      numberOfGuests: json['numberOfGuests'] ?? 1,
      primaryGuestName: json['primaryGuestName'] ?? '',
      totalPrice:
          double.tryParse(json['totalPrice']?.toString() ?? '0')?.toDouble() ??
              0,
      basePrice:
          double.tryParse(json['basePrice']?.toString() ?? '0')?.toDouble() ??
              0,
      currency: json['currency'] ?? 'IDR',
      paymentMethod: json['paymentMethod'] ?? 'unknown',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      createdAt: _parseTimestamp(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(json['updatedAt']) ?? DateTime.now(),
      bookedAt: _parseTimestamp(json['bookedAt']),
      policies: json['policies'] as Map<String, dynamic>?,
      guests: List<Map<String, dynamic>>.from(json['guests'] ?? []),
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

