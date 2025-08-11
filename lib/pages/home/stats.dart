import 'package:dm1/pages/exit.dart';
import 'package:dm1/pages/home/widgets/auth_guard.dart';
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

      if (resp.success != null) {
        final DrivingRecord record = resp.success!;

        Map<String, double> gaze = {'left': 0, 'center': 0, 'right': 0}; 
        final lHttp = (record.left ?? 0).toDouble();    
        final rHttp = (record.right ?? 0).toDouble();   
        final cHttp = (record.front ?? 0).toDouble();   
        final sumHttp = lHttp + rHttp + cHttp;          
        if (sumHttp > 0) {            
          gaze = {
            'left'  : (lHttp / sumHttp * 100.0).toDouble(),
            'center': (cHttp / sumHttp * 100.0).toDouble(),
            'right' : (rHttp / sumHttp * 100.0).toDouble(),
          };
       
        }           

        var stats = DrivingStats(
          tripId: record.drivingId.toString(),
          date: record.startTime,
          duration: record.endTime.difference(record.startTime),
          distance: record.mileage,
          gazePercentages: gaze,
          recommendations: [],
          laneDeparture: (record.bias ?? 0).toDouble(),
        );

        final end = socketManager.lastEndData;
        if (end != null) {

          final sameDay = record.startTime.day == end.startTime.day &&
              record.startTime.month == end.startTime.month &&
              record.startTime.year == end.startTime.year;

          if (sameDay) {
            if ((record.bias ?? 0) == 0) {               
              final lane = end.bias.toDouble();          
              stats = DrivingStats(    
                tripId: stats.tripId,
                date: stats.date,
                duration: stats.duration,
                distance: stats.distance,
                gazePercentages: stats.gazePercentages,
                recommendations: stats.recommendations,
                laneDeparture: lane,   
              );
            }

            if (sumHttp == 0) {        
              final l = end.left.toDouble();             
              final r = end.right.toDouble();            
              final c = end.front.toDouble();            
              final sum = (l + r + c); 
              final fallbackGaze = sum > 0
                ? {
                    'left': (l / sum * 100.0).toDouble(),
                    'center': (c / sum * 100.0).toDouble(),
                    'right': (r / sum * 100.0).toDouble(),
                  }
                : {'left': 0.0, 'center': 0.0, 'right': 0.0}; 

              stats = DrivingStats(    
                tripId: stats.tripId,
                date: stats.date,
                duration: stats.duration,
                distance: stats.distance,
                gazePercentages: fallbackGaze,           
                recommendations: stats.recommendations,
                laneDeparture: stats.laneDeparture,
              );
            }
          }
        }

        setState(() => _latestStats = stats);
      }
    } catch (e) {
      e.toString();
    } finally {
      setState(() => _loading = false);
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
