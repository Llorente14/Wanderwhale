// lib/models/search_params.dart

/// Parameter untuk flight search
class FlightSearchParams {
  final String origin;
  final String destination;
  final String departureDate;
  final String? returnDate; // Optional untuk return flight
  final int adults;
  final int children;
  final String travelClass; // ECONOMY, BUSINESS, FIRST

  FlightSearchParams({
    required this.origin,
    required this.destination,
    required this.departureDate,
    this.returnDate,
    this.adults = 1,
    this.children = 0,
    this.travelClass = 'ECONOMY',
  });

  // Untuk debugging
  @override
  String toString() =>
      'FlightSearch($origin→$destination, $departureDate, adults:$adults)';

  // Untuk comparison di provider (autoDispose.family needs this)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlightSearchParams &&
          runtimeType == other.runtimeType &&
          origin == other.origin &&
          destination == other.destination &&
          departureDate == other.departureDate &&
          returnDate == other.returnDate &&
          adults == other.adults &&
          children == other.children &&
          travelClass == other.travelClass;

  @override
  int get hashCode =>
      origin.hashCode ^
      destination.hashCode ^
      departureDate.hashCode ^
      (returnDate?.hashCode ?? 0) ^
      adults.hashCode ^
      children.hashCode ^
      travelClass.hashCode;
}

/// Parameter untuk hotel search
class HotelSearchParams {
  final List<String> hotelIds;
  final String checkInDate;
  final String checkOutDate;
  final int adults;
  final int roomQuantity;

  HotelSearchParams({
    required this.hotelIds,
    required this.checkInDate,
    required this.checkOutDate,
    this.adults = 2,
    this.roomQuantity = 1,
  });

  @override
  String toString() =>
      'HotelSearch(${hotelIds.length} hotels, $checkInDate→$checkOutDate)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HotelSearchParams &&
          runtimeType == other.runtimeType &&
          hotelIds.toString() == other.hotelIds.toString() &&
          checkInDate == other.checkInDate &&
          checkOutDate == other.checkOutDate &&
          adults == other.adults &&
          roomQuantity == other.roomQuantity;

  @override
  int get hashCode =>
      hotelIds.hashCode ^
      checkInDate.hashCode ^
      checkOutDate.hashCode ^
      adults.hashCode ^
      roomQuantity.hashCode;
}
