// lib/providers/app_providers.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/booking_model.dart';
import '../models/destination_master_model.dart';
import '../models/trip_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

// ==================== API SERVICE PROVIDER ====================

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// ==================== LOCATION SERVICE & PROVIDERS ====================

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Mengambil posisi GPS user (lat, long)
final userLocationProvider = FutureProvider<Position>((ref) async {
  final service = ref.watch(locationServiceProvider);
  return service.getCurrentPosition();
});

/// Mengubah posisi GPS menjadi teks alamat yang ramah untuk ditampilkan
final userLocationTextProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(locationServiceProvider);
  final position = await ref.watch(userLocationProvider.future);
  return service.getReadableAddress(position);
});

// ==================== USER PROVIDER ====================
final userProvider = FutureProvider<UserModel>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    return await api.getUserProfile();
  } on DioException catch (e) {
    // Jika 401 (user tidak login), throw error yang bisa ditangani UI
    if (e.response?.statusCode == 401) {
      throw Exception(
        "User tidak terautentikasi. Silakan login terlebih dahulu.",
      );
    }
    rethrow;
  }
});

// ==================== TRIPS PROVIDER ====================
final tripsProvider = FutureProvider<List<TripModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getTrips();
});

final upcomingTripsProvider = Provider<AsyncValue<List<TripModel>>>((ref) {
  final tripsAsync = ref.watch(tripsProvider);

  return tripsAsync.when(
    data: (trips) {
      final upcoming = trips
          .where((trip) => trip.isUpcoming || trip.isOngoing)
          .toList();
      upcoming.sort((a, b) => a.startDate.compareTo(b.startDate));
      return AsyncValue.data(upcoming);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// ==================== DESTINATIONS PROVIDER ====================
final popularDestinationsProvider =
    FutureProvider<List<DestinationMasterModel>>((ref) async {
      final api = ref.watch(apiServiceProvider);
      return api.getPopularDestinations();
    });

// ==================== SEARCH PROVIDER ====================
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider untuk search results (destinations)
final destinationSearchProvider = FutureProvider<List<DestinationMasterModel>>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider);
  if (query.length < 3) {
    return [];
  }
  final api = ref.watch(apiServiceProvider);
  return api.searchDestinations(query);
});

// Provider untuk search results (locations/hotels by keyword)
final hotelLocationSearchProvider = FutureProvider<List<dynamic>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.length < 3) {
    return [];
  }
  final api = ref.watch(apiServiceProvider);
  return api.searchLocationsByKeyword(keyword: query, subType: "CITY,HOTEL");
});

// ==================== BOOKINGS PROVIDER ====================
final upcomingFlightsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final bookings = await api.getMyBookings(type: "flight");
  final now = DateTime.now();
  return bookings.where((booking) => booking.bookingDate.isAfter(now)).toList();
});

// ==================== WISHLIST PROVIDERS ====================
/// Mengecek apakah suatu destinasi sudah ada di wishlist user
final wishlistStatusProvider = FutureProvider.family<bool, String>((
  ref,
  destinationId,
) async {
  final api = ref.watch(apiServiceProvider);
  return api.checkWishlistStatus(destinationId);
});

// ==================== BOTTOM NAV INDEX PROVIDER ====================
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
