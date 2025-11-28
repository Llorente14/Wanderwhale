// lib/models/location_model.dart

// Model ini mem-parsing respons dari API Amadeus
// GET /v1/reference-data/locations (yang dipanggil oleh /api/flights/search/locations)

class LocationModel {
  final String type; // "location"
  final String subType; // "CITY" atau "AIRPORT"
  final String name; // "JAKARTA" atau "SOEKARNO-HATTA INTL"
  final String detailedName; // "JAKARTA, INDONESIA"
  final String iataCode; // "JKT" atau "CGK"
  final Address address;

  LocationModel({
    required this.type,
    required this.subType,
    required this.name,
    required this.detailedName,
    required this.iataCode,
    required this.address,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      type: json['type'] ?? 'location',
      subType: json['subType'] ?? 'UNKNOWN',
      name: json['name'] ?? 'Unknown',
      detailedName: json['detailedName'] ?? json['name'] ?? '',
      iataCode: json['iataCode'] ?? '',
      address: Address.fromJson(json['address'] ?? {}),
    );
  }

  // Helper getter untuk tampilan UI yang lebih ramah
  String get displayName {
    // Menampilkan "Jakarta (JKT)" atau "Soekarno-Hatta (CGK)"
    return '${_toTitleCase(name)} ($iataCode)';
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return '';
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

class Address {
  final String? cityCode;
  final String? countryCode;

  Address({this.cityCode, this.countryCode});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      cityCode: json['cityCode'],
      countryCode: json['countryCode'],
    );
  }
}
