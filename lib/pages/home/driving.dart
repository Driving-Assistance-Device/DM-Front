import 'dart:async';
import 'package:dm1/pages/exit.dart';
import 'package:dm1/pages/home/widgets/auth_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:dm1/auth_manager.dart';
import 'package:dm1/models/user.dart';
import 'package:dm1/services/wsocket/constants.dart';
import '../../socket_manager.dart';
import 'widgets/action_button.dart';
import 'widgets/bottom_navbar.dart';

class DrivingPage extends StatefulWidget {
  const DrivingPage({super.key});

  @override
  State<DrivingPage> createState() => _DrivingPageState();
}

class _DrivingPageState extends State<DrivingPage> {
  Map<String, dynamic> _drivingData = {'time': '00:00:00'};

  Timer? _drivingTimer;
  DateTime? _startTime;

  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final socketManager = context.read<SocketManager>();
      final authManager = context.read<AuthManager>();

      if (socketManager.status == SocketConstants.disconnected) {
        try {
          await socketManager.connect(authManager);
        } catch (_) {}
      }

      final ls = socketManager.lastStatus;
      if ((ls == 1 || ls == 2) && socketManager.currentDriving != null) {
        _restoreTimerFromServer(socketManager.currentDriving!.startTime);
      }
    });
  }

  @override
  void dispose() {
    _drivingTimer?.cancel();
    super.dispose();
  }

  void _restoreTimerFromServer(DateTime serverStart) {
    _startTime = serverStart;
    _startTimer();
    setState(() {
      _drivingData['time'] = _formatDuration(_safeElapsed());
    });
  }

  void _startTimer() {
    _drivingTimer?.cancel();
    _drivingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _drivingData['time'] = _formatDuration(_safeElapsed());
      });
    });
  }

  Future<void> _startDriving(SocketManager socketManager) async {
    if (_isAnalyzing) return;

    final int? deviceId = socketManager.currentDeviceId;
    if (deviceId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('디바이스가 없습니다.')),
      );
      return;
    }

    try {
      final driving = await socketManager.startDriving(deviceId);
      _restoreTimerFromServer(driving.startTime);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('운전 시작')),
      );
    } catch (e) {
      _drivingTimer?.cancel();
      _startTime = null;
      setState(() => _drivingData['time'] = '00:00:00');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('운전 시작 실패: $e')),
      );
    }
  }

  void _showAnalyzingDialog() {
    if (_isAnalyzing) return;
    setState(() => _isAnalyzing = true);

    showGeneralDialog(
      context: context,
      barrierLabel: 'analyzing',
      barrierDismissible: false,
      barrierColor: Colors.black54,
      pageBuilder: (_, __, ___) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    '분석중입니다...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _hideAnalyzingDialog() {
    if (_isAnalyzing && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (mounted) {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _endDriving(SocketManager socketManager) async {
    if (_isAnalyzing) return;
    _showAnalyzingDialog();

    try {
      await socketManager.endDriving();

      _drivingTimer?.cancel();
      _startTime = null;
      setState(() => _drivingData['time'] = '00:00:00');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('운전 종료 완료')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('운전 종료 실패: $e')),
      );
    } finally {
      _hideAnalyzingDialog();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home/stats');
      }
    }
  }

  Duration _safeElapsed() {
    if (_startTime == null) return Duration.zero;
    final now = DateTime.now();
    if (now.isBefore(_startTime!)) return Duration.zero;
    return now.difference(_startTime!);
  }

  String _formatDuration(Duration duration) {
    final hh = duration.inHours.toString().padLeft(2, '0');
    final mm = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  Widget _wsStatusTitle(BuildContext context) {
    final status = context.watch<SocketManager>().status;
    final tuple = _wsStatusDisplay(status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(color: tuple.$2, shape: BoxShape.circle),
        ),
        Text(tuple.$1, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  (String, Color) _wsStatusDisplay(String status) {
    switch (status) {
      case SocketConstants.connected:
        return ('WS 연결됨', Colors.green);
      case SocketConstants.connecting:
        return ('연결 중…', Colors.orange);
      case SocketConstants.error:
        return ('오류', Colors.red);
      case SocketConstants.disconnected:
      default:
        return ('미연결', Colors.grey);
    }
  }

  Future<bool> confirmExit(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('앱 종료'),
        content: const Text('정말 종료하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('종료', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (result == true) {
      SystemNavigator.pop();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final socketManager = context.watch<SocketManager>();
    final authManager = context.read<AuthManager>();

    final bool wsConnected = socketManager.status == SocketConstants.connected;
    final int? lastStatus = socketManager.lastStatus;           // 0/1/2/null
    final bool uiDriving = (lastStatus == 1 || lastStatus == 2);

    final driving = socketManager.currentDriving;
    final distanceText = driving != null
        ? '${driving.mileage.toStringAsFixed(1)} km'
        : '0 km';

    if (uiDriving && driving != null && _startTime == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreTimerFromServer(driving.startTime);
      });
    }
    if (!uiDriving && _startTime != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _drivingTimer?.cancel();
        _startTime = null;
        setState(() => _drivingData['time'] = '00:00:00');
      });
    }

    final int? deviceIdCandidate = socketManager.currentDeviceId;
    final bool hasDevice = deviceIdCandidate != null;

    final bool startEnabled = uiDriving
        ? true
        : (wsConnected && hasDevice && lastStatus == 0 && !_isAnalyzing);

    String? disabledHint;
    if (!uiDriving && !startEnabled) {
      if (!wsConnected) {
        disabledHint = 'WS 연결 중입니다...';
      } else if (!hasDevice && socketManager.noStatusWindowElapsed) {
        disabledHint = '디바이스가 연결되지 않았습니다';
      } else {
        disabledHint = '서버 상태 동기화 중입니다...';
      }
    }

    return ConfirmExitWrapper(
      child: AuthGuard(
        child: Scaffold(
          appBar: AppBar(
            leading: Opacity(
              opacity: 0,
              child: IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
            ),
            title: _wsStatusTitle(context),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  final sm = context.read<SocketManager>();
                  final am = context.read<AuthManager>();
                  try { await sm.disconnect(); } catch (_) {}
                  try {
                    await sm.connect(am);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('WS 재연결 시도')),
                    );
                  } catch (e) {
                    final more = sm.error ?? e.toString();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('재연결 실패: $more')),
                    );
                  }
                },
                tooltip: 'WS 재연결',
              ),
            ],
          ),
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 70),
                Column(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 50, color: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<User>(
                      future: authManager.getUserProfile(),
                      builder: (context, snapshot) {
                        final userName = snapshot.hasData ? snapshot.data!.name : '사용자';
                        return Text(
                          '$userName 님 안전운행하세요',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 70),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('주행시간:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text(
                            _drivingData['time'] ?? '00:00:00',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          const Text('주행거리:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text(
                            distanceText,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 50),

                      ActionButton(
                        text: uiDriving ? '운전종료' : '운전시작',
                        icon: uiDriving ? Icons.stop : Icons.play_arrow,
                        color: uiDriving ? Colors.red : const Color.fromARGB(255, 5, 68, 107),
                        enabled: startEnabled,
                        onPressed: () {
                          if (_isAnalyzing) return;
                          if (uiDriving) {
                            _endDriving(socketManager);
                          } else {
                            if (deviceIdCandidate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('디바이스가 없습니다.')),
                              );
                              return;
                            }
                            _startDriving(socketManager);
                          }
                        },
                      ),

                      if (disabledHint != null) ...[
                        const SizedBox(height: 12),
                        Text(disabledHint, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          bottomNavigationBar: const BottomNavBar(selectedIndex: 0),
        ),
      ),
    );
  }
}
