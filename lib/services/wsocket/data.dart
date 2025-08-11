import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart' show IOWebSocketChannel;

import 'constants.dart';
import 'response.dart';
import 'exceptions.dart';
import '../../models/trip.dart';
import '../../models/device.dart';
import 'package:flutter/foundation.dart';

class SocketService {
  final String _accessToken;
  WebSocketChannel? _channel;

  String _status = SocketConstants.disconnected;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  String? _lastError;
  String? get lastError => _lastError;

  SocketService({required String accessToken}) : _accessToken = accessToken;

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<String> get statusStream => _statusController.stream;
  String get currentStatus => _status;

  Future<void> connect() async {
    if (_status == SocketConstants.connecting ||
        _status == SocketConstants.connected) {
      return;
    }

    _updateStatus(SocketConstants.connecting);
    debugPrint('[WS] 연결시작…');

    try {
      final encodedToken = Uri.encodeQueryComponent(_accessToken);
      final wsUrl = '${SocketConstants.baseUrl}?token=$encodedToken';
      debugPrint('[WS] url=$wsUrl');

      _channel = IOWebSocketChannel.connect(wsUrl);

      _channel?.stream.listen(
        (message) {
          try {
            final text = message is String
                ? message
                : (message is List<int> ? utf8.decode(message) : '$message');

            final decoded = json.decode(text);
            if (decoded is Map<String, dynamic>) {
              _messageController.add(Map<String, dynamic>.from(decoded));
            } else {
              final err = 'Invalid message format: ${decoded.runtimeType}';
              _lastError = err;
              _messageController.addError(SocketException(err));
            }
          } catch (e, st) {
            final err = 'JSON 디코드 실패: $e';
            _lastError = '$err\n$st';
            _messageController.addError(SocketException(err));
          }
        },
        onError: (error, [st]) {
          _lastError = 'WS onError: $error${st != null ? '\n$st' : ''}';
          debugPrint('[WS] onError: $_lastError');
          _updateStatus(SocketConstants.error);
          _messageController.addError(
            SocketConnectionException('연결실패: $error'),
          );
        },
        onDone: () {
          _lastError = 'WS onDone: 연결종료';
          debugPrint('[WS] onDone: $_lastError');
          _updateStatus(SocketConstants.disconnected);
          _messageController.addError(
            SocketConnectionException('연결종료'),
          );
        },
    
        cancelOnError: false,
      );

      _updateStatus(SocketConstants.connected);
      debugPrint('[WS] 연결');
    } catch (e, st) {
      _lastError = '연결에러: $e\n$st';
      debugPrint('[WS] 연결에러: $_lastError');
      _updateStatus(SocketConstants.error);
      throw SocketConnectionException('연결실패: $e');
    }
  }

  Future<DrivingData> startDriving(int deviceId) async {
    if (_status != SocketConstants.connected) {
      throw SocketConnectionException('WebSocket 미연결');
    }

    final message = {
      'type': SocketConstants.drivingStart,
      'payload': {'deviceId': deviceId}
    };

    _channel?.sink.add(json.encode(message));
    debugPrint('[WS] -> DRIVING:START $message');

    final response = await _messageController.stream
        .firstWhere(
          (data) => data['type'] == SocketConstants.drivingStart,
          orElse: () =>
              throw SocketMessageException('응답없음', SocketConstants.drivingStart),
        )
        .timeout(const Duration(seconds: 10), onTimeout: () {
          final err = 'DRIVING:START 시간초과';
          _lastError = err;
          throw SocketMessageException(err, SocketConstants.drivingStart);
        });

    debugPrint('[WS] <- DRIVING:START $response');

    final socketResponse = SocketResponse<DrivingData>.fromJson(
      response,
      (json) => DrivingData.fromJson(json),
    );

    if (!socketResponse.isSuccess) {
      final err = '운전시작실패: ${socketResponse.error}';
      _lastError = err;
      throw SocketMessageException(err, SocketConstants.drivingStart);
    }

    return socketResponse.data!;
  }

  Future<DrivingEndData> endDriving(int deviceId) async {
    if (_status != SocketConstants.connected) {
      throw SocketConnectionException('WebSocket 미연결');
    }

    final message = {
      'type': SocketConstants.drivingEnd,
      'payload': {'deviceId': deviceId}
    };

    _channel?.sink.add(json.encode(message));
    debugPrint('[WS] -> DRIVING:END $message');

    final response = await _messageController.stream
        .firstWhere(
          (data) => data['type'] == SocketConstants.drivingEnd,
          orElse: () =>
              throw SocketMessageException('응답없음', SocketConstants.drivingEnd),
        )
        .timeout(const Duration(seconds: 15), onTimeout: () {
          final err = 'DRIVING:END 시간초과';
          _lastError = err;
          throw SocketMessageException(err, SocketConstants.drivingEnd);
        });

    debugPrint('[WS] <- DRIVING:END $response');

    final socketResponse = SocketResponse<DrivingEndData>.fromJson(
      response,
      (json) => DrivingEndData.fromJson(json),
    );

    if (!socketResponse.isSuccess) {
      final err = '운전종료실패: ${socketResponse.error}';
      _lastError = err;
      throw SocketMessageException(err, SocketConstants.drivingEnd);
    }

    return socketResponse.data!;
  }

  Future<List<Device>> getDeviceList() async {
    if (_status != SocketConstants.connected) {
      throw SocketConnectionException('WebSocket 미연결');
    }

    final message = {'type': SocketConstants.deviceList, 'payload': {}};
    _channel?.sink.add(json.encode(message));
    debugPrint('[WS] -> DEVICE:LIST');

    final response = await _messageController.stream
        .firstWhere(
          (data) => data['type'] == SocketConstants.deviceList,
          orElse: () =>
              throw SocketMessageException('응답없음', SocketConstants.deviceList),
        )
        .timeout(const Duration(seconds: 10), onTimeout: () {
          final err = 'DEVICE:LIST 시간초과';
          _lastError = err;
          throw SocketMessageException(err, SocketConstants.deviceList);
        });

    debugPrint('[WS] <- DEVICE:LIST $response');

    final socketResponse = SocketResponse<List<Device>>.fromJson(
      response,
      (json) => (json as List).map((e) => Device.fromJson(e)).toList(),
    );

    if (!socketResponse.isSuccess) {
      final err = '장치 리스트 응답 에러: ${socketResponse.error}';
      _lastError = err;
      throw SocketMessageException(err, SocketConstants.deviceList);
    }

    return socketResponse.data!;
  }

  Future<void> testConnection() async {
    if (_status != SocketConstants.connected) {
      throw SocketConnectionException('WebSocket 미연결');
    }

    final message = {'type': SocketConstants.socketTest, 'payload': {}};
    _channel?.sink.add(json.encode(message));
    debugPrint('[WS] -> SOCKET:TEST');

    final response = await _messageController.stream
        .firstWhere(
          (data) => data['type'] == SocketConstants.socketTest,
          orElse: () =>
              throw SocketMessageException('응답없음', SocketConstants.socketTest),
        )
        .timeout(const Duration(seconds: 5), onTimeout: () {
          final err = 'SOCKET:TEST 시간초과';
          _lastError = err;
          throw SocketMessageException(err, SocketConstants.socketTest);
        });

    debugPrint('[WS] <- SOCKET:TEST $response');

    final socketResponse = SocketResponse<void>.fromJson(response, (_) {});
    if (!socketResponse.isSuccess) {
      final err = '연결테스트 실패: ${socketResponse.error}';
      _lastError = err;
      throw SocketMessageException(err, SocketConstants.socketTest);
    }
  }

  Future<void> disconnect() async {
    try {
      await _channel?.sink.close();
    } catch (e) {
      debugPrint('WebSocket disconnect error: $e');
    } finally {
      _channel = null;
      _updateStatus(SocketConstants.disconnected);
      await _messageController.close();
      await _statusController.close();
    }
  }

  void _updateStatus(String status) {
    _status = status;
    try {
      _statusController.add(status);
    } catch (e) {
      debugPrint('StatusController 종료: $e');
    }
  }
}
