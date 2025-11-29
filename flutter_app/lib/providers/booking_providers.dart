// lib/providers/booking_providers.dart
//
// Riverpod state management for flight & hotel booking flows.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/flight_offer_model.dart';
import '../models/hotel_offer_model.dart';

// ---------------------------------------------------------------------------
// Flight booking state
// ---------------------------------------------------------------------------

@immutable
class FlightPassengerForm {
  const FlightPassengerForm({
    this.type = 'ADULT',
    this.firstName = '',
    this.lastName = '',
    this.dateOfBirth,
    this.email = '',
    this.phone = '',
    this.gender,
    this.nationality,
    this.documentType,
    this.documentNumber,
  });

  final String type;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String email;
  final String phone;
  final String? gender;
  final String? nationality;
  final String? documentType;
  final String? documentNumber;

  bool get isComplete =>
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      dateOfBirth != null &&
      email.isNotEmpty;

  FlightPassengerForm copyWith({
    String? type,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? email,
    String? phone,
    String? gender,
    String? nationality,
    String? documentType,
    String? documentNumber,
  }) {
    return FlightPassengerForm(
      type: type ?? this.type,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      nationality: nationality ?? this.nationality,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'type': type,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': _formatDate(dateOfBirth),
      'email': email,
      if (phone.isNotEmpty) 'phone': phone,
      if (gender?.isNotEmpty ?? false) 'gender': gender,
      if (nationality?.isNotEmpty ?? false) 'nationality': nationality,
      if (documentType?.isNotEmpty ?? false) 'documentType': documentType,
      if (documentNumber?.isNotEmpty ?? false) 'documentNumber': documentNumber,
    };
  }
}

@immutable
class FlightBookingState {
  const FlightBookingState({
    this.offer,
    this.tripId,
    this.passengers = const [],
    this.selectedSeats = const [],
    this.seatPrice = 150000,
    this.departureDate,
  });

  final FlightOfferModel? offer;
  final String? tripId;
  final List<FlightPassengerForm> passengers;
  final List<String> selectedSeats;
  final double seatPrice;
  final DateTime? departureDate;

  double get _basePassengerFare {
    if (offer == null) return 0;
    final travelerCount = offer!.travelerPricings.isNotEmpty
        ? offer!.travelerPricings.length
        : 1;
    return offer!.price.total / travelerCount;
  }

  int get passengerCount {
    if (passengers.isNotEmpty) {
      return passengers.length;
    }
    if (offer == null) return 0;
    return offer!.travelerPricings.isNotEmpty
        ? offer!.travelerPricings.length
        : 1;
  }

  double get passengerUnitPrice => _basePassengerFare;

  double get seatsTotalPrice => selectedSeats.length * seatPrice;

  double get totalPrice {
    if (offer == null) return 0;
    return (_basePassengerFare * passengerCount) + seatsTotalPrice;
  }

  bool get isReadyForCheckout =>
      offer != null &&
      passengers.isNotEmpty &&
      passengers.every((p) => p.isComplete);

  Map<String, dynamic>? buildPayload() {
    if (!isReadyForCheckout || offer == null) return null;
    return {
      if (tripId != null && tripId!.isNotEmpty) 'tripId': tripId,
      'flightOffer': _serializeFlightOffer(offer!),
      'passengers': passengers.map((p) => p.toPayload()).toList(),
      'selectedSeats': selectedSeats,
    };
  }

  FlightBookingState copyWith({
    FlightOfferModel? offer,
    String? tripId,
    List<FlightPassengerForm>? passengers,
    List<String>? selectedSeats,
    double? seatPrice,
    DateTime? departureDate,
  }) {
    return FlightBookingState(
      offer: offer ?? this.offer,
      tripId: tripId ?? this.tripId,
      passengers: passengers ?? this.passengers,
      selectedSeats: selectedSeats ?? this.selectedSeats,
      seatPrice: seatPrice ?? this.seatPrice,
      departureDate: departureDate ?? this.departureDate,
    );
  }
}

class FlightBookingNotifier extends StateNotifier<FlightBookingState> {
  FlightBookingNotifier() : super(const FlightBookingState());

  void setOffer(FlightOfferModel offer) {
    state = state.copyWith(offer: offer);
  }

  void setTrip(String? tripId) {
    state = state.copyWith(tripId: tripId);
  }

  void setPassengers(List<FlightPassengerForm> passengers) {
    state = state.copyWith(passengers: List.unmodifiable(passengers));
  }

  void updatePassenger(int index, FlightPassengerForm passenger) {
    if (index < 0 || index >= state.passengers.length) return;
    final next = [...state.passengers]..[index] = passenger;
    setPassengers(next);
  }

  void addPassenger([FlightPassengerForm? passenger]) {
    final next = [...state.passengers, passenger ?? const FlightPassengerForm()];
    setPassengers(next);
  }

  void removePassenger(int index) {
    if (index < 0 || index >= state.passengers.length) return;
    final next = [...state.passengers]..removeAt(index);
    setPassengers(next);
  }

  void toggleSeat(String seatId) {
    final current = [...state.selectedSeats];
    if (current.contains(seatId)) {
      current.remove(seatId);
    } else {
      current.add(seatId);
    }
    state = state.copyWith(selectedSeats: List.unmodifiable(current));
  }

  void setSeats(List<String> seats) {
    state = state.copyWith(selectedSeats: List.unmodifiable(seats));
  }

  void setDepartureDate(DateTime? date) {
    state = state.copyWith(departureDate: date);
  }

  void reset() {
    state = const FlightBookingState();
  }
}

final flightBookingProvider =
    StateNotifierProvider<FlightBookingNotifier, FlightBookingState>(
  (ref) => FlightBookingNotifier(),
);

// ---------------------------------------------------------------------------
// Hotel booking state
// ---------------------------------------------------------------------------

@immutable
class HotelGuestForm {
  const HotelGuestForm({
    this.title = 'MR',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
  });

  final String title;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  bool get isComplete =>
      firstName.isNotEmpty && lastName.isNotEmpty && email.isNotEmpty;

  HotelGuestForm copyWith({
    String? title,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) {
    return HotelGuestForm(
      title: title ?? this.title,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'name': {
        'title': title,
        'firstName': firstName,
        'lastName': lastName,
      },
      'contact': {
        'email': email,
        'phone': phone,
      },
    };
  }
}

@immutable
class HotelBookingState {
  const HotelBookingState({
    this.offer,
    this.hotel,
    this.tripId,
    this.checkInDate,
    this.checkOutDate,
    this.guests = const [],
    this.imageUrl,
  });

  final HotelOffer? offer;
  final HotelSummary? hotel;
  final String? tripId;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final List<HotelGuestForm> guests;
  final String? imageUrl; // URL gambar hotel

  double get totalPrice => offer?.price.total ?? 0;
  double get basePrice => offer?.price.base ?? 0;
  double get taxes => totalPrice - basePrice;

  bool get isReadyForCheckout =>
      offer != null &&
      hotel != null &&
      guests.isNotEmpty &&
      guests.every((g) => g.isComplete);

  Map<String, dynamic>? buildPayload() {
    if (!isReadyForCheckout || offer == null) return null;
    return {
      'offerId': offer!.id,
      if (tripId != null && tripId!.isNotEmpty) 'tripId': tripId,
      'guests': guests.map((g) => g.toPayload()).toList(),
      'checkInDate': _formatDate(checkInDate ?? offer!.checkInDate),
      'checkOutDate': _formatDate(checkOutDate ?? offer!.checkOutDate),
    };
  }

  HotelBookingState copyWith({
    HotelOffer? offer,
    HotelSummary? hotel,
    String? tripId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    List<HotelGuestForm>? guests,
    String? imageUrl,
  }) {
    return HotelBookingState(
      offer: offer ?? this.offer,
      hotel: hotel ?? this.hotel,
      tripId: tripId ?? this.tripId,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      guests: guests ?? this.guests,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class HotelBookingNotifier extends StateNotifier<HotelBookingState> {
  HotelBookingNotifier() : super(const HotelBookingState());

  void setContext({
    HotelOffer? offer,
    HotelSummary? hotel,
    String? imageUrl,
  }) {
    state = state.copyWith(
      offer: offer ?? state.offer,
      hotel: hotel ?? state.hotel,
      checkInDate: offer?.checkInDate ?? state.checkInDate,
      checkOutDate: offer?.checkOutDate ?? state.checkOutDate,
      imageUrl: imageUrl ?? state.imageUrl,
    );
  }

  void setTrip(String? tripId) {
    state = state.copyWith(tripId: tripId);
  }

  void setDates({DateTime? checkIn, DateTime? checkOut}) {
    state = state.copyWith(
      checkInDate: checkIn ?? state.checkInDate,
      checkOutDate: checkOut ?? state.checkOutDate,
    );
  }

  void setGuests(List<HotelGuestForm> guests) {
    state = state.copyWith(guests: List.unmodifiable(guests));
  }

  void updateGuest(int index, HotelGuestForm guest) {
    if (index < 0 || index >= state.guests.length) return;
    final next = [...state.guests]..[index] = guest;
    setGuests(next);
  }

  void addGuest([HotelGuestForm? guest]) {
    final next = [...state.guests, guest ?? const HotelGuestForm()];
    setGuests(next);
  }

  void removeGuest(int index) {
    if (index < 0 || index >= state.guests.length) return;
    final next = [...state.guests]..removeAt(index);
    setGuests(next);
  }

  void reset() {
    state = const HotelBookingState();
  }
}

final hotelBookingProvider =
    StateNotifierProvider<HotelBookingNotifier, HotelBookingState>(
  (ref) => HotelBookingNotifier(),
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String? _formatDate(DateTime? date) {

  if (date == null) return null;
  return date.toIso8601String().split('T').first;
}

Map<String, dynamic> _serializeFlightOffer(FlightOfferModel offer) {
  return {
    'id': offer.id,
    'source': offer.source,
    'itineraries': offer.itineraries
        .map((itinerary) => {
              'segments': itinerary.segments
                  .map(
                    (segment) => {
                      'carrierCode': segment.carrierCode,
                      'number': segment.number,
                      'departure': {
                        'iataCode': segment.departure.iataCode,
                        'at': _formatDateTime(segment.departure.at),
                        'terminal': segment.departure.terminal?.code,
                      },
                      'arrival': {
                        'iataCode': segment.arrival.iataCode,
                        'at': _formatDateTime(segment.arrival.at),
                        'terminal': segment.arrival.terminal?.code,
                      },
                      if (segment.aircraft != null)
                        'aircraft': {'code': segment.aircraft},
                      if (segment.duration != null) 'duration': segment.duration,
                      if (segment.operating != null)
                        'operating': {
                          'carrierCode': segment.operating!.carrierCode,
                        },
                      if (segment.pricing != null)
                        'pricingDetailPerAdult': {
                          'travelClass': segment.pricing!.travelClass,
                          'fareBasis': segment.pricing!.fareBasis,
                          'brandedFare': segment.pricing!.brandedFare,
                          'isRefundable': segment.pricing!.isRefundable,
                          'isChangeAllowed': segment.pricing!.isChangeAllowed,
                        },
                    },
                  )
                  .toList(),
            })
        .toList(),
    'price': {
      'currency': offer.price.currency,
      'total': offer.price.total,
      'base': offer.price.base,
      if (offer.price.fees != null) 'fees': offer.price.fees,
      if (offer.price.taxes != null) 'taxes': offer.price.taxes,
    },
    'validatingAirlineCodes': offer.validatingAirlineCodes,
    'travelerPricings': offer.travelerPricings
        .map(
          (pricing) => {
            'travelerId': pricing.travelerId,
            'travelerType': pricing.travelerType,
            'price': {
              'currency': pricing.price.currency,
              'total': pricing.price.total,
              'base': pricing.price.base,
            },
          },
        )
        .toList(),
  };
}

String? _formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return null;
  return dateTime.toIso8601String();
}

