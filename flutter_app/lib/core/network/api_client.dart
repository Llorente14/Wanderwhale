import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> get({
    required String path,
    required String authToken,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');

    final response = await _client
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
        )
        .timeout(AppConfig.networkTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  Future<Map<String, dynamic>> put({
    required String path,
    required Map<String, dynamic> data,
    required String authToken,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');

    final response = await _client
        .put(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode(data),
        )
        .timeout(AppConfig.networkTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}








