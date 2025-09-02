import 'dart:async';
import 'package:flutter/foundation.dart';

import 'auth_manager.dart';
import 'services/wsocket/data.dart';
import 'services/wsocket/constants.dart';

import 'package:dm1/models/trip.dart';

class SocketManager with ChangeNotifier {
  SocketService? _socketService;

  StreamSubscription<Map<String, dynamic>>? _msgSub;
  StreamSubscription<String>? _statusSub;

  Timer? _reconnectTimer;
  int _retryCount = 0;
  bool _wantReconnect = true;

  String _status = SocketConstants.disconnected;
  String? _error;

  int? _lastStatus;

  DrivingData? _currentDriving;
  DrivingEndData? _lastEndData;
  bool _serverDriving = false;
  int? _currentDeviceId;

  final Duration _noStatusWindow = const Duration(seconds: 2);
  Timer? _noStatusTimer;
  bool _noStatusWindowElapsed = false;

  String get status => _status;
  String? get error => _error;

  int? get lastStatus => _lastStatus; 
  bool get isDrivingByServer => _serverDriving;
  bool get isDriving => _currentDriving != null;

  DrivingData? get currentDriving => _currentDriving;
  DrivingEndData? get lastEndData => _lastEndData;

  int? get currentDeviceId => _currentDeviceId;
  bool get hasDevice => _currentDeviceId != null;
  bool get noStatusWindowElapsed => _noStatusWindowElapsed;

  Stream<Map<String, dynamic>>? get messageStream => _socketService?.messageStream;

  Future<void> connect(AuthManager authManager) async {
    try {
      final accessToken = await authManager.getAccessToken();
      _wantReconnect = true;

      await _statusSub?.cancel();
      await _msgSub?.cancel();
      _statusSub = null;
      _msgSub = null;

      _currentDeviceId = null;
      _lastStatus = null;
      _serverDriving = false;
      _currentDriving = null;
      _lastEndData = null;
      _noStatusTimer?.cancel();
      _noStatusWindowElapsed = false;

      _socketService = SocketService(accessToken: accessToken);

      _statusSub = _socketService!.statusStream.listen((s) {
        _status = s;
        _error = null;
        notifyListeners();

        if (s == SocketConstants.connected) {
          _retryCount = 0;
          _reconnectTimer?.cancel();

          _noStatusTimer?.cancel();
          final was = _noStatusWindowElapsed;
          _noStatusWindowElapsed = false;
          _noStatusTimer = Timer(_noStatusWindow, () {
            _noStatusWindowElapsed = true;
            notifyListeners(); 
          });
          if (was != _noStatusWindowElapsed) {
            notifyListeners();
          }
        } else if (_wantReconnect &&
            (s == SocketConstants.error || s == SocketConstants.disconnected)) {
          _scheduleReconnect(authManager);
        }
      });

      _msgSub = _socketService!.messageStream.listen((message) {
        final type = message['type'];

        if (type == 'DRIVING:STATUS') {
          try {
            final prevLastStatus = _lastStatus;
            final prevDeviceId   = _currentDeviceId;
            final prevDriving    = _currentDriving;
            final prevServerFlag = _serverDriving;
            final prevNoWin      = _noStatusWindowElapsed;

            final next = DrivingData.fromJson(message['data']);

            _noStatusTimer?.cancel();
            _noStatusWindowElapsed = true;

            _currentDeviceId = next.deviceId; 
            _lastStatus = next.status;

            if (next.status == 0) {
              _currentDriving = null;
              _serverDriving = false;

              notifyListeners();
              return;
            }

            _currentDriving = next;
            _serverDriving = true;

            final changed = prevDriving == null ||
                prevDriving.mileage != next.mileage ||
                prevDriving.left    != next.left   ||
                prevDriving.right   != next.right  ||
                prevDriving.front   != next.front  ||
                prevDriving.status  != next.status ||
                prevDriving.endTime != next.endTime ||
                prevLastStatus      != _lastStatus ||
                prevDeviceId        != _currentDeviceId ||
                prevServerFlag      != _serverDriving ||
                prevNoWin           != _noStatusWindowElapsed;

            if (changed) {
              notifyListeners();
            } else {
              notifyListeners();
            }
          } catch (e) {
            debugPrint('DRIVING:STATUS 디코드 실패: $e');
          }
        } else if (type == SocketConstants.drivingEnd) {
          try {
            final end = DrivingEndData.fromJson(message['data']);
            _lastStatus = 0;
            _lastEndData = end;
            _currentDriving = null;
            _serverDriving = false;
            notifyListeners();
          } catch (e) {
            debugPrint('DRIVING:END 디코드 실패: $e');
          }
        }
      });

      await _socketService!.connect();

    } catch (e) {
      _error = e.toString();
      _status = SocketConstants.error;
      notifyListeners();
      if (_wantReconnect) {
        _scheduleReconnect(authManager);
      }
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      _wantReconnect = false;
      _reconnectTimer?.cancel();
      _noStatusTimer?.cancel();

      await _msgSub?.cancel();
      await _statusSub?.cancel();
      await _socketService?.disconnect();
    } finally {
      _msgSub = null;
      _statusSub = null;
      _socketService = null;

      _status = SocketConstants.disconnected;
      _lastStatus = null;
      _serverDriving = false;
      _currentDeviceId = null;
      _currentDriving = null;
      _lastEndData = null;
      _noStatusWindowElapsed = false;

      notifyListeners();
    }
  }

  Future<DrivingData> startDriving(int deviceId) async {
    if (deviceId == 0) {
      throw Exception('유효하지 않은 디바이스 ID');
    }
    try {
      debugPrint('>> SEND WS START: deviceId=$deviceId');
      final data = await _socketService!.startDriving(deviceId);

      _currentDriving = data;
      _lastEndData = null;
      _error = null;
      _serverDriving = true;
      _lastStatus = 1;
      _currentDeviceId = data.deviceId;
      notifyListeners();

      return data;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<DrivingEndData> endDriving() async {
    final int deviceId = _currentDeviceId ?? 1;
    try {
      debugPrint('>> SEND WS END: deviceId=$deviceId');
      final endData = await _socketService!.endDriving(deviceId);

      _lastEndData = endData;
      _currentDriving = null;
      _error = null;
      _serverDriving = false;
      _lastStatus = 0;
      notifyListeners();

      return endData;
    } catch (e) {
      _currentDriving = null;
      _serverDriving = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> testConnection() async {
    try {
      await _socketService?.testConnection();
      _error = null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void _scheduleReconnect(AuthManager auth) {
    _reconnectTimer?.cancel();

    final sec = 1 << (_retryCount.clamp(0, 5));
    final delay = Duration(seconds: sec);

    _reconnectTimer = Timer(delay, () async {
      if (!_wantReconnect) return;
      try {
        _retryCount++;
        await _socketService?.connect();
      } catch (_) {
        _scheduleReconnect(auth);
      }
    });
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _noStatusTimer?.cancel();
    _msgSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }
}
