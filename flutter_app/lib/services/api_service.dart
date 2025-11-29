// lib/services/api_service.dart

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/booking_model.dart';
import 'package:flutter_app/models/destination_master_model.dart';
import 'package:flutter_app/models/flight_booking_model.dart';
import 'package:flutter_app/models/flight_offer_model.dart';
import 'package:flutter_app/models/hotel_booking_model.dart';
import 'package:flutter_app/models/hotel_offer_model.dart';
import 'package:flutter_app/models/notification_model.dart';
import 'package:flutter_app/models/trip_destination_model.dart';
import 'package:flutter_app/models/trip_hotel_model.dart';
import 'package:flutter_app/models/trip_model.dart';
import 'package:flutter_app/models/user_model.dart';
import 'package:flutter_app/models/wishlist_model.dart';
import 'package:flutter_app/utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  void Function()? _onUnauthorized;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Interceptor untuk menambahkan token Firebase Auth
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. Dapatkan user yang sedang login
          final user = _auth.currentUser;

          if (user != null) {
            // 2. Minta ID token (ini akan otomatis refresh jika kedaluwarsa)
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle 401 Unauthorized (misal: token dicabut)
          if (error.response?.statusCode == 401) {
            // Panggil callback jika terdaftar (AuthProvider akan mendaftarkan)
            try {
              _onUnauthorized?.call();
            } catch (e) {
              // ignore errors from callback
            }
            print("Token tidak valid. Harap login ulang.");
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Register callback yang dipanggil saat API mengembalikan 401 Unauthorized
  void setOnUnauthorizedCallback(void Function()? callback) {
    _onUnauthorized = callback;
  }

  // === Helper untuk parsing respons ===
  // Semua respons API kita dibungkus dalam { success: ..., data: ... }
  // Fungsi ini mengekstrak 'data'
  T _parseResponse<T>(Response response, T Function(dynamic json) fromJson) {
    if (response.data != null && response.data['data'] != null) {
      return fromJson(response.data['data']);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      message: "Respon 'data' tidak ditemukan atau null.",
    );
  }

  List<T> _parseResponseList<T>(
    Response response,
    T Function(dynamic json) fromJson,
  ) {
    if (response.data != null && response.data['data'] is List) {
      return (response.data['data'] as List)
          .map((json) => fromJson(json))
          .toList();
    }
    // Handle jika 'data' kosong (misal: '[]' dari controller)
    if (response.data['data'] == null ||
        (response.data['data'] is List && response.data['data'].isEmpty)) {
      return [];
    }
    throw DioException(
      requestOptions: response.requestOptions,
      message: "Respon 'data' bukan List.",
    );
  }

  // === FLIGHTS ===
  Future<List<FlightOfferModel>> searchFlights({
    required String origin,
    required String destination,
    required DateTime date,
    int travelers = 1,
  }) async {
    final payload = {
      "originDestinations": [
        {
          "id": "1",
          "originLocationCode": origin,
          "destinationLocationCode": destination,
          "departureDateTimeRange": {
            "date": DateFormat('yyyy-MM-dd').format(date),
          }
        }
      ],
      "travelers": List.generate(travelers, (index) => {
        "id": "${index + 1}",
        "travelerType": "ADULT"
      }),
      "sources": ["GDS"],
      "searchCriteria": {
        "maxFlightOffers": 50
      }
    };

    try {
      final response = await _dio.post(ApiConstants.searchFlightOffers, data: payload);
      return _parseResponseList(response, (json) => FlightOfferModel.fromJson(json));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchCity(String keyword) async {
    try {
      final response = await _dio.get(
        '/flights/search/city',
        queryParameters: {'keyword': keyword},
      );
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      print("Error searching city: $e");
      return [];
    }
  }

  // ==================== AUTH / USER ====================

  // (Login/Register ditangani oleh FirebaseAuth.instance)

  /// Dipanggil setelah registrasi Firebase berhasil
  Future<UserModel> createProfileAfterRegister(
    String displayName,
    String? photoURL,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.userProfile,
        data: {'displayName': displayName, 'photoURL': photoURL},
      );
      return _parseResponse(response, (json) => UserModel.fromJson(json));
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> getUserProfile() async {
    try {
      final response = await _dio.get(ApiConstants.userProfile);
      return _parseResponse(response, (json) => UserModel.fromJson(json));
    } catch (e) {
      rethrow;
    }
  }

  /// Update /users/fcm-token (PUT) - menyimpan FCM token device
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _dio.put(ApiConstants.userFcmToken, data: {'fcmToken': fcmToken});
    } catch (e) {
      rethrow;
    }
  }

  // ==================== TRIPS (Internal) ====================

  Future<List<TripModel>> getTrips() async {
    try {
      // Jika user belum login, jangan panggil API supaya tidak error 401.
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final response = await _dio.get(ApiConstants.trips);
      // 'data' dari backend kita adalah { success, message, data, count }
      // Kita perlu mem-parsing 'data' di dalamnya
      return _parseResponseList(response, (json) => TripModel.fromJson(json));
    } catch (e) {
      rethrow;
    }
  }

  Future<TripModel> getTripDetail(String tripId) async {
    try {
      final response = await _dio.get(ApiConstants.tripDetail(tripId));
      return _parseResponse(response, (json) => TripModel.fromJson(json));
    } catch (e) {
      rethrow;
    }
  }

  Future<TripModel> createTrip(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(ApiConstants.trips, data: payload);
      return _parseResponse(response, (json) => TripModel.fromJson(json));
    } catch (e) {
      rethrow;
    }
  }

  Future<TripModel> updateTrip(
    String tripId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put(
        ApiConstants.tripDetail(tripId),
        data: payload,
      );
      return _parseResponse(response, (json) => TripModel.fromJson(json));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      await _dio.delete(ApiConstants.tripDetail(tripId));
    } catch (e) {
      rethrow;
    }
  }

  Future<TripModel> updateTripStatus(String tripId, String status) async {
    try {
      final response = await _dio.patch(
        ApiConstants.tripStatus(tripId),
        data: {'status': status},
      );
      return _parseResponse(response, (json) => TripModel.fromJson(json));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TripDestinationModel>> getTripDestinations(
    String tripId, {
    String? sortBy,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.tripDestinations(tripId),
        queryParameters: {if (sortBy != null) 'sortBy': sortBy},
      );
      return _parseResponseList(
        response,
        (json) => TripDestinationModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<TripDestinationModel> createTripDestination(
    String tripId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.tripDestinations(tripId),
        data: payload,
      );
      return _parseResponse(
        response,
        (json) => TripDestinationModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<TripDestinationModel> updateTripDestination(
    String tripId,
    String destinationId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put(
        ApiConstants.tripDestinationDetail(tripId, destinationId),
        data: payload,
      );
      return _parseResponse(
        response,
        (json) => TripDestinationModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTripDestination(
    String tripId,
    String destinationId,
  ) async {
    try {
      await _dio.delete(
        ApiConstants.tripDestinationDetail(tripId, destinationId),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TripHotelModel>> getTripHotels(
    String tripId, {
    String? sortBy,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.tripHotels(tripId),
        queryParameters: {if (sortBy != null) 'sortBy': sortBy},
      );
      return _parseResponseList(
        response,
        (json) => TripHotelModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<TripHotelModel> createTripHotel(
    String tripId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.tripHotels(tripId),
        data: payload,
      );
      return _parseResponse(response, (json) => TripHotelModel.fromJson(json));
    } catch (e) {
      rethrow;
    }
  }

  Future<TripHotelModel> updateTripHotel(
    String tripId,
    String hotelId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.put(
        ApiConstants.tripHotelDetail(tripId, hotelId),
        data: payload,
      );
      return _parseResponse(response, (json) => TripHotelModel.fromJson(json));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTripHotel(String tripId, String hotelId) async {
    try {
      await _dio.delete(ApiConstants.tripHotelDetail(tripId, hotelId));
    } catch (e) {
      rethrow;
    }
  }

  // ==================== DESTINATIONS (Publik) ====================

  Future<List<DestinationMasterModel>> getPopularDestinations() async {
    try {
      final response = await _dio.get(ApiConstants.popularDestinations);
      // Menggunakan DestinationMasterModel
      return _parseResponseList(
        response,
        (json) => DestinationMasterModel.fromJson(json['id'] ?? '', json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DestinationMasterModel>> searchDestinations(String query) async {
    try {
      final response = await _dio.get(
        ApiConstants.searchDestinations,
        queryParameters: {'query': query},
      );
      // Menggunakan DestinationMasterModel
      return _parseResponseList(
        response,
        (json) => DestinationMasterModel.fromJson(json['id'] ?? '', json),
      );
    } catch (e) {
      rethrow;
    }
  }

  // ==================== HOTEL SEARCH (Amadeus Step 1) ====================

  Future<List<dynamic>> searchHotelsByCity({
    required String cityCode,
    int radius = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.searchHotelsByCity,
        queryParameters: {'cityCode': cityCode, 'radius': radius},
      );
      // API Amadeus dibungkus dalam 'data' oleh controller kita
      return _parseResponseList(response, (json) => json);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> searchLocationsByKeyword({
    required String keyword,
    String? subType,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.searchLocations,
        queryParameters: {
          'keyword': keyword,
          if (subType != null) 'subType': subType,
        },
      );
      return _parseResponseList(response, (json) => json);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== HOTEL OFFERS (Amadeus Step 2) ====================

  Future<List<HotelOfferGroup>> getHotelOffers({
    required List<String> hotelIds,
    required String checkInDate,
    required String checkOutDate,
    required int adults,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.hotelOffers,
        queryParameters: {
          'hotelIds': hotelIds.join(','), // Ubah list jadi string
          'checkInDate': checkInDate,
          'checkOutDate': checkOutDate,
          'adults': adults,
        },
      );
      return _parseResponseList(
        response,
        (json) => HotelOfferGroup.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<HotelOffer> getHotelOfferPricing(String offerId) async {
    try {
      final response = await _dio.get(ApiConstants.hotelOfferDetail(offerId));
      return _parseResponse(response, (json) => HotelOffer.fromJson(json));
    } catch (e) {
      rethrow;
    }
  }

  // ==================== FLIGHT SEARCH (Amadeus Step 1 & 2) ====================

  // (searchFlightLocations mirip dengan searchLocationsByKeyword)

  Future<List<FlightOfferModel>> searchFlightOffers(
    Map<String, dynamic> body,
  ) async {
    try {
      // Ingat, Flight Search kita adalah POST, bukan GET
      final response = await _dio.post(
        ApiConstants.searchFlightOffers,
        data: body,
      );
      return _parseResponseList(
        response,
        (json) => FlightOfferModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getFlightSeatmap(List<dynamic> flightOffers) async {
    try {
      final response = await _dio.post(
        ApiConstants.flightSeatmaps,
        data: {'data': flightOffers},
      );
      return _parseResponse(response, (json) => json);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== BOOKING (Dummy Step 3) ====================

  Future<HotelBookingModel> storeHotelBooking(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.hotelBookings, data: body);
      return _parseResponse(
        response,
        (json) => HotelBookingModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<FlightBookingModel> storeFlightBooking(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post(ApiConstants.flightBookings, data: body);
      return _parseResponse(
        response,
        (json) => FlightBookingModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BookingModel>> getMyBookings({String? type}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) {
        queryParams['type'] = type;
      }

      final response = await _dio.get(
        ApiConstants.myBookings,
        queryParameters: queryParams,
      );

      // Kita asumsikan backend mengembalikan { success: true, data: [...] }
      if (response.data['data'] is List) {
        return (response.data['data'] as List)
            .map((json) => BookingModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<HotelBookingModel>> getHotelBookings({
    String? tripId,
    String? status,
    int? page,
    int? limit,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.hotelBookingsList,
        queryParameters: {
          if (tripId != null) 'tripId': tripId,
          if (status != null) 'status': status,
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
      );
      return _parseResponseList(
        response,
        (json) => HotelBookingModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FlightBookingModel>> getFlightBookings({
    String? tripId,
    String? status,
    int? page,
    int? limit,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.flightBookingsList,
        queryParameters: {
          if (tripId != null) 'tripId': tripId,
          if (status != null) 'status': status,
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
      );
      return _parseResponseList(
        response,
        (json) => FlightBookingModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  // ==================== WISHLIST ====================

  /// Mengecek apakah destinasi tertentu sudah ada di wishlist user.
  Future<bool> checkWishlistStatus(String destinationId) async {
    try {
      final response = await _dio.get(
        ApiConstants.wishlistCheck(destinationId),
      );

      if (response.data != null &&
          response.data['data'] != null &&
          response.data['data']['isWishlisted'] is bool) {
        return response.data['data']['isWishlisted'] as bool;
      }

      return false;
    } catch (e) {
      // Jika terjadi error (misal network), jangan crash UI, anggap belum di-wishlist
      return false;
    }
  }

  /// Toggle wishlist (tambah jika belum ada, hapus jika sudah ada).
  /// Mengembalikan `true` jika setelah toggle status menjadi di-wishlist.
  Future<bool> toggleWishlist(String destinationId) async {
    try {
      final response = await _dio.post(
        ApiConstants.wishlistToggle,
        data: {'destinationId': destinationId},
      );

      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        if (data['isWishlisted'] is bool) {
          return data['isWishlisted'] as bool;
        }
      }

      return false;
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiConstants.wishlistToggle),
        message: e.toString(),
      );
    }
  }

  Future<List<WishlistModel>> getWishlistItems() async {
    try {
      final response = await _dio.get(ApiConstants.wishlist);
      return _parseResponseList(
        response,
        (json) => WishlistModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteWishlistItem(String wishlistId) async {
    try {
      await _dio.delete(ApiConstants.wishlistDetail(wishlistId));
    } catch (e) {
      rethrow;
    }
  }

  // ==================== NOTIFICATIONS ====================

  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.notifications,
        queryParameters: {if (unreadOnly) 'unreadOnly': unreadOnly},
      );
      return _parseResponseList(
        response,
        (json) => NotificationModel.fromJson(json['id'] ?? '', json),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _dio.patch(ApiConstants.notificationMarkRead(notificationId));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await _dio.patch(ApiConstants.notificationMarkAllRead);
    } catch (e) {
      rethrow;
    }
  }
}
