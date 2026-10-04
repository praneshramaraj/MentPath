import '../config/api_config.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Mentor-Student App';

  // Base API URL configuration targeting production Render backend
  static String get apiBaseUrl => ApiConfig.apiBaseUrl;

  static String get baseUrl => ApiConfig.baseUrl;

  static const int apiTimeoutSeconds = 10;
}
