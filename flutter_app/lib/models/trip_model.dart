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
      durationInDays: json['durationInDays'] as int,
      travelers: json['travelers'] as int,
      tripType: json['tripType'] as String,
      accommodationType: json['accommodationType'] as String,
      budget: json['budget'] != null ? (json['budget'] as num).toDouble() : null,
      notes: json['notes'] as String?,
      wantFlight: json['wantFlight'] as bool? ?? false,
      wantHotel: json['wantHotel'] as bool? ?? false,
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

