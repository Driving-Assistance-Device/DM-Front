import 'package:flutter/material.dart';

class GazeStats extends StatelessWidget {
  final Map<String, double> gaze;

  const GazeStats({
    super.key,
    required this.gaze,
  });

  @override
  Widget build(BuildContext context) {
    final left = gaze['left'] ?? 0.0;
    final center = gaze['center'] ?? 0.0;
    final right = gaze['right'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const Text(
            '시선 방향 통계',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // color bar
          _buildPercentageBar(left, center, right),
          const SizedBox(height: 16),

          // text box
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGazeIndicator('좌측', left, _getSideColor(left)),
              _buildGazeIndicator('중앙', center, _getCenterColor(center)),
              _buildGazeIndicator('우측', right, _getSideColor(right)),
            ],
          ),
        ],
      ),
    );
  }

  // colorbar
  Widget _buildPercentageBar(double left, double center, double right) {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[200],
      ),
      child: Row(
        children: [
          Expanded(
            flex: left.round().clamp(0, 100),
            child: Container(
              decoration: BoxDecoration(
                color: _getSideColor(left),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            flex: center.round().clamp(0, 100),
            child: Container(
              color: _getCenterColor(center),
            ),
          ),
          Expanded(
            flex: right.round().clamp(0, 100),
            child: Container(
              decoration: BoxDecoration(
                color: _getSideColor(right),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 양측
  Color _getSideColor(double percentage) {
    if (percentage < 10) return Colors.red;
    if (percentage < 20) return Colors.orange;
    return Colors.blue;
  }

  // 중앙
  Color _getCenterColor(double percentage) {
    if (percentage < 30 || percentage > 70) return Colors.red;
    return Colors.blue;
  }

  // indicator
  Widget _buildGazeIndicator(String label, double percentage, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(45),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
