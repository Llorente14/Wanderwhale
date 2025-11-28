// lib/models/user_model.dart

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? phoneNumber;
  final DateTime? dateOfBirth; // Dibuat nullable
  final String language;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.dateOfBirth,
    required this.language,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
  });

  // From JSON (Data dari Firestore)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      phoneNumber: json['phoneNumber'],
      dateOfBirth: _parseNullableTimestamp(
        json['dateOfBirth'],
      ), // Menggunakan parser nullable
      language: json['language'] ?? 'id', // Default
      currency: json['currency'] ?? 'IDR', // Default
      createdAt: _parseTimestamp(
        json['createdAt'],
      ), // Menggunakan parser non-nullable
      updatedAt: _parseTimestamp(json['updatedAt']),
      fcmToken: json['fcmToken'],
    );
  }

  // To JSON (Untuk mengirim data, misal saat update profil)
  Map<String, dynamic> toJson() {
    return {
      // uid dan email biasanya tidak di-update, tapi kita masukkan
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(), // Handle nullable
      'language': language,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'fcmToken': fcmToken,
    };
  }

  // Helper getter untuk inisial (berguna untuk UI)
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final names = displayName!.split(' ');
      if (names.length > 1) {
        return names[0][0].toUpperCase() + names[1][0].toUpperCase();
      }
      return names[0][0].toUpperCase();
    }
    return email[0].toUpperCase();
  }
}

// --- Helper Parser Timestamp ---

// Parser ini (dicopy dari model Anda) mengembalikan DateTime.now() jika null.
// Cocok untuk `createdAt` dan `updatedAt`.
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

// Parser ini mengembalikan NULL jika null.
// Cocok untuk `dateOfBirth`.
DateTime? _parseNullableTimestamp(dynamic timestamp) {
  if (timestamp == null) return null; // <-- Perbedaan utama

  if (timestamp is Map && timestamp.containsKey('_seconds')) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
  } else if (timestamp is String) {
    return DateTime.parse(timestamp);
  } else if (timestamp is int) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // Fallback
  return null;
}
