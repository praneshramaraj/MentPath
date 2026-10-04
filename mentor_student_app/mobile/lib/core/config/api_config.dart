class ApiConfig {
  ApiConfig._();

  /// Primary Production API Base URL
  static const String baseUrl = 'https://mentpath-db.onrender.com';

  /// API Version Prefix
  static const String apiVersion = '/api/v1';

  /// Full Base URL including API version prefix
  static const String apiBaseUrl = '$baseUrl$apiVersion';
}
