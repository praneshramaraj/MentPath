class AppException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const AppException({
    required this.message,
    this.code,
    this.statusCode,
  });

  @override
  String toString() => 'AppException(code: $code, statusCode: $statusCode, message: $message)';
}

class NetworkException extends AppException {
  const NetworkException([String message = 'Unable to connect to server. Please check your network connection.'])
      : super(message: message, code: 'NETWORK_ERROR');
}

class TimeoutException extends AppException {
  const TimeoutException([String message = 'Connection timed out. Please try again.'])
      : super(message: message, code: 'TIMEOUT_ERROR');
}

class ServerException extends AppException {
  const ServerException(String message, {super.statusCode, String? code})
      : super(message: message, code: code ?? 'SERVER_ERROR');
}
