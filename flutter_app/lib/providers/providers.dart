// lib/providers/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/trip_model.dart';
import '../models/booking_model.dart';
// --- PERBAIKAN 1 ---
// Nama model yang benar dari file kita adalah 'DestinationMasterModel'
import '../models/destination_master_model.dart';

// ==================== API SERVICE PROVIDER ====================

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// ==================== USER PROVIDER ====================
// (Provider ini sudah benar)
final userProvider = FutureProvider<UserModel>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return await api.getUserProfile();
});

// ==================== TRIPS PROVIDER ====================
// (Provider ini sudah benar)
final tripsProvider = FutureProvider<List<TripModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return await api.getTrips();
});

// (Provider ini sudah benar)
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

// --- PERBAIKAN 2 ---
// Mengganti 'DestinationModel' dengan 'DestinationMasterModel'
final popularDestinationsProvider =
    FutureProvider<List<DestinationMasterModel>>((ref) async {
      final api = ref.watch(apiServiceProvider);
      return await api.getPopularDestinations();
    });

// ==================== SEARCH PROVIDER ====================

// (Provider ini sudah benar)
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider untuk search results (destinations)
// --- PERBAIKAN 3 ---
// Mengganti 'DestinationModel' dengan 'DestinationMasterModel'
final destinationSearchProvider = FutureProvider<List<DestinationMasterModel>>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider);

  // Penyesuaian: Jangan panggil API jika query terlalu pendek
  if (query.length < 3) {
    return [];
  }

  final api = ref.watch(apiServiceProvider);
  return await api.searchDestinations(query);
});

// Provider untuk search results (locations/hotels by keyword)
// (Provider ini sudah benar)
final hotelLocationSearchProvider = FutureProvider<List<dynamic>>((ref) async {
  final query = ref.watch(searchQueryProvider);

  // Penyesuaian: Jangan panggil API jika query terlalu pendek
  if (query.length < 3) {
    return [];
  }

  final api = ref.watch(apiServiceProvider);
  // Penyesuaian: Lebih baik spesifik kita mencari apa,
  // Sesuai API Amadeus, 'CITY,HOTEL' adalah subType yang valid
  return await api.searchLocationsByKeyword(
    keyword: query,
    subType: "CITY,HOTEL",
  );
});

// ==================== BOOKINGS PROVIDER ====================

// --- 2. TAMBAHKAN PROVIDER INI ---
final upcomingFlightsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  // Ambil booking tipe 'flight'
  final bookings = await api.getMyBookings(type: "flight");

  // Filter hanya untuk yang akan datang
  final now = DateTime.now();
  // Asumsi 'bookingDate' adalah tanggal penerbangan (ganti jika Anda punya 'departureDate')
  return bookings.where((booking) => booking.bookingDate.isAfter(now)).toList();
});

// ==================== BOTTOM NAV INDEX PROVIDER ====================

// (Provider ini sudah benar)
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
