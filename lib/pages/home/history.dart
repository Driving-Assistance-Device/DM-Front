import 'package:dm1/pages/exit.dart';
import 'package:dm1/pages/home/widgets/auth_guard.dart';
import 'package:dm1/pages/home/widgets/recommend.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth_manager.dart';
import '../../services/http/data.dart';
import '../../models/stats_data.dart';
import '../../models/driving.dart';
import 'widgets/calendar.dart';
import 'stats_detail.dart';
import '../home/widgets/bottom_navbar.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  Map<DateTime, List<DrivingStats>> _historyData = {};
  List<DrivingStats> _selectedDayTrips = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    final authManager = context.read<AuthManager>();
    final httpService = HttpService();

    try {
      final token = await authManager.getAccessToken();
      final resp = await httpService.getAllDriving(token);

      if (resp.success != null) {
        final List<DrivingRecord> records = resp.success!.drivings;

        final Map<DateTime, List<DrivingStats>> mapData = {};
        for (var record in records) {
          final dateKey = DateTime(
            record.startTime.year,
            record.startTime.month,
            record.startTime.day,
          );

          final l = (record.left ?? 0).toDouble();
          final r = (record.right ?? 0).toDouble();
          final c = (record.front ?? 0).toDouble();
          final sum = l + r + c;
          final gaze = sum > 0
              ? {
                  'left': l / sum * 100.0,
                  'center': c / sum * 100.0,
                  'right': r / sum * 100.0,
                }
              : {
                  'left': 0.0,
                  'center': 0.0,
                  'right': 0.0,
                };

          final lane = (record.bias ?? 0).toDouble();

          final recos = RecommendHelper.buildRecommendations(
            bias: (record.bias ?? 0),
            headway: (record.headway ?? 0),
            left: (record.left ?? 0),
            right: (record.right ?? 0),
            front: (record.front ?? 0),
          );

          final stats = DrivingStats(
            tripId: record.drivingId.toString(),
            date: record.startTime,
            duration: record.endTime.difference(record.startTime),
            distance: record.mileage,
            gazePercentages: gaze,
            recommendations: recos,
            laneDeparture: lane,
          );

          mapData.putIfAbsent(dateKey, () => []);
          mapData[dateKey]!.add(stats);
        }

        setState(() {
          _historyData = mapData;
          final today = DateTime.now();
          final normalizedToday = DateTime(today.year, today.month, today.day);
          _selectedDayTrips = _historyData[normalizedToday] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = '데이터를 불러오지 못했습니다';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<bool> _deleteTrip(DrivingStats trip) async {
    final drivingId = int.tryParse(trip.tripId);
    if (drivingId == null) return false;

    try {
      final authManager = context.read<AuthManager>();
      final httpService = HttpService();
      final token = await authManager.getAccessToken();

      final resp = await httpService.deleteDriving(token, drivingId);
      if (resp.resultType == 'SUCCESS') {
        final dayKey = DateTime(trip.date.year, trip.date.month, trip.date.day);

        setState(() {
          _historyData[dayKey]?.removeWhere((t) => t.tripId == trip.tripId);
          _selectedDayTrips.removeWhere((t) => t.tripId == trip.tripId);
          if ((_historyData[dayKey]?.isEmpty ?? false)) {
            _historyData.remove(dayKey);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('삭제 완료')),
          );
        }
        return true;
      } else {
        throw Exception(resp.error?.reason ?? '삭제 실패');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _confirmAndDelete(DrivingStats trip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _deleteTrip(trip);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitWrapper(
      child: AuthGuard(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('주행 기록'),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : Column(
                      children: [
                        HistoryCalendar(
                          historyData: _historyData,
                          onDaySelected: _handleDaySelected,
                        ),

                        Expanded(
                          child: _selectedDayTrips.isEmpty
                              ? const Center(child: Text('선택된 날짜에 기록이 없습니다'))
                              : ListView.builder(
                                  itemCount: _selectedDayTrips.length,
                                  itemBuilder: (context, index) {
                                    final trip = _selectedDayTrips[index];

                                    return Dismissible(
                                      key: ValueKey('driving_${trip.tripId}'),
                                      direction: DismissDirection.endToStart, 
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        color: const Color.fromARGB(255, 135, 147, 193).withOpacity(0.1),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Color.fromARGB(255, 10, 16, 93),
                                        ),
                                      ),
                                      confirmDismiss: (direction) async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('삭제 확인'),
                                            content: const Text('이 기록을 삭제하시겠습니까?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: const Text('취소'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: const Text('삭제', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (ok != true) return false;

                                        final ok2 = await _deleteTrip(trip);
                                        return ok2;
                                      },
                                      child: _buildTripCard(trip),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
          bottomNavigationBar: const BottomNavBar(selectedIndex: 1),
        ),
      ),
    );
  }

  void _handleDaySelected(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    setState(() {
      _selectedDayTrips = _historyData[normalizedDay] ?? [];
    });
  }

  Widget _buildTripCard(DrivingStats trip) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('주행 상세')),
              body: StatsDetailView(stats: trip),
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trip.formattedTime} • ${trip.formattedDistance}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '시선 분포: 좌 ${trip.gazePercentages['left']?.toStringAsFixed(1) ?? '0'}% '
                      '중 ${trip.gazePercentages['center']?.toStringAsFixed(1) ?? '0'}% '
                      '우 ${trip.gazePercentages['right']?.toStringAsFixed(1) ?? '0'}%',
                    ),
                    if (trip.laneDeparture != null) ...[
                      const SizedBox(height: 8),
                      Text('차선 이탈: ${trip.laneDeparture?.toStringAsFixed(1)}'),
                    ],
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color.fromARGB(255, 17, 8, 88)),
                  tooltip: '삭제',
                  onPressed: () => _confirmAndDelete(trip),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
