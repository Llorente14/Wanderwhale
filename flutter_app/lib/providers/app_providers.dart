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
import 'trip_providers.dart';

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
    // Jika 404 (profile belum dibuat), throw error yang jelas
    if (e.response?.statusCode == 404) {
      throw Exception("Profile belum dibuat. Silakan lengkapi profil Anda.");
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

// ==================== HOTELS FROM TRIPS PROVIDER ====================
/// Aggregates hotels from all user trips
final hotelsFromTripsProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final trips = await ref.watch(tripsProvider.future);
    final allHotels = <dynamic>[];

    // Create a list of futures to wait for all hotels
    final hotelFutures = <Future<List<dynamic>>>[];

    for (final trip in trips) {
      // Create a nested FutureProvider for each trip's hotels
      final future = _getHotelsForTrip(ref, trip.tripId);
      hotelFutures.add(future);
    }

    // Wait for all hotel futures to complete
    final results = await Future.wait(hotelFutures, eagerError: false);

    // Combine all results
    for (final result in results) {
      allHotels.addAll(result);
    }

    // If no hotels found, return demo data
    if (allHotels.isEmpty) {
      print('⚠️ No hotels found from trips, using demo data');
      return _getDemoHotels();
    }

    return allHotels;
  } catch (e) {
    print('❌ Error fetching hotels from trips: $e, using demo data');
    return _getDemoHotels();
  }
});

/// Demo hotel data for testing
List<dynamic> _getDemoHotels() {
  final now = DateTime.now();
  return [
    {
      'hotelId': 'DEMO_HOTEL_1',
      'tripId': 'DEMO_TRIP_1',
      'hotelName': 'Bali Grand Hotel',
      'address': 'Jl. Pantai Kuta No. 123',
      'city': 'Bali',
      'country': 'Indonesia',
      'checkInDate': now.add(const Duration(days: 7)).toIso8601String(),
      'checkOutDate': now.add(const Duration(days: 10)).toIso8601String(),
      'numberOfNights': 3,
      'totalPrice': 1500000.0,
      'currency': 'IDR',
      'rating': 4.5,
      'confirmationNumber': 'BKG123456',
      'bookingStatus': 'confirmed',
      'imageUrl':
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=500&h=300&fit=crop',
    },
    {
      'hotelId': 'DEMO_HOTEL_2',
      'tripId': 'DEMO_TRIP_1',
      'hotelName': 'Jakarta Luxury Residence',
      'address': 'Jl. Sudirman Km. 10',
      'city': 'Jakarta',
      'country': 'Indonesia',
      'checkInDate': now.add(const Duration(days: 14)).toIso8601String(),
      'checkOutDate': now.add(const Duration(days: 17)).toIso8601String(),
      'numberOfNights': 3,
      'totalPrice': 2500000.0,
      'currency': 'IDR',
      'rating': 4.8,
      'confirmationNumber': 'BKG789012',
      'bookingStatus': 'confirmed',
      'imageUrl':
          'https://www.remotelands.com/travelogues/app/uploads/2018/01/RCJAKAR_00070_conversion.jpg',
    },
    {
      'hotelId': 'DEMO_HOTEL_3',
      'tripId': 'DEMO_TRIP_2',
      'hotelName': 'Yogyakarta Heritage Hotel',
      'address': 'Jl. Malioboro 456',
      'city': 'Yogyakarta',
      'country': 'Indonesia',
      'checkInDate': now.add(const Duration(days: 21)).toIso8601String(),
      'checkOutDate': now.add(const Duration(days: 24)).toIso8601String(),
      'numberOfNights': 3,
      'totalPrice': 1200000.0,
      'currency': 'IDR',
      'rating': 4.3,
      'confirmationNumber': 'BKG345678',
      'bookingStatus': 'confirmed',
      'imageUrl':
          'https://images.unsplash.com/photo-1582719471384-894fbb16e074?w=500&h=300&fit=crop',
    },
    {
      'hotelId': 'DEMO_HOTEL_4',
      'tripId': 'DEMO_TRIP_2',
      'hotelName': 'Bandung Mountain View Resort',
      'address': 'Jl. Tangkuban Perahu',
      'city': 'Bandung',
      'country': 'Indonesia',
      'checkInDate': now.add(const Duration(days: 28)).toIso8601String(),
      'checkOutDate': now.add(const Duration(days: 31)).toIso8601String(),
      'numberOfNights': 3,
      'totalPrice': 1800000.0,
      'currency': 'IDR',
      'rating': 4.6,
      'confirmationNumber': 'BKG901234',
      'bookingStatus': 'confirmed',
      'imageUrl':
          'https://media-cdn.tripadvisor.com/media/photo-s/2a/d2/db/b3/caption.jpg',
    },
    {
      'hotelId': 'DEMO_HOTEL_5',
      'tripId': 'DEMO_TRIP_3',
      'hotelName': 'Surabaya Waterfront Hotel',
      'address': 'Jl. Tanjungsari 789',
      'city': 'Surabaya',
      'country': 'Indonesia',
      'checkInDate': now.add(const Duration(days: 35)).toIso8601String(),
      'checkOutDate': now.add(const Duration(days: 38)).toIso8601String(),
      'numberOfNights': 3,
      'totalPrice': 1350000.0,
      'currency': 'IDR',
      'rating': 4.4,
      'confirmationNumber': 'BKG567890',
      'bookingStatus': 'confirmed',
      'imageUrl':
          'https://cf.bstatic.com/xdata/images/hotel/max1024x768/500919855.jpg?k=6ee12069162489ed444285a8247f02a01963481194b2ba0eda5c71697779fb43&o=',
    },
  ];
}

/// Helper to fetch hotels for a specific trip
Future<List<dynamic>> _getHotelsForTrip(Ref ref, String tripId) async {
  try {
    final tripHotelsAsync = ref.watch(tripHotelsProvider(tripId));

    // Convert AsyncValue to Future
    return await tripHotelsAsync.when(
      data: (hotels) => Future.value(hotels.cast<dynamic>()),
      loading: () => Future.value([]),
      error: (err, stack) {
        print('⚠️ Error fetching hotels for trip $tripId: $err');
        return Future.value([]);
      },
    );
  } catch (e) {
    print('⚠️ Exception fetching hotels for trip $tripId: $e');
    return [];
  }
}

// ==================== BOTTOM NAV INDEX PROVIDER ====================
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
