class DrivingStats {

String tripId; 
DateTime date; 
Duration duration; 
double distance; 
Map<String, double> gazePercentages; 
List<String> recommendations; 
double? laneDeparture; 

  DrivingStats({
    required this.tripId,
    required this.date,
    required this.duration,
    required this.distance,
    required this.gazePercentages,
    this.recommendations = const [],
    this.laneDeparture,
  });



  String get formattedTime {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}시간 ${minutes}분';
  }

  String get formattedDistance {
    return '${distance.toStringAsFixed(0)} km';
  }

  factory DrivingStats.fromApi(Map<String, dynamic> json) {
    return DrivingStats(
      tripId: json['trip_id'],
      date: DateTime.parse(json['date']),
      duration: Duration(minutes: json['duration_minutes']),
      distance: json['distance_km'].toDouble(),
      gazePercentages: Map<String, double>.from(json['gaze_distribution']),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}