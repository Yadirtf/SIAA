class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

class AuthException extends ApiException {
  const AuthException({required super.message, super.statusCode, super.details});
}

class NetworkException extends ApiException {
  const NetworkException({required super.message, super.statusCode, super.details});
}

class ServerException extends ApiException {
  const ServerException({required super.message, super.statusCode, super.details});
}
