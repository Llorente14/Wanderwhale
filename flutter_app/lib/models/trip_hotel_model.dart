// lib/models/trip_hotel_model.dart

class TripHotelModel {
  final String hotelId;
  final String tripId;
  final String? destinationId;
  final String hotelName;
  final String? address;
  final String? city;
  final String? country;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numberOfNights;
  final double totalPrice;
  final String currency;
  final double rating;
  final String? imageUrl;
  final String? confirmationNumber;
  final String bookingStatus; // pending, confirmed, cancelled

  TripHotelModel({
    required this.hotelId,
    required this.tripId,
    this.destinationId,
    required this.hotelName,
    this.address,
    this.city,
    this.country,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfNights,
    required this.totalPrice,
    required this.currency,
    required this.rating,
    this.imageUrl,
    this.confirmationNumber,
    required this.bookingStatus,
  });

  factory TripHotelModel.fromJson(Map<String, dynamic> json) {
    return TripHotelModel(
      hotelId: json['hotelId'] ?? '',
      tripId: json['tripId'] ?? '',
      destinationId: json['destinationId'],
      hotelName: json['hotelName'] ?? 'Unknown Hotel',
      address: json['address'],
      city: json['city'],
      country: json['country'],
      checkInDate: _parseTimestamp(json['checkInDate']),
      checkOutDate: _parseTimestamp(json['checkOutDate']),
      numberOfNights: json['numberOfNights'] ?? 0,
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'IDR',
      rating: (json['rating'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'],
      confirmationNumber: json['confirmationNumber'],
      bookingStatus: json['bookingStatus'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hotelId': hotelId,
      'tripId': tripId,
      'destinationId': destinationId,
      'hotelName': hotelName,
      'address': address,
      'city': city,
      'country': country,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
      'numberOfNights': numberOfNights,
      'totalPrice': totalPrice,
      'currency': currency,
      'rating': rating,
      'imageUrl': imageUrl,
      'confirmationNumber': confirmationNumber,
      'bookingStatus': bookingStatus,
    };
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
