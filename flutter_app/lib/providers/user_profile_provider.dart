import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../models/user_profile.dart';

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

  Future<void> loadProfile({String? authToken, bool forceRefresh = false}) async {
    if (authToken != null) {
      _authToken = authToken;
    }

    if (_authToken == null || _authToken!.isEmpty) {
      _errorMessage = 'Token autentikasi belum diset.';
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
        authToken: _authToken!,
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

  Future<void> refresh() => loadProfile(forceRefresh: true);

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }
}


