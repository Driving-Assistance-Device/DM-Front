import 'package:dm1/models/trip.dart';
import 'package:dm1/pages/exit.dart';
import 'package:dm1/pages/home/widgets/auth_guard.dart';
import 'package:dm1/pages/home/widgets/recommend.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/stats_data.dart';
import '../../models/driving.dart';
import '../../auth_manager.dart';
import '../../services/http/data.dart';
import 'stats_detail.dart';
import '../home/widgets/bottom_navbar.dart';
import '../../socket_manager.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  DrivingStats? _latestStats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLatestStats();
  }

  Future<void> _loadLatestStats() async {
    final authManager = context.read<AuthManager>();
    final httpService = HttpService();
    final socketManager = context.read<SocketManager>();

    try {
      final token = await authManager.getAccessToken();
      final resp = await httpService.getLatestDriving(token);

      if (resp.success == null) {
        setState(() => _latestStats = null);
        return;
      }

      final DrivingRecord record = resp.success!;

      final DrivingEndData? end = socketManager.lastEndData;
      bool sameDayAsEnd = false;
      if (end != null) {
        sameDayAsEnd =
            end.startTime.year == record.startTime.year &&
            end.startTime.month == record.startTime.month &&
            end.startTime.day == record.startTime.day;
      }

      final int finalLeft  = (record.left  ?? (sameDayAsEnd ? end?.left  : null))  ?? 0;
      final int finalRight = (record.right ?? (sameDayAsEnd ? end?.right : null)) ?? 0;
      final int finalFront = (record.front ?? (sameDayAsEnd ? end?.front : null)) ?? 0;

      final double finalBias = (record.bias ?? (sameDayAsEnd ? end?.bias : null) ?? 0).toDouble();
      final int finalHeadway = (record.headway ?? (sameDayAsEnd ? end?.headway : null) ?? 0);

      final double distance = record.mileage;
      final Duration duration = record.endTime.difference(record.startTime);

      Map<String, double> gazePercent = {'left': 0, 'center': 0, 'right': 0};
      final double sum = (finalLeft + finalRight + finalFront).toDouble();
      if (sum > 0) {
        gazePercent = {
          'left'  : finalLeft  / sum * 100.0,
          'center': finalFront / sum * 100.0,
          'right' : finalRight / sum * 100.0,
        };
      }

      final recos = RecommendHelper.buildRecommendations(
        bias: finalBias,
        headway: finalHeadway,
        left: finalLeft,
        right: finalRight,
        front: finalFront,
      );

      final stats = DrivingStats(
        tripId: record.drivingId.toString(),
        date: record.startTime,
        duration: duration,
        distance: distance,
        gazePercentages: gazePercent,
        recommendations: recos,
        laneDeparture: finalBias,
      );

      setState(() => _latestStats = stats);
    } catch (e) {
      setState(() => _latestStats = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitWrapper(
      child: AuthGuard(
        child: PopScope(
          canPop: true,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop) {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('최근 주행 기록'),
              centerTitle: true,
              automaticallyImplyLeading: false,
            ),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : _latestStats != null
                    ? StatsDetailView(stats: _latestStats!)
                    : _buildEmptyState(),
            bottomNavigationBar: const BottomNavBar(selectedIndex: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.directions_car, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '최근 주행 기록이 없습니다',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
