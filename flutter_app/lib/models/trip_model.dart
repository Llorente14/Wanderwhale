class Trip {
  final String id;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int durationInDays;
  final int travelers;
  final String tripType; // Vacation, Business, Adventure, Romantic, Family, Backpacking
  final String accommodationType;
  final double? budget;
  final String? notes;

  Trip({
    required this.id,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.durationInDays,
    required this.travelers,
    required this.tripType,
    required this.accommodationType,
    this.budget,
    this.notes,
  });

  // Factory constructor for creating a Trip from JSON
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      destination: json['destination'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      durationInDays: json['durationInDays'] as int,
      travelers: json['travelers'] as int,
      tripType: json['tripType'] as String,
      accommodationType: json['accommodationType'] as String,
      budget: json['budget'] != null ? (json['budget'] as num).toDouble() : null,
      notes: json['notes'] as String?,
    );
  }

  // Convert Trip to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'durationInDays': durationInDays,
      'travelers': travelers,
      'tripType': tripType,
      'accommodationType': accommodationType,
      'budget': budget,
      'notes': notes,
    };
  }

  // Copy with method for updating trips
  Trip copyWith({
    String? id,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    int? durationInDays,
    int? travelers,
    String? tripType,
    String? accommodationType,
    double? budget,
    String? notes,
  }) {
    return Trip(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationInDays: durationInDays ?? this.durationInDays,
      travelers: travelers ?? this.travelers,
      tripType: tripType ?? this.tripType,
      accommodationType: accommodationType ?? this.accommodationType,
      budget: budget ?? this.budget,
      notes: notes ?? this.notes,
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

