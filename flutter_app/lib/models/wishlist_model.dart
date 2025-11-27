// lib/models/wishlist_model.dart

class WishlistModel {
  final String id; // ID dokumen wishlist
  final String userId;
  final String destinationId;
  final String destinationName;
  final String? destinationCity;
  final String? destinationCountry;
  final String? destinationImageUrl;
  final double? destinationRating;
  final List<String> destinationTags;
  final DateTime addedAt;

  WishlistModel({
    required this.id,
    required this.userId,
    required this.destinationId,
    required this.destinationName,
    this.destinationCity,
    this.destinationCountry,
    this.destinationImageUrl,
    this.destinationRating,
    required this.destinationTags,
    required this.addedAt,
  });

  factory WishlistModel.fromJson(Map<String, dynamic> json) {
    return WishlistModel(
      id: json['id'] ?? json['wishlistId'] ?? '',
      userId: json['userId'] ?? '',
      destinationId: json['destinationId'] ?? '',
      destinationName: json['destinationName'] ?? 'Unknown',
      destinationCity: json['destinationCity'],
      destinationCountry: json['destinationCountry'],
      destinationImageUrl: json['destinationImageUrl'],
      destinationRating: (json['destinationRating'] ?? 0.0).toDouble(),
      destinationTags: List<String>.from(json['destinationTags'] ?? []),
      addedAt: _parseTimestamp(json['addedAt']),
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
