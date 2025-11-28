// lib/models/flight_offer_model.dart

class FlightOfferModel {
  final String id;
  final String source;
  final List<FlightItinerary> itineraries;
  final FlightPrice price;
  final List<String> validatingAirlineCodes;
  final List<TravelerPricing> travelerPricings;

  FlightOfferModel({
    required this.id,
    required this.source,
    required this.itineraries,
    required this.price,
    required this.validatingAirlineCodes,
    required this.travelerPricings,
  });

  factory FlightOfferModel.fromJson(Map<String, dynamic> json) {
    return FlightOfferModel(
      id: json['id'] ?? '',
      source: json['source'] ?? 'GDS',
      itineraries: (json['itineraries'] as List<dynamic>? ?? [])
          .map((itinerary) =>
              FlightItinerary.fromJson(itinerary as Map<String, dynamic>))
          .toList(),
      price: FlightPrice.fromJson(json['price'] ?? const {}),
      validatingAirlineCodes:
          List<String>.from(json['validatingAirlineCodes'] ?? const []),
      travelerPricings: (json['travelerPricings'] as List<dynamic>? ?? [])
          .map((pricing) =>
              TravelerPricing.fromJson(pricing as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FlightItinerary {
  final List<FlightSegment> segments;

  FlightItinerary({required this.segments});

  factory FlightItinerary.fromJson(Map<String, dynamic> json) {
    return FlightItinerary(
      segments: (json['segments'] as List<dynamic>? ?? [])
          .map(
              (segment) => FlightSegment.fromJson(segment as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FlightSegment {
  final String carrierCode;
  final String number;
  final FlightEndpoint departure;
  final FlightEndpoint arrival;
  final String? aircraft;
  final String? duration;
  final FlightOperating? operating;
  final FlightSegmentPricing? pricing;

  FlightSegment({
    required this.carrierCode,
    required this.number,
    required this.departure,
    required this.arrival,
    this.aircraft,
    this.duration,
    this.operating,
    this.pricing,
  });

  factory FlightSegment.fromJson(Map<String, dynamic> json) {
    return FlightSegment(
      carrierCode: json['carrierCode'] ?? '',
      number: json['number'] ?? '',
      departure: FlightEndpoint.fromJson(json['departure'] ?? const {}),
      arrival: FlightEndpoint.fromJson(json['arrival'] ?? const {}),
      aircraft: json['aircraft']?['code'],
      duration: json['duration'],
      operating: json['operating'] != null
          ? FlightOperating.fromJson(json['operating'] as Map<String, dynamic>)
          : null,
      pricing: json['pricingDetailPerAdult'] != null
          ? FlightSegmentPricing.fromJson(
              json['pricingDetailPerAdult'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class FlightEndpoint {
  final String iataCode;
  final DateTime? at;
  final TerminalInfo? terminal;

  FlightEndpoint({required this.iataCode, required this.at, this.terminal});

  factory FlightEndpoint.fromJson(Map<String, dynamic> json) {
    return FlightEndpoint(
      iataCode: json['iataCode'] ?? '',
      at: _tryParseDateTime(json['at']),
      terminal: json['terminal'] != null
          ? TerminalInfo(code: json['terminal'])
          : null,
    );
  }
}

class TerminalInfo {
  final String code;

  TerminalInfo({required this.code});
}

class FlightOperating {
  final String carrierCode;

  FlightOperating({required this.carrierCode});

  factory FlightOperating.fromJson(Map<String, dynamic> json) {
    return FlightOperating(carrierCode: json['carrierCode'] ?? '');
  }
}

class FlightSegmentPricing {
  final String? travelClass;
  final String? fareBasis;
  final String? brandedFare;
  final bool? isRefundable;
  final bool? isChangeAllowed;

  FlightSegmentPricing({
    this.travelClass,
    this.fareBasis,
    this.brandedFare,
    this.isRefundable,
    this.isChangeAllowed,
  });

  factory FlightSegmentPricing.fromJson(Map<String, dynamic> json) {
    return FlightSegmentPricing(
      travelClass: json['travelClass'],
      fareBasis: json['fareBasis'],
      brandedFare: json['brandedFare'],
      isRefundable: json['isRefundable'],
      isChangeAllowed: json['isChangeAllowed'],
    );
  }
}

class FlightPrice {
  final String currency;
  final double total;
  final double base;
  final List<Map<String, dynamic>>? fees;
  final List<Map<String, dynamic>>? taxes;

  FlightPrice({
    required this.currency,
    required this.total,
    required this.base,
    this.fees,
    this.taxes,
  });

  factory FlightPrice.fromJson(Map<String, dynamic> json) {
    return FlightPrice(
      currency: json['currency'] ?? 'USD',
      total: double.tryParse(json['grandTotal']?.toString() ??
              json['total']?.toString() ??
              '0') ??
          0,
      base: double.tryParse(json['base']?.toString() ?? '0') ?? 0,
      fees: (json['fees'] as List<dynamic>?)
          ?.map((fee) => Map<String, dynamic>.from(fee as Map))
          .toList(),
      taxes: (json['taxes'] as List<dynamic>?)
          ?.map((tax) => Map<String, dynamic>.from(tax as Map))
          .toList(),
    );
  }
}

class TravelerPricing {
  final String travelerId;
  final String travelerType;
  final PriceDetails price;

  TravelerPricing({
    required this.travelerId,
    required this.travelerType,
    required this.price,
  });

  factory TravelerPricing.fromJson(Map<String, dynamic> json) {
    return TravelerPricing(
      travelerId: json['travelerId'] ?? '',
      travelerType: json['travelerType'] ?? 'ADULT',
      price: PriceDetails.fromJson(json['price'] ?? const {}),
    );
  }
}

class PriceDetails {
  final String currency;
  final double total;
  final double base;

  PriceDetails({
    required this.currency,
    required this.total,
    required this.base,
  });

  factory PriceDetails.fromJson(Map<String, dynamic> json) {
    return PriceDetails(
      currency: json['currency'] ?? 'USD',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      base: double.tryParse(json['base']?.toString() ?? '0') ?? 0,
    );
  }
}

DateTime? _tryParseDateTime(String? value) {
  if (value == null) return null;
  return DateTime.tryParse(value);
}

