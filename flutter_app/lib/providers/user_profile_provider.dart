import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../models/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userProfileProvider = ChangeNotifierProvider<UserProfileProvider>((ref) {
  return UserProfileProvider();
});

class UserProfileProvider extends ChangeNotifier {
  UserProfileProvider({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  UserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  String? _authToken;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void seedProfile(UserProfile profile) {
    _profile = profile;
    _errorMessage = null;
    notifyListeners();
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  Future<String?> _getAuthToken() async {
    if (_authToken != null && _authToken!.isNotEmpty) {
      return _authToken;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        _authToken = await user.getIdToken();
        return _authToken;
      } catch (e) {
        debugPrint('Error getting auth token: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> loadProfile({String? authToken, bool forceRefresh = false}) async {
    if (authToken != null) {
      _authToken = authToken;
    }

    final token = await _getAuthToken();
    if (token == null) {
      _errorMessage = 'Token autentikasi belum diset dan user tidak login.';
      notifyListeners();
      return;
    }

    if (!forceRefresh && _profile != null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiClient.get(
        path: AppConfig.userProfileEndpoint,
        authToken: token,
      );

      final data = result['data'] ?? result;

      _profile = UserProfile.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Gunakan ApiService langsung atau lewat ApiClient jika sudah ada wrapper-nya.
      // Di sini kita asumsikan ApiClient punya method put atau kita pakai ApiService singleton jika ApiClient hanya wrapper http biasa.
      // Tapi karena di kode yang ada ApiClient dipakai untuk get, kita coba pakai itu juga untuk put jika ada.
      // Cek ApiClient dulu.
      // Ternyata ApiClient di sini sepertinya wrapper custom. Mari kita lihat ApiClient dulu kalau perlu.
      // Tapi tunggu, di file user_profile_provider.dart yang saya baca tadi:
      // import '../core/network/api_client.dart';
      // Dan _apiClient.get(...)
      
      // Kalau saya lihat ApiService.dart yang saya edit sebelumnya, itu pakai Dio langsung.
      // UserProfileProvider pakai ApiClient.
      // Ini ada inkonsistensi di codebase user. Ada ApiService (singleton dengan Dio) dan ApiClient (wrapper).
      // Saya harus cek ApiClient.dart dulu untuk memastikan dia punya method PUT.
      
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User tidak terautentikasi');
      }

      final result = await _apiClient.put(
        path: AppConfig.userProfileEndpoint,
        data: data,
        authToken: token,
      );

      final responseData = result['data'] ?? result;
       _profile = UserProfile.fromJson(
        Map<String, dynamic>.from(responseData as Map),
      );
      
    } catch (error) {
      _errorMessage = error.toString();
      rethrow; // Rethrow agar UI bisa tangkap errornya
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadProfile(forceRefresh: true);

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }
}


