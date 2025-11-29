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

class Trip {
  final String id;
  final String destination;
  final String originCity;
  final String destinationCity;
  final DateTime startDate;
  final DateTime endDate;
  final int durationInDays;
  final int travelers;
  final String tripType; // Vacation, Business, Adventure, Romantic, Family, Backpacking
  final String accommodationType;
  final double? budget;
  final String? notes;
  final bool wantFlight;
  final bool wantHotel;
  final String? hotelName;
  final String? roomType;
  final double? hotelPrice;
  final DateTime? hotelCheckIn;
  final DateTime? hotelCheckOut;
  final String syncStatus; // synced, pending, failed
  final Map<String, dynamic>? flight;
  final Map<String, dynamic>? hotel;
  final Map<String, dynamic>? room;

  Trip({
    required this.id,
    required this.destination,
    this.originCity = '',
    this.destinationCity = '',
    required this.startDate,
    required this.endDate,
    required this.durationInDays,
    required this.travelers,
    required this.tripType,
    required this.accommodationType,
    this.budget,
    this.notes,
    this.wantFlight = false,
    this.wantHotel = false,
    this.hotelName,
    this.roomType,
    this.hotelPrice,
    this.hotelCheckIn,
    this.hotelCheckOut,
    this.syncStatus = 'pending',
    this.flight,
    this.hotel,
    this.room,
  });

  // Factory constructor for creating a Trip from JSON
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      destination: json['destination'] as String,
      originCity: json['originCity'] as String? ?? '',
      destinationCity: json['destinationCity'] as String? ?? '',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      durationInDays: (json['durationInDays'] as num?)?.toInt() ?? 0,
      travelers: (json['travelers'] as num?)?.toInt() ?? 1,
      tripType: json['tripType'] as String? ?? 'Vacation',
      accommodationType: json['accommodationType'] as String? ?? 'Hotel',
      budget: json['budget'] != null ? (json['budget'] as num).toDouble() : null,
      notes: json['notes'] as String?,
      wantFlight: json['wantFlight'] as bool? ?? false,
      wantHotel: json['wantHotel'] as bool? ?? false,
      hotelName: json['hotelName'] as String?,
      roomType: json['roomType'] as String?,
      hotelPrice: json['hotelPrice'] != null ? (json['hotelPrice'] as num).toDouble() : null,
      hotelCheckIn: json['hotelCheckIn'] != null ? DateTime.parse(json['hotelCheckIn'] as String) : null,
      hotelCheckOut: json['hotelCheckOut'] != null ? DateTime.parse(json['hotelCheckOut'] as String) : null,
      syncStatus: json['syncStatus'] as String? ?? 'pending',
      flight: json['flight'] as Map<String, dynamic>?,
      hotel: json['hotel'] as Map<String, dynamic>?,
      room: json['room'] as Map<String, dynamic>?,
    );
  }

  // Convert Trip to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destination': destination,
      'originCity': originCity,
      'destinationCity': destinationCity,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'durationInDays': durationInDays,
      'travelers': travelers,
      'tripType': tripType,
      'accommodationType': accommodationType,
      'budget': budget,
      'notes': notes,
      'wantFlight': wantFlight,
      'wantHotel': wantHotel,
      'hotelName': hotelName,
      'roomType': roomType,
      'hotelPrice': hotelPrice,
      'hotelCheckIn': hotelCheckIn?.toIso8601String(),
      'hotelCheckOut': hotelCheckOut?.toIso8601String(),
      'hotelCheckOut': hotelCheckOut?.toIso8601String(),
      'syncStatus': syncStatus,
      'flight': flight,
      'hotel': hotel,
      'room': room,
    };
  }

  // Copy with method for updating trips
  Trip copyWith({
    String? id,
    String? destination,
    String? originCity,
    String? destinationCity,
    DateTime? startDate,
    DateTime? endDate,
    int? durationInDays,
    int? travelers,
    String? tripType,
    String? accommodationType,
    double? budget,
    String? notes,
    bool? wantFlight,
    bool? wantHotel,
    String? hotelName,
    String? roomType,
    double? hotelPrice,
    DateTime? hotelCheckIn,
    DateTime? hotelCheckOut,
    String? syncStatus,
    Map<String, dynamic>? flight,
    Map<String, dynamic>? hotel,
    Map<String, dynamic>? room,
  }) {
    return Trip(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      originCity: originCity ?? this.originCity,
      destinationCity: destinationCity ?? this.destinationCity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationInDays: durationInDays ?? this.durationInDays,
      travelers: travelers ?? this.travelers,
      tripType: tripType ?? this.tripType,
      accommodationType: accommodationType ?? this.accommodationType,
      budget: budget ?? this.budget,
      notes: notes ?? this.notes,
      wantFlight: wantFlight ?? this.wantFlight,
      wantHotel: wantHotel ?? this.wantHotel,
      hotelName: hotelName ?? this.hotelName,
      roomType: roomType ?? this.roomType,
      hotelPrice: hotelPrice ?? this.hotelPrice,
      hotelCheckIn: hotelCheckIn ?? this.hotelCheckIn,
      hotelCheckOut: hotelCheckOut ?? this.hotelCheckOut,
      syncStatus: syncStatus ?? this.syncStatus,
      flight: flight ?? this.flight,
      hotel: hotel ?? this.hotel,
      room: room ?? this.room,
    );
  }

  // Formatted date range getter
  String get formattedDateRange {
    final startFormatted = _formatDate(startDate);
    final endFormatted = _formatDate(endDate);
    return '$startFormatted – $endFormatted';
  }

  // Formatted start date
  String get formattedStartDate => _formatDate(startDate);

  // Formatted end date
  String get formattedEndDate => _formatDate(endDate);

  // Duration string
  String get durationString => '$durationInDays ${durationInDays == 1 ? 'day' : 'days'}';

  // Formatted budget
  String? get formattedBudget {
    if (budget == null) return null;
    return '\$${budget!.toStringAsFixed(0)}';
  }

  // Helper method to format dates
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

