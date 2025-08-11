class SocketConstants {
  static const String baseUrl = 'wss://api.driving.p-e.kr/ws';
  
  // WebSocket datatype
  static const String drivingStart = 'DRIVING:START';
  static const String drivingEnd = 'DRIVING:END';
  static const String deviceList = 'DEVICE:LIST';
  static const String socketTest = 'SOCKET:TEST';
  
  // WebSocket states
  static const String connected = 'CONNECTED';
  static const String disconnected = 'DISCONNECTED';
  static const String connecting = 'CONNECTING';
  static const String error = 'ERROR';
}