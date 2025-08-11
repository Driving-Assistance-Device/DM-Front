class SocketException implements Exception {
  final String message;
  final String? type;

  SocketException(this.message, {this.type});

  @override
  String toString() => 'SocketException: $message (Type: $type)';
}

class SocketConnectionException extends SocketException {
  SocketConnectionException(String message) : super(message);
}

class SocketMessageException extends SocketException {
  SocketMessageException(String message, String type) : super(message, type: type);
}