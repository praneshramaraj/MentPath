class AppConstants {
  AppConstants._();

  static const String appName = 'Mentor-Student App';

  // Base API URL configuration
  // For iOS / macOS / Web / Desktop: http://127.0.0.1:8000/api/v1
  // For Android Emulator: http://10.0.2.2:8000/api/v1
  static String get apiBaseUrl {
    return 'https://green-ghosts-rest.loca.lt/api/v1';
  }

  static const int apiTimeoutSeconds = 10;
}
