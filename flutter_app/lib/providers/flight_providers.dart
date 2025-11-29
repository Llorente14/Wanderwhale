// lib/providers/flight_providers.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/flight_booking_model.dart';
import '../models/flight_offer_model.dart';
import '../screens/flight/flight_data.dart'; // For demo data
import '../services/api_service.dart';
import 'app_providers.dart';

final flightOffersProvider = FutureProvider.family
    .autoDispose<List<FlightOfferModel>, FlightSearchParams>((ref, params) async {
  final api = ref.watch(apiServiceProvider);
  
  try {
    // Try API first
    final offers = await api.searchFlightOffers(params.body);
    
    // If API returns empty, fallback to demo data
    if (offers.isEmpty) {
      print('⚠️ API returned empty results, using demo flight data');
      return _getDemoFlightOffers();
    }
    
    print('✅ Loaded ${offers.length} flights from API');
    return offers;
  } catch (e) {
    // If API fails, fallback to demo data
    print('⚠️ API error: $e, using demo flight data');
    return _getDemoFlightOffers();
  }
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

// Helper function to get demo flight offers
List<FlightOfferModel> _getDemoFlightOffers() {
  return demoFlightOffers;
}

// Provider for searching locations (airports/cities)
final locationSearchProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.length < 3) return [];
  
  final api = ref.watch(apiServiceProvider);
  try {
    // subType: AIRPORT or CITY. We search for both.
    final results = await api.searchLocationsByKeyword(keyword: query, subType: 'AIRPORT,CITY');
    return results.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (e) {
    print('Location search error: $e');
    return [];
  }
});

