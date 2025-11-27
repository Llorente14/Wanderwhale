// lib/services/api_service.dart

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/utils/constants.dart';
import 'package:flutter_app/models/user_model.dart';
import 'package:flutter_app/models/trip_model.dart';
import 'package:flutter_app/models/booking_model.dart';
import 'package:flutter_app/models/destination_master_model.dart';
// (Tambahkan model lain seperti HotelModel, FlightModel jika Anda membuatnya)

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
            // TODO: Panggil AuthProvider untuk logout & redirect ke login
            print("Token tidak valid. Harap login ulang.");
          }
          return handler.next(error);
        },
      ),
    );
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

  // (Tambahkan createTrip, addTripDestination, dll. di sini)

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

  Future<List<dynamic>> getHotelOffers({
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
      return _parseResponseList(response, (json) => json);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getHotelOfferPricing(String offerId) async {
    try {
      final response = await _dio.get(ApiConstants.hotelOfferDetail(offerId));
      return _parseResponse(response, (json) => json); // Mengembalikan 1 objek
    } catch (e) {
      rethrow;
    }
  }

  // ==================== FLIGHT SEARCH (Amadeus Step 1 & 2) ====================

  // (searchFlightLocations mirip dengan searchLocationsByKeyword)

  Future<List<dynamic>> searchFlightOffers(Map<String, dynamic> body) async {
    try {
      // Ingat, Flight Search kita adalah POST, bukan GET
      final response = await _dio.post(
        ApiConstants.searchFlightOffers,
        data: body,
      );
      return _parseResponseList(response, (json) => json);
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

  Future<dynamic> storeHotelBooking(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.hotelBookings, data: body);
      return _parseResponse(response, (json) => json);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> storeFlightBooking(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.flightBookings, data: body);
      return _parseResponse(response, (json) => json);
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
}
