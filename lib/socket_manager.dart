import 'package:flutter/foundation.dart';

import 'auth_manager.dart';
import 'services/wsocket/data.dart';
import 'services/wsocket/constants.dart';

import 'package:dm1/models/device.dart';
import 'package:dm1/models/trip.dart';

class SocketManager with ChangeNotifier {
  SocketService? _socketService;
  String _status = SocketConstants.disconnected;
  DrivingData? _currentDriving;
  DrivingEndData? _lastEndData;
  List<Device> _devices = [];
  String? _error;
  bool _serverDriving = false;
  
  //get
  String get status => _status;
  String? get error => _error;
  DrivingData? get currentDriving => _currentDriving;
  DrivingEndData? get lastEndData => _lastEndData;
  List<Device> get devices => _devices;
  bool get isDriving => _currentDriving != null;
  bool get isDrivingByServer => _serverDriving;

  Stream<Map<String, dynamic>>? get messageStream => _socketService?.messageStream;

  Future<void> connect(AuthManager authManager) async {
    try {
      final accessToken = await authManager.getAccessToken();
      _socketService = SocketService(accessToken: accessToken);

      _socketService?.statusStream.listen((s) {
        _status = s;
        _error = null;
        notifyListeners();
      });

      _socketService?.messageStream.listen((message) {
        final type = message['type'];

        if (type == 'DRIVING:UPDATE') {
          try {
            final next = DrivingData.fromJson(message['data']);
            final prev = _currentDriving;

            _currentDriving = next;
            _serverDriving = true;

            final changed = prev == null ||
                prev.mileage != next.mileage ||
                prev.left    != next.left   ||
                prev.right   != next.right  ||
                prev.front   != next.front  ||
                prev.status  != next.status ||
                prev.endTime != next.endTime;

            if (changed) {
              debugPrint('[WS] DRIVING:UPDATE -> mileage=${next.mileage}, '
                  'gaze(l/c/r)=${next.left}/${next.front}/${next.right}, status=${next.status}');
              notifyListeners(); 
            }
          } catch (e) {
            debugPrint('DRIVING:UPDATE 디코드 실패: $e');
          }

        } else if (type == SocketConstants.drivingEnd) {
          try {
            final end = DrivingEndData.fromJson(message['data']);
            _lastEndData = end;
            _currentDriving = null;
            _serverDriving = false;
            debugPrint('[WS] DRIVING:END -> bias=${end.bias}, mileage=${end.mileage}');
            notifyListeners(); 
          } catch (e) {
            debugPrint('DRIVING:END 디코드 실패: $e');
          }
        }
      });

      await _socketService?.connect();

      _devices = await _socketService!.getDeviceList();
      _serverDriving = _devices.any((d) => d.status == true);
      notifyListeners();

    } catch (e) {
      _error = e.toString();
      _status = SocketConstants.error;
      notifyListeners();
      rethrow;
    }
  }
  Future<void> disconnect() async {
    try {
      await _socketService?.disconnect();
    } finally {
      _socketService = null;
      _status = SocketConstants.disconnected;
      notifyListeners();
    }
  }

  Future<DrivingData> startDriving(int deviceId) async {
    try {
      debugPrint('>> SEND WS START: deviceId=$deviceId');
      final data = await _socketService!.startDriving(deviceId);

      _currentDriving = data;
      _lastEndData = null;
      _error = null;
      _serverDriving = true;
      notifyListeners();
      return data;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<DrivingEndData> endDriving() async {
    final int deviceId =
        _currentDriving?.deviceId ?? (_devices.isNotEmpty ? _devices.first.deviceId : 1);

    try {
      debugPrint('>> SEND WS END: deviceId=$deviceId');
      final endData = await _socketService!.endDriving(deviceId);

      _lastEndData = endData;
      _currentDriving = null;
      _error = null;
      _serverDriving = false;
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
  Future<void> refreshServerDriving() async {
    if (_socketService == null) return;
    try {
      _devices = await _socketService!.getDeviceList();
      final driving = _devices.any((d) => d.status == true);
      if (driving != _serverDriving) {
        _serverDriving = driving;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
}
