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
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User tidak terautentikasi');
      }

      // JSON request - photoURL dikirim sebagai string dalam data
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
      rethrow;
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


