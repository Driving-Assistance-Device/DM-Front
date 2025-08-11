import 'package:dm1/services/http/response.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiError? apiError;

  ApiException({
    required this.message,
    this.statusCode,
    this.apiError,
  });

  @override
  String toString() => 'ApiException: $message (${apiError?.errorCode})';
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class UnexpectedResponseException implements Exception {
  @override
  String toString() => 'UnexpectedResponseException: Invalid server response';
}