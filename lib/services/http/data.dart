import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'response.dart';
import 'exceptions.dart';
import '../../models/user.dart';
import '../../models/driving.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}

class HttpService {
  final String baseUrl;
  final http.Client? client;

  HttpService({this.baseUrl = ApiConstants.baseUrl, this.client});

  Future<ApiResponse<T>> _request<T>(
    String method,
    String endpoint,
    T Function(dynamic) fromJsonSuccess, {
    Map<String, String>? headers,
    dynamic body,
    Map<String, String>? queryParams,
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final request = http.Request(method, uri);

      final mergedHeaders = <String, String>{
        'Accept': 'application/json',
        if (headers != null) ...headers,
      };
      request.headers.addAll(mergedHeaders);

      if (body != null) {
        request.body = json.encode(body);
      }

      final streamed = await (client ?? http.Client()).send(request);
      final statusCode = streamed.statusCode;
      final responseBody = await streamed.stream.bytesToString();
      final trimmed = responseBody.trim();

      Map<String, dynamic>? _safeDecode(String s) {
        if (s.isEmpty) return null;
        try {
          final decoded = json.decode(s);
          return decoded is Map<String, dynamic> ? decoded : null;
        } catch (_) {
          return null;
        }
      }

      if (statusCode >= 200 && statusCode < 300) {
        final decoded = _safeDecode(trimmed) ?? {
          'resultType': 'SUCCESS',
          'error': null,
          'success': null,
        };

        final hasResultType = decoded.containsKey('resultType');
        final normalized = hasResultType
            ? decoded
            : {
                'resultType': 'SUCCESS',
                'error': null,
                'success': decoded,
              };

        return ApiResponse<T>.fromJson(
          normalized,
          fromJsonSuccess,
        );
      } else {
        final decoded = _safeDecode(trimmed);
        if (decoded != null && decoded['error'] != null) {
          try {
            final error = ApiError.fromJson(decoded['error']);
            throw ApiException(
              message: error.reason,
              statusCode: statusCode,
              apiError: error,
            );
          } catch (_) {}
        }
        throw ApiException(
          message: trimmed.isEmpty
              ? 'HTTP $statusCode with empty body'
              : 'HTTP $statusCode: $trimmed',
          statusCode: statusCode,
          apiError: null,
        );
      }
    } on SocketException {
      throw NetworkException('Network connection failed');
    } on http.ClientException {
      throw NetworkException('Request failed');
    } on ApiException {
      rethrow;
    } on FormatException {
      throw UnexpectedResponseException();
    }
  }

  Future<ApiResponse<User>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return _request<User>(
      'POST',
      ApiConstants.signUp,
      (json) => User.fromJson(json),
      headers: ApiConstants.jsonHeader,
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
  }

  Future<ApiResponse<AuthTokens>> signIn({
    required String email,
    required String password,
  }) async {
    return _request<AuthTokens>(
      'POST',
      ApiConstants.signIn,
      (json) => AuthTokens.fromJson(json),
      headers: ApiConstants.jsonHeader,
      body: {
        'email': email,
        'password': password,
      },
    );
  }

  Future<ApiResponse<void>> signOut(String accessToken) async {
    return _request<void>(
      'POST',
      ApiConstants.signOut,
      (_) {},
      headers: ApiConstants.authHeader(accessToken),
    );
  }

  Future<ApiResponse<AuthTokens>> refreshAccessToken(
      String refreshToken) async {
    return _request<AuthTokens>(
      'POST',
      ApiConstants.refreshToken,
      (json) => AuthTokens.fromJson(json),
      headers: ApiConstants.jsonHeader,
      body: {'refreshToken': refreshToken},
    );
  }

  Future<ApiResponse<void>> verifyAccessToken(String accessToken) async {
    return _request<void>(
      'GET',
      ApiConstants.protected,
      (_) {},
      headers: ApiConstants.authHeader(accessToken),
    );
  }

  Future<ApiResponse<User>> getUserProfile(String accessToken) async {
    return _request<User>(
      'GET',
      ApiConstants.userProfile,
      (json) => User.fromJson(json),
      headers: ApiConstants.authHeader(accessToken),
    );
  }

  Future<ApiResponse<UserRecommendation>> getUserRecommendations(
      String accessToken) async {
    return _request<UserRecommendation>(
      'GET',
      ApiConstants.userRecommend,
      (json) => UserRecommendation.fromJson(json),
      headers: ApiConstants.authHeader(accessToken),
    );
  }

  Future<ApiResponse<DrivingRecord>> getLatestDriving(
      String accessToken) async {
    return _request<DrivingRecord>(
      'GET',
      ApiConstants.latestDriving,
      (json) => DrivingRecord.fromJson(json),
      headers: ApiConstants.authHeader(accessToken),
    );
  }

  Future<ApiResponse<DrivingTotalResponse>> getAllDriving(
    String accessToken, {
    DateTime? date,
  }) async {
    final queryParams = date != null
        ? {'date': date.toIso8601String().substring(0, 10)}
        : null;

    return _request<DrivingTotalResponse>(
      'GET',
      ApiConstants.totalDriving,
      (json) {
        if (json is List) {
          final drivings = json
              .map<DrivingRecord>((e) => DrivingRecord.fromJson(e as Map<String, dynamic>))
              .toList();
          return DrivingTotalResponse(
            userName: '', 
            drivings: drivings,
          );
        }

        if (json is Map<String, dynamic>) {
          return DrivingTotalResponse.fromJson(json);
        }

        throw UnexpectedResponseException();
      },
      headers: ApiConstants.authHeader(accessToken),
      queryParams: queryParams,
    );
  }

  Future<ApiResponse<DrivingTotalCount>> getDrivingStatistics(
      String accessToken) async {
    return _request<DrivingTotalCount>(
      'GET',
      ApiConstants.drivingCount,
      (json) => DrivingTotalCount.fromJson(json),
      headers: ApiConstants.authHeader(accessToken),
    );
  }
  Future<ApiResponse<void>> deleteDriving(String accessToken, int drivingId) async {
  return _request<void>(
    'DELETE',
    '${ApiConstants.latestDriving}$drivingId', 
    (_) {},
    headers: ApiConstants.authHeader(accessToken),
  );
}
}
