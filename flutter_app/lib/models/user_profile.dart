class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.language,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    this.points = 0,
    this.membershipLevel = 'Bronze',
    this.postCount = 0,
    this.followerCount = 0,
    this.followingCount = 0,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String language;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int points;
  final String membershipLevel;
  final int postCount;
  final int followerCount;
  final int followingCount;

  String get initials {
    if ((displayName ?? '').trim().isEmpty) {
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }

    final parts = displayName!.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? language,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? points,
    String? membershipLevel,
    int? postCount,
    int? followerCount,
    int? followingCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      points: points ?? this.points,
      membershipLevel: membershipLevel ?? this.membershipLevel,
      postCount: postCount ?? this.postCount,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String?,
      photoUrl: json['photoURL'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      dateOfBirth: parseDate(json['dateOfBirth']),
      language: json['language'] as String? ?? 'id',
      currency: json['currency'] as String? ?? 'IDR',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      points: parseInt(json['points']),
      membershipLevel: json['membershipLevel'] as String? ?? 'Bronze',
      postCount: parseInt(json['postCount']),
      followerCount: parseInt(json['followerCount']),
      followingCount: parseInt(json['followingCount']),
    );
  }
}


