// lib/providers/flight_providers.dart

import 'package:dio/dio.dart';
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
    debugPrint('🔍 latestFlightFromTripsProvider: Starting to fetch flights...');

    // Ambil semua trips
    final trips = await api.getTrips();
    debugPrint('🔍 latestFlightFromTripsProvider: Found ${trips.length} trips');

    if (trips.isEmpty) {
      debugPrint('⚠️ latestFlightFromTripsProvider: No trips found');
      return null;
    }

    // Ambil semua flight bookings dari semua trips
    final allFlights = <FlightBookingModel>[];
    int successCount = 0;
    int errorCount = 0;

    for (final trip in trips) {
      try {
        debugPrint(
          '🔍 latestFlightFromTripsProvider: Fetching flights for trip ${trip.tripId} (${trip.tripName})',
        );
        final flights = await api.getFlightBookings(
          tripId: trip.tripId,
          status: null, // Tidak filter status, ambil semua
          limit: 10,
        );
        debugPrint(
          '🔍 latestFlightFromTripsProvider: Found ${flights.length} flights for trip ${trip.tripId}',
        );
        if (flights.isNotEmpty) {
          debugPrint(
            '🔍 First flight: ${flights.first.airline} ${flights.first.flightNumber} (${flights.first.origin} → ${flights.first.destination})',
          );
          allFlights.addAll(flights);
          successCount++;
        }
      } catch (e) {
        errorCount++;
        debugPrint(
          '⚠️ latestFlightFromTripsProvider: Error fetching flights for trip ${trip.tripId}: $e',
        );
        // Skip jika error, lanjut ke trip berikutnya
        continue;
      }
    }

    debugPrint(
      '🔍 latestFlightFromTripsProvider: Total flights collected: ${allFlights.length} (Success: $successCount, Errors: $errorCount)',
    );

    if (allFlights.isEmpty) {
      debugPrint('⚠️ latestFlightFromTripsProvider: No flights found in any trip');
      return null;
    }

    // Filter flights yang memiliki departureDate atau createdAt yang valid
    // createdAt tidak bisa null karena required di model, jadi cukup cek departureDate
    final validFlights = allFlights.where((flight) {
      return flight.departureDate != null;
    }).toList();
    
    // Jika tidak ada yang punya departureDate, gunakan semua flights (sort by createdAt)
    final flightsToSort = validFlights.isNotEmpty ? validFlights : allFlights;

    if (flightsToSort.isEmpty) {
      debugPrint('⚠️ latestFlightFromTripsProvider: No valid flights with dates found');
      return null;
    }

    // Sort berdasarkan departureDate (terbaru dulu), jika null sort berdasarkan createdAt
    flightsToSort.sort((a, b) {
      final aDate = a.departureDate ?? a.createdAt;
      final bDate = b.departureDate ?? b.createdAt;
      // Sort descending (terbaru dulu)
      return bDate.compareTo(aDate);
    });

    // Return yang pertama (terbaru)
    final latestFlight = flightsToSort.first;
    debugPrint('✅ latestFlightFromTripsProvider: Latest flight selected:');
    debugPrint('   - Airline: ${latestFlight.airline}');
    debugPrint('   - Flight Number: ${latestFlight.flightNumber}');
    debugPrint('   - Route: ${latestFlight.origin} → ${latestFlight.destination}');
    debugPrint('   - Departure: ${latestFlight.departureDate}');
    debugPrint('   - Created: ${latestFlight.createdAt}');

    return latestFlight;
  } on DioException catch (e) {
    // Handle specific DioException
    if (e.response?.statusCode == 404) {
      debugPrint('⚠️ latestFlightFromTripsProvider: 404 - No trips or flights found');
      return null;
    }
    if (e.response?.statusCode == 401) {
      debugPrint('⚠️ latestFlightFromTripsProvider: 401 - User not authenticated');
      return null;
    }
    debugPrint('❌ latestFlightFromTripsProvider: DioException - ${e.message}');
    return null;
  } catch (e, stackTrace) {
    debugPrint('❌ latestFlightFromTripsProvider: Error - $e');
    debugPrint('❌ Stack trace: $stackTrace');
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
