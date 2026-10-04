import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'app_exception.dart';

class ApiClient {
  final http.Client _client;
  final String _baseUrl;
  String? _authToken;

  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    try {
      final response = await _client
          .get(
            uri,
            headers: _buildHeaders(headers),
          )
          .timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const TimeoutException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Unexpected network error: ${e.toString()}');
    }
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    try {
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const TimeoutException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Unexpected network error: ${e.toString()}');
    }
  }

  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    try {
      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const TimeoutException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Unexpected network error: ${e.toString()}');
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    try {
      final response = await _client
          .delete(
            uri,
            headers: _buildHeaders(headers),
          )
          .timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const TimeoutException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Unexpected network error: ${e.toString()}');
    }
  }

  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic body;

    try {
      if (response.body.isNotEmpty) {
        body = jsonDecode(response.body);
      }
    } catch (_) {
      // Non-JSON body fallback
    }

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    } else if (statusCode == 401) {
      final msg = body is Map ? (body['error']?['message'] ?? body['message'] ?? 'Unauthorized access') : 'Unauthorized access';
      throw ServerException(msg, statusCode: 401, code: 'UNAUTHORIZED');
    } else if (statusCode == 403) {
      final msg = body is Map ? (body['error']?['message'] ?? body['message'] ?? 'Access forbidden') : 'Access forbidden';
      throw ServerException(msg, statusCode: 403, code: 'FORBIDDEN');
    } else if (statusCode == 404) {
      throw const ServerException('Requested resource not found', statusCode: 404, code: 'NOT_FOUND');
    } else {
      final message = body is Map ? (body['error']?['message'] ?? body['message'] ?? 'Server error occurred ($statusCode)') : 'Server error occurred ($statusCode)';
      final code = body is Map ? (body['error']?['code'] ?? 'SERVER_ERROR') : 'SERVER_ERROR';
      throw ServerException(message, statusCode: statusCode, code: code);
    }
  }
}
