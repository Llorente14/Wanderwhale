// lib/core/utils/constants.dart
import 'package:flutter/foundation.dart';
import 'package:wanderwhale/core/config/app_config.dart';

class ApiConstants {
  // Ganti ke "http://localhost:5000/api" jika pakai iOS Simulator
  // 10.0.2.2 adalah alamat IP khusus emulator Android untuk mengakses 'localhost'
  static String get baseUrl {
    // Jika build diset via --dart-define=API_BASE_URL, gunakan itu (compile-time)
    final env = const String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) {
      return env.endsWith('/api') ? env : env + '/api';
    }

    // Untuk web/dev lokal tetap gunakan localhost
    if (kIsWeb) {
      return "http://localhost:5000/api";
    }

    // Untuk release builds gunakan AppConfig (production) base URL
    if (kReleaseMode) {
      return AppConfig.apiBaseUrl.endsWith('/api')
          ? AppConfig.apiBaseUrl
          : AppConfig.apiBaseUrl + '/api';
    }

    // Untuk pengembangan Android emulator gunakan 10.0.2.2
    if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:5000/api";
    }

    // Default (mis. iOS simulator)
    return "http://localhost:5000/api"; // Untuk iOS
  }

  // Naikkan durasi jadi 60 detik (1 menit) biar aman
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // === AUTH ===
  // (Login/Register ditangani oleh Firebase Auth, bukan API kita)
  // Ini adalah endpoint untuk membuat/mengambil data profil KITA
  static const String userProfile = "/users/profile"; // POST, GET, PUT
  static const String userAccount = "/users/account"; // DELETE
  static const String userFcmToken = "/users/fcm-token"; // PUT

  // Note: OAuth backend endpoint removed from client config

  // === TRIPS (Internal Database) ===
  static const String trips = "/trips"; // GET, POST
  static String tripDetail(String id) => "/trips/$id"; // GET, PUT, DELETE
  static String tripStatus(String id) => "/trips/$id/status"; // PATCH
  static String tripDestinations(String id) => "/trips/$id/destinations";
  static String tripDestinationDetail(String tripId, String destId) =>
      "/trips/$tripId/destinations/$destId";
  static String tripHotels(String id) => "/trips/$id/hotels";
  static String tripHotelDetail(String tripId, String hotelId) =>
      "/trips/$tripId/hotels/$hotelId";

  // === DESTINATIONS (Publik / 'Ensiklopedia') ===
  static const String popularDestinations = "/destinations/popular"; // GET
  static const String searchDestinations =
      "/destinations/search"; // GET ?query=
  static String destinationDetail(String id) => "/destinations/$id"; // GET

  // === HOTEL SEARCH (Amadeus Step 1 & 2) ===
  static const String searchHotelsByCity = "/hotels/search/by-city";
  static const String searchHotelsByGeocode = "/hotels/search/by-geocode";
  static const String searchHotelsByIds = "/hotels/search/by-hotels";
  static const String searchLocations = "/hotels/search/locations";
  static const String hotelOffers = "/hotels/offers"; // GET (Cari Harga)
  static String hotelOfferDetail(String id) =>
      "/hotels/offers/$id"; // GET (Konfirmasi)

  // === FLIGHT SEARCH (Amadeus Step 1 & 2) ===
  static const String searchFlightLocations = "/flights/search/locations";
  static const String searchFlightOffers = "/flights/search"; // POST
  static const String flightSeatmaps = "/flights/seatmaps"; // POST

  // === BOOKING (Dummy Step 3) ===
  static const String hotelBookings = "/bookings/hotels"; // POST
  static const String flightBookings = "/flights/bookings"; // POST
  static const String myBookings = "/bookings"; // GET
  static const String hotelBookingsList = "/hotels/bookings"; // GET
  static const String flightBookingsList = "/flights/bookings"; // GET

  // === WISHLIST ===
  static const String wishlist = "/wishlist"; // GET, POST
  static String wishlistDetail(String id) => "/wishlist/$id"; // DELETE
  static const String wishlistToggle = "/wishlist/toggle"; // POST
  static String wishlistCheck(String id) => "/wishlist/check/$id"; // GET

  // === NOTIFICATIONS ===
  static const String notifications = "/notifications"; // GET
  static String notificationMarkRead(String id) =>
      "/notifications/$id/read"; // PATCH
  static const String notificationMarkAllRead =
      "/notifications/read-all"; // PATCH
  static String notificationDelete(String id) => "/notifications/$id"; // DELETE
}

// StorageKeys TIDAK DIPERLUKAN
// Karena FirebaseAuth menyimpan token-nya sendiri secara aman.
// class StorageKeys { ... }

// AppStrings Anda sudah bagus
class AppStrings {
  static const String appName = 'WanderWhale'; // Ganti ke WanderWhale
  static const String welcomeBack = 'Welcome Back';
  static const String upcomingTrips = 'Upcoming Trips';
  static const String upcomingFlight = 'Upcoming Flight';
  static const String searchPlaceholder = 'Where do you want to go?';
  static const String details = 'Details';
  static const String when = 'When';
}
