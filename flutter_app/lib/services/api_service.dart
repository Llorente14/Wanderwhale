// lib/services/api_service.dart

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wanderwhale/models/booking_model.dart';
import 'package:wanderwhale/models/destination_master_model.dart';
import 'package:wanderwhale/models/flight_booking_model.dart';
import 'package:wanderwhale/models/flight_offer_model.dart';
import 'package:wanderwhale/models/hotel_booking_model.dart';
import 'package:wanderwhale/models/hotel_offer_model.dart';
import 'package:wanderwhale/models/notification_model.dart';
import 'package:wanderwhale/models/trip_destination_model.dart';
import 'package:wanderwhale/models/trip_hotel_model.dart';
import 'package:wanderwhale/models/trip_model.dart';
import 'package:wanderwhale/models/user_model.dart';
import 'package:wanderwhale/models/wishlist_model.dart';
import 'package:wanderwhale/utils/constants.dart';

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

    // Debug: print baseUrl used by Dio and enable verbose logging temporarily
    print('DEBUG: ApiService initialized with baseUrl=${_dio.options.baseUrl}');
    _dio.interceptors.add(
      LogInterceptor(requestBody: false, responseBody: false, error: true),
    );

    // Interceptor untuk menambahkan token Firebase Auth
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. Dapatkan user yang sedang login
          final user = _auth.currentUser;

          if (user != null) {
            try {
              // 2. Minta ID token (ini akan otomatis refresh jika kedaluwarsa)
              final token = await user.getIdToken();
              options.headers['Authorization'] = 'Bearer $token';
            } catch (e) {
              // Jika gagal mendapatkan token, lanjutkan tanpa header
              // Request akan gagal dengan 401, dan akan ditangani di onError
              print("Warning: Failed to get ID token: $e");
            }
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 Unauthorized - coba refresh token dan retry
          if (error.response?.statusCode == 401) {
            final user = _auth.currentUser;

            if (user != null) {
              try {
                // Force refresh token
                final newToken = await user.getIdToken(true);

                // Retry request dengan token baru
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newToken';

                // Clone request dengan options baru
                final response = await _dio.fetch(options);
                return handler.resolve(response);
              } catch (refreshError) {
                // Jika refresh gagal, token mungkin sudah tidak valid
                print("Token refresh failed: $refreshError");
                print("Sesi berakhir. Silakan login ulang.");

                // Return error yang lebih informatif
                return handler.next(
                  DioException(
                    requestOptions: error.requestOptions,
                    response: error.response,
                    type: DioExceptionType.badResponse,
                    message: "Sesi berakhir. Silakan login ulang.",
                  ),
                );
              }
            } else {
              // User tidak login
              print(
                "User tidak terautentikasi. Silakan login terlebih dahulu.",
              );
              return handler.next(
                DioException(
                  requestOptions: error.requestOptions,
                  response: error.response,
                  type: DioExceptionType.badResponse,
                  message: "Silakan login terlebih dahulu.",
                ),
              );
            }
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

  static String getErrorMessage(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet connection and try again.';
    }
    if (error.type == DioExceptionType.receiveTimeout) {
      return 'Request timeout. The server is taking too long to respond. Please try again.';
    }
    if (error.type == DioExceptionType.sendTimeout) {
      return 'Send timeout. Please check your internet connection and try again.';
    }
    if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return 'Unauthorized. Please login again.';
      }
      if (statusCode == 403) {
        return 'Access forbidden. You don\'t have permission to perform this action.';
      }
      if (statusCode == 404) {
        return 'Resource not found.';
      }
      if (statusCode == 500) {
        return 'Server error. Please try again later.';
      }
      return 'Request failed with status code $statusCode.';
    }
    if (error.type == DioExceptionType.cancel) {
      return 'Request was cancelled.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Connection error. Please check your internet connection.';
    }
    if (error.type == DioExceptionType.unknown) {
      return 'An unexpected error occurred. Please try again.';
    }
    return error.message ?? 'An error occurred. Please try again.';
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
          },
        },
      ],
      "travelers": List.generate(
        travelers,
        (index) => {"id": "${index + 1}", "travelerType": "ADULT"},
      ),
      "sources": ["GDS"],
      "searchCriteria": {"maxFlightOffers": 50},
    };

    try {
      final response = await _dio.post(
        ApiConstants.searchFlightOffers,
        data: payload,
      );
      return _parseResponseList(
        response,
        (json) => FlightOfferModel.fromJson(json),
      );
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

  Future<UserModel> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiConstants.userProfile, data: data);
      return _parseResponse(response, (json) => UserModel.fromJson(json));
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> getUserProfile() async {
    try {
      // Jika user belum login, jangan panggil API supaya tidak error 401.
      final user = _auth.currentUser;
      if (user == null) {
        throw DioException(
          requestOptions: RequestOptions(path: ApiConstants.userProfile),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.userProfile),
            statusCode: 401,
          ),
          message: "User tidak terautentikasi. Silakan login terlebih dahulu.",
        );
      }

      final response = await _dio.get(ApiConstants.userProfile);
      return _parseResponse(response, (json) => UserModel.fromJson(json));
    } on DioException catch (e) {
      // Handle 404 - user profile belum dibuat di backend
      if (e.response?.statusCode == 404) {
        // User sudah login tapi profile belum ada, throw error yang jelas
        throw DioException(
          requestOptions: e.requestOptions,
          type: DioExceptionType.badResponse,
          response: e.response,
          message: "Profile belum dibuat. Silakan lengkapi profil Anda.",
        );
      }
      rethrow;
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
      print('📡 getTripDestinations: Fetching for tripId: $tripId');
      final response = await _dio.get(
        ApiConstants.tripDestinations(tripId),
        queryParameters: {if (sortBy != null) 'sortBy': sortBy},
      );

      print('📡 getTripDestinations: Response status: ${response.statusCode}');
      print('📡 getTripDestinations: Response data: ${response.data}');

      final destinations = _parseResponseList(
        response,
        (json) => TripDestinationModel.fromJson(json),
      );

      print(
        '✅ getTripDestinations: Parsed ${destinations.length} destinations',
      );
      if (destinations.isNotEmpty) {
        print('✅ First destination: ${destinations.first.destinationName}');
        print('✅ First destination country: ${destinations.first.country}');
        print('✅ First destination city: ${destinations.first.city}');
      }

      return destinations;
    } catch (e) {
      print('❌ getTripDestinations: Error - $e');
      // Handle 404 - trip belum punya destinations
      if (e is DioException && e.response?.statusCode == 404) {
        print('⚠️ getTripDestinations: 404 - Returning empty list');
        return [];
      }
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
      // Jika user belum login, return empty list
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

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
      // Jika terjadi 401, return empty list (user tidak login)
      if (e is DioException && e.response?.statusCode == 401) {
        return [];
      }
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
      // Jika user belum login, return empty list
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ getHotelBookings: User belum login');
        return [];
      }

      print('📡 getHotelBookings: Fetching for user ${user.uid}');
      print(
        '📡 Filter: tripId=$tripId, status=$status, page=$page, limit=$limit',
      );

      final response = await _dio.get(
        ApiConstants.hotelBookingsList,
        queryParameters: {
          if (tripId != null) 'tripId': tripId,
          if (status != null) 'status': status,
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
      );

      print('📡 getHotelBookings: Response status: ${response.statusCode}');
      print('📡 getHotelBookings: Response data: ${response.data}');

      final bookings = _parseResponseList(
        response,
        (json) => HotelBookingModel.fromJson(json),
      );

      print('✅ getHotelBookings: Parsed ${bookings.length} hotel bookings');
      if (bookings.isNotEmpty) {
        print('✅ First hotel: ${bookings.first.hotelName}');
        print('✅ First hotel check-in: ${bookings.first.checkInDate}');
        print('✅ First hotel location: ${bookings.first.hotelAddress}');
      }

      return bookings;
    } catch (e) {
      print('❌ getHotelBookings: Error - $e');
      // Jika terjadi 401, return empty list (user tidak login)
      if (e is DioException && e.response?.statusCode == 401) {
        print('⚠️ getHotelBookings: 401 - User not authenticated');
        return [];
      }
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
      // Jika user belum login, return empty list
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ getFlightBookings: User belum login');
        return [];
      }

      print('📡 getFlightBookings: Fetching for user ${user.uid}');
      print(
        '📡 Filter: status=$status, tripId=$tripId, page=$page, limit=$limit',
      );

      final response = await _dio.get(
        ApiConstants.flightBookingsList,
        queryParameters: {
          if (tripId != null) 'tripId': tripId,
          if (status != null) 'status': status,
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
      );

      print('📡 getFlightBookings: Response status: ${response.statusCode}');
      print('📡 getFlightBookings: Response data: ${response.data}');

      final bookings = _parseResponseList(
        response,
        (json) => FlightBookingModel.fromJson(json),
      );

      print('✅ getFlightBookings: Parsed ${bookings.length} bookings');
      if (bookings.isNotEmpty) {
        print(
          '✅ First booking: ${bookings.first.airline} - ${bookings.first.flightNumber}',
        );
      }

      return bookings;
    } catch (e) {
      print('❌ getFlightBookings: Error - $e');
      // Handle 404 atau 500 - return empty list
      if (e is DioException &&
          (e.response?.statusCode == 404 || e.response?.statusCode == 500)) {
        print(
          '⚠️ getFlightBookings: ${e.response?.statusCode} - Returning empty list',
        );
        return [];
      }
      // Jika terjadi 401, return empty list (user tidak login)
      if (e is DioException && e.response?.statusCode == 401) {
        return [];
      }
      rethrow;
    }
  }

  // ==================== WISHLIST ====================

  /// Mengecek apakah destinasi tertentu sudah ada di wishlist user.
  Future<bool> checkWishlistStatus(String destinationId) async {
    try {
      // Jika user belum login, return false (belum di-wishlist)
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

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
      // Jika terjadi error (misal network atau 401), jangan crash UI, anggap belum di-wishlist
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
      // Jika user belum login, return empty list
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ getWishlistItems: User belum login');
        return [];
      }

      print('📡 getWishlistItems: Fetching wishlist for user ${user.uid}');
      final response = await _dio.get(ApiConstants.wishlist);

      print('📡 getWishlistItems: Response status: ${response.statusCode}');
      print('📡 getWishlistItems: Response data: ${response.data}');

      final items = _parseResponseList(
        response,
        (json) => WishlistModel.fromJson(json),
      );

      print('✅ getWishlistItems: Parsed ${items.length} items');
      if (items.isNotEmpty) {
        print(
          '✅ First item: ${items.first.destinationName} (ID: ${items.first.id})',
        );
      }

      return items;
    } catch (e) {
      print('❌ getWishlistItems: Error - $e');
      // Handle 404 - endpoint belum tersedia atau user belum memiliki wishlist
      if (e is DioException && e.response?.statusCode == 404) {
        print('⚠️ getWishlistItems: 404 - Returning empty list');
        // Return empty list jika 404 (normal jika user belum punya wishlist)
        return [];
      }
      // Jika terjadi 401, return empty list (user tidak login)
      if (e is DioException && e.response?.statusCode == 401) {
        print('⚠️ getWishlistItems: 401 - User tidak terautentikasi');
        return [];
      }
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
      // Jika user belum login, return empty list
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final response = await _dio.get(
        ApiConstants.notifications,
        queryParameters: {if (unreadOnly) 'unreadOnly': unreadOnly},
      );
      return _parseResponseList(
        response,
        (json) => NotificationModel.fromJson(
          json['id'] ?? json['notificationId'] ?? '',
          json,
        ),
      );
    } catch (e) {
      // Handle 404 - endpoint belum tersedia atau user belum memiliki notifications
      if (e is DioException && e.response?.statusCode == 404) {
        // Return empty list jika 404 (normal jika user belum punya notifications)
        return [];
      }
      // Jika terjadi 401, return empty list (user tidak login)
      if (e is DioException && e.response?.statusCode == 401) {
        return [];
      }
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

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _dio.delete(ApiConstants.notificationDelete(notificationId));
    } catch (e) {
      rethrow;
    }
  }
}
