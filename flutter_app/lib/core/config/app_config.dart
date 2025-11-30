class AppConfig {
  AppConfig._();

  /// Base URL untuk backend API.
  /// Gunakan --dart-define=API_BASE_URL=https://example.com jika perlu override.
  static const String apiBaseUrl =
      'https://wanderwhale-production.up.railway.app';

  /// Endpoint user profile relatif terhadap [apiBaseUrl].
  static const String userProfileEndpoint = '/api/users/profile';

  /// Bangun URL penuh untuk endpoint API yang diberikan.
  /// Contoh: `AppConfig.endpoint('/api/users/profile')` -> https://.../api/users/profile
  static String endpoint(String path) {
    if (path.startsWith('/')) return apiBaseUrl + path;
    return apiBaseUrl + '/' + path;
  }

  /// Timeout default untuk request network.
  static const Duration networkTimeout = Duration(seconds: 20);
}
