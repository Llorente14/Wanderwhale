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

final flightBookingControllerProvider = Provider<FlightBookingController>((
  ref,
) {
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

// Provider untuk mendapatkan flight terbaru dari semua trips
final latestFlightFromTripsProvider = FutureProvider.autoDispose<FlightBookingModel?>((
  ref,
) async {
  final api = ref.watch(apiServiceProvider);

  try {
    print('🔍 latestFlightFromTripsProvider: Starting to fetch flights...');

    // Ambil semua trips
    final trips = await api.getTrips();
    print('🔍 latestFlightFromTripsProvider: Found ${trips.length} trips');

    if (trips.isEmpty) {
      print('⚠️ latestFlightFromTripsProvider: No trips found');
      return null;
    }

    // Ambil semua flight bookings dari semua trips
    final allFlights = <FlightBookingModel>[];
    for (final trip in trips) {
      try {
        print(
          '🔍 latestFlightFromTripsProvider: Fetching flights for trip ${trip.tripId} (${trip.tripName})',
        );
        final flights = await api.getFlightBookings(
          tripId: trip.tripId,
          status: null, // Tidak filter status, ambil semua
          limit: 10,
        );
        print(
          '🔍 latestFlightFromTripsProvider: Found ${flights.length} flights for trip ${trip.tripId}',
        );
        if (flights.isNotEmpty) {
          print(
            '🔍 First flight: ${flights.first.airline} ${flights.first.flightNumber} (${flights.first.origin} → ${flights.first.destination})',
          );
        }
        allFlights.addAll(flights);
      } catch (e) {
        print(
          '❌ latestFlightFromTripsProvider: Error fetching flights for trip ${trip.tripId}: $e',
        );
        // Skip jika error, lanjut ke trip berikutnya
        continue;
      }
    }

    print(
      '🔍 latestFlightFromTripsProvider: Total flights collected: ${allFlights.length}',
    );

    if (allFlights.isEmpty) {
      print('⚠️ latestFlightFromTripsProvider: No flights found in any trip');
      return null;
    }

    // Sort berdasarkan departureDate (terbaru dulu), jika null sort berdasarkan createdAt
    allFlights.sort((a, b) {
      final aDate = a.departureDate ?? a.createdAt;
      final bDate = b.departureDate ?? b.createdAt;
      return bDate.compareTo(aDate);
    });

    // Return yang pertama (terbaru)
    final latestFlight = allFlights.first;
    print('✅ latestFlightFromTripsProvider: Latest flight selected:');
    print('   - Airline: ${latestFlight.airline}');
    print('   - Flight Number: ${latestFlight.flightNumber}');
    print('   - Route: ${latestFlight.origin} → ${latestFlight.destination}');
    print('   - Departure: ${latestFlight.departureDate}');
    print('   - Created: ${latestFlight.createdAt}');

    return latestFlight;
  } catch (e) {
    print('❌ latestFlightFromTripsProvider: Error - $e');
    return null;
  }
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
  const FlightBookingFilter({this.tripId, this.status, this.page, this.limit});

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
