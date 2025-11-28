class AppConfig {
  AppConfig._();

  /// Base URL untuk backend API.
  /// Gunakan --dart-define=API_BASE_URL=https://example.com jika perlu override.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  /// Endpoint user profile relatif terhadap [apiBaseUrl].
  static const String userProfileEndpoint = '/api/users/profile';

  /// Timeout default untuk request network.
  static const Duration networkTimeout = Duration(seconds: 20);
}






