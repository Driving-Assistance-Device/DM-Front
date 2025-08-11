class ApiResponse<T> {
  final String resultType;
  final ApiError? error;
  final T? success;

  ApiResponse({
    required this.resultType,
    this.error,
    this.success,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, 
    T Function(dynamic) fromJsonSuccess
  ) {
    return ApiResponse<T>(
      resultType: json['resultType'],
      error: json['error'] != null 
          ? ApiError.fromJson(json['error']) 
          : null,
      success: json['success'] != null 
          ? fromJsonSuccess(json['success']) 
          : null,
    );
  }
}

class ApiError {
  final String errorCode;
  final String reason;
  final dynamic data;

  ApiError({
    required this.errorCode,
    required this.reason,
    this.data,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      errorCode: json['errorCode'],
      reason: json['reason'],
      data: json['data'],
    );
  }
}