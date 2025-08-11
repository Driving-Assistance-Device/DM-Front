class SocketResponse<T> {
  final String status;
  final String type;
  final T? data;
  final String? error;

  SocketResponse({
    required this.status,
    required this.type,
    this.data,
    this.error,
  });

  factory SocketResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonData) {
    return SocketResponse<T>(
      status: json['status'],
      type: json['type'],
      data: json['data'] != null ? fromJsonData(json['data']) : null,
      error: json['error'],
    );
  }
  
  bool get isSuccess => status == 'success';
}