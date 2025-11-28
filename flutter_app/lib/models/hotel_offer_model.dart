// lib/models/hotel_offer_model.dart

class HotelOfferGroup {
  final HotelSummary hotel;
  final bool available;
  final List<HotelOffer> offers;

  HotelOfferGroup({
    required this.hotel,
    required this.available,
    required this.offers,
  });

  factory HotelOfferGroup.fromJson(Map<String, dynamic> json) {
    return HotelOfferGroup(
      hotel: HotelSummary.fromJson(json['hotel'] ?? const {}),
      available: json['available'] ?? true,
      offers: (json['offers'] as List<dynamic>? ?? [])
          .map((offer) => HotelOffer.fromJson(offer as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HotelSummary {
  final String hotelId;
  final String name;
  final String? chainCode;
  final String? cityCode;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final HotelAddress? address;
  final HotelContact? contact;

  HotelSummary({
    required this.hotelId,
    required this.name,
    this.chainCode,
    this.cityCode,
    this.latitude,
    this.longitude,
    this.rating,
    this.address,
    this.contact,
  });

  factory HotelSummary.fromJson(Map<String, dynamic> json) {
    return HotelSummary(
      hotelId: json['hotelId'] ?? '',
      name: json['name'] ?? '',
      chainCode: json['chainCode'],
      cityCode: json['cityCode'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString())
          : null,
      address: json['address'] != null
          ? HotelAddress.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      contact: json['contact'] != null
          ? HotelContact.fromJson(json['contact'] as Map<String, dynamic>)
          : null,
    );
  }
}

class HotelAddress {
  final String? lines;
  final String? cityName;
  final String? postalCode;
  final String? countryCode;
  final String? stateCode;

  HotelAddress({
    this.lines,
    this.cityName,
    this.postalCode,
    this.countryCode,
    this.stateCode,
  });

  factory HotelAddress.fromJson(Map<String, dynamic> json) {
    final linesValue = json['lines'];
    String? parsedLine;
    if (linesValue is String) {
      parsedLine = linesValue;
    } else if (linesValue is List && linesValue.isNotEmpty) {
      parsedLine = linesValue.first.toString();
    }
    return HotelAddress(
      lines: parsedLine,
      cityName: json['cityName'],
      postalCode: json['postalCode'],
      countryCode: json['countryCode'],
      stateCode: json['stateCode'],
    );
  }
}

class HotelContact {
  final String? phone;
  final String? email;
  final String? fax;

  HotelContact({this.phone, this.email, this.fax});

  factory HotelContact.fromJson(Map<String, dynamic> json) {
    return HotelContact(
      phone: json['phone'],
      email: json['email'],
      fax: json['fax'],
    );
  }
}

class HotelOffer {
  final String id;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final HotelRoom? room;
  final HotelGuests guests;
  final HotelPrice price;
  final Map<String, dynamic>? policies;
  final String? boardType;
  final String? paymentPolicy;

  HotelOffer({
    required this.id,
    required this.checkInDate,
    required this.checkOutDate,
    this.room,
    required this.guests,
    required this.price,
    this.policies,
    this.boardType,
    this.paymentPolicy,
  });

  factory HotelOffer.fromJson(Map<String, dynamic> json) {
    return HotelOffer(
      id: json['id'] ?? '',
      checkInDate: _tryParseDate(json['checkInDate']),
      checkOutDate: _tryParseDate(json['checkOutDate']),
      room: json['room'] != null
          ? HotelRoom.fromJson(json['room'] as Map<String, dynamic>)
          : null,
      guests: HotelGuests.fromJson(json['guests'] ?? const {}),
      price: HotelPrice.fromJson(json['price'] ?? const {}),
      policies: json['policies'] as Map<String, dynamic>?,
      boardType: json['boardType'],
      paymentPolicy: json['paymentPolicy'],
    );
  }
}

class HotelRoom {
  final String? type;
  final String? description;
  final String? category;
  final int? beds;
  final String? bedType;

  HotelRoom({
    this.type,
    this.description,
    this.category,
    this.beds,
    this.bedType,
  });

  factory HotelRoom.fromJson(Map<String, dynamic> json) {
    final typeEstimated = json['typeEstimated'] as Map<String, dynamic>?;
    final descriptionJson = json['description'] as Map<String, dynamic>?;
    return HotelRoom(
      type: json['type'],
      description: descriptionJson?['text'],
      category: typeEstimated?['category'],
      beds: typeEstimated?['beds'],
      bedType: typeEstimated?['bedType'],
    );
  }
}

class HotelGuests {
  final int adults;
  final int? children;

  HotelGuests({required this.adults, this.children});

  factory HotelGuests.fromJson(Map<String, dynamic> json) {
    return HotelGuests(
      adults: json['adults'] ?? 1,
      children: json['children'],
    );
  }
}

class HotelPrice {
  final String currency;
  final double base;
  final double total;
  final List<Map<String, dynamic>> taxes;

  HotelPrice({
    required this.currency,
    required this.base,
    required this.total,
    required this.taxes,
  });

  factory HotelPrice.fromJson(Map<String, dynamic> json) {
    return HotelPrice(
      currency: json['currency'] ?? 'USD',
      base: double.tryParse(json['base']?.toString() ?? '') ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '') ?? 0,
      taxes: List<Map<String, dynamic>>.from(json['taxes'] ?? []),
    );
  }
}

DateTime? _tryParseDate(String? value) {
  if (value == null) return null;
  return DateTime.tryParse(value);
}

