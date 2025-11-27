// lib/providers/flight_providers.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/flight_booking_model.dart';
import '../models/flight_offer_model.dart';
import '../services/api_service.dart';
import 'app_providers.dart';

final flightOffersProvider = FutureProvider.family
    .autoDispose<List<FlightOfferModel>, FlightSearchParams>((ref, params) {
  final api = ref.watch(apiServiceProvider);
  return api.searchFlightOffers(params.body);
});

final flightBookingControllerProvider =
    Provider<FlightBookingController>((ref) {
  final api = ref.watch(apiServiceProvider);
  return FlightBookingController(api);
});

final flightBookingsProvider = FutureProvider.family
    .autoDispose<List<FlightBookingModel>, FlightBookingFilter>((ref, filter) {
  final api = ref.watch(apiServiceProvider);
  return api.getFlightBookings(
    tripId: filter.tripId,
    status: filter.status,
    page: filter.page,
    limit: filter.limit,
  );
});

class FlightBookingController {
  FlightBookingController(this._api);

  final ApiService _api;

  Future<FlightBookingModel> bookFlight(Map<String, dynamic> payload) {
    return _api.storeFlightBooking(payload);
  }
}

@immutable
class FlightSearchParams {
  const FlightSearchParams(this.body);

  final Map<String, dynamic> body;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FlightSearchParams) return false;
    if (body.length != other.body.length) return false;
    for (final key in body.keys) {
      if (!other.body.containsKey(key) || other.body[key] != body[key]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(
        body.entries.map((entry) => Object.hash(entry.key, entry.value)),
      );
}

@immutable
class FlightBookingFilter {
  const FlightBookingFilter({
    this.tripId,
    this.status,
    this.page,
    this.limit,
  });

  final String? tripId;
  final String? status;
  final int? page;
  final int? limit;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlightBookingFilter &&
        other.tripId == tripId &&
        other.status == status &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(tripId, status, page, limit);
}

