import 'package:flutter/material.dart';
import '../../models/stats_data.dart';
import '../../pages/home/widgets/lanecard.dart';
import 'widgets/stat_card.dart';
import 'widgets/gaze_stats.dart';

class StatsDetailView extends StatelessWidget {
  final DrivingStats stats;

  const StatsDetailView({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasGaze = stats.gazePercentages.isNotEmpty;
    final bool hasLane = stats.laneDeparture != null;
    final Map<String, double> gaze = hasGaze
        ? stats.gazePercentages
        : const {'left': 0.0, 'center': 0.0, 'right': 0.0};
    final double laneValue =
        ((stats.laneDeparture ?? 0).clamp(-50.0, 50.0)).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          StatCard(
            title: '주행 요약',
            child: Column(
              children: [
                _buildInfoRow('날짜', _formatDate(stats.date)),
                _buildInfoRow('주행 시간', stats.formattedTime),
                _buildInfoRow('주행 거리', stats.formattedDistance),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 시선 분포
          StatCard(
            title: '시선 분포 분석',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GazeStats(gaze: gaze),
                if (!hasGaze) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '데이터 없음 (기본값 0%)',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 차선 분석
          StatCard(
            title: '차선 분석',
            child: Column(
              children: [
                const SizedBox(height: 10),
                LaneIndicator(
                  value: laneValue,
                  width: MediaQuery.of(context).size.width * 0.9,
                ),
                if (!hasLane) ...[
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '데이터 없음 (기본값 0)',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 개선 권장사항 null => “데이터 없음”
          StatCard(
            title: '개선 권장사항',
            child: SizedBox(
              width: double.infinity,
              child: stats.recommendations.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: stats.recommendations
                          .map((text) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text('• $text'),
                              ))
                          .toList(),
                    )
                  : const Text(
                      '데이터 없음',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
