class DrivingData {
  final int deviceId;
  final int status;
  final double mileage;
  final DateTime startTime;
  final DateTime? endTime;
  final int left;
  final int right;
  final int front;
  final DateTime createdAt;

  DrivingData({
    required this.deviceId,
    required this.status,
    required this.mileage,
    required this.startTime,
    this.endTime,
    required this.left,
    required this.right,
    required this.front,
    required this.createdAt,
  });

  factory DrivingData.fromJson(Map<String, dynamic> json) {
  double parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
  int parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
  DateTime parseDate(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (v is String && v.isNotEmpty) {
      final s = v.contains(' ') ? v.replaceFirst(' ', 'T') : v;
      return DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  return DrivingData(
    deviceId: parseInt(json['deviceId']),
    status: parseInt(json['status']),
    mileage: parseDouble(json['mileage']),
    startTime: parseDate(json['startTime']),
    endTime: json['endTime'] != null ? parseDate(json['endTime']) : null,
    left: parseInt(json['left']),
    right: parseInt(json['right']),
    front: parseInt(json['front']),
    createdAt: parseDate(json['createdAt']),
  );
}

  DrivingEndData toEndData({
    required double mileage,
    required DateTime endTime,
    required int bias,
    required int headway,
  }) {
    return DrivingEndData(
      deviceId: deviceId,
      status: 0, // 종료
      mileage: mileage,
      startTime: startTime,
      endTime: endTime,
      left: left,
      right: right,
      front: front,
      bias: bias,
      headway: headway,
      createdAt: createdAt,
    );
  }
}

class DrivingEndData extends DrivingData {
  final int bias;
  final int headway;

  DrivingEndData({
    required int deviceId,
    required int status,
    required double mileage,
    required DateTime startTime,
    required DateTime endTime,
    required int left,
    required int right,
    required int front,
    required DateTime createdAt,
    required this.bias,
    required this.headway,
  }) : super(
          deviceId: deviceId,
          status: status,
          mileage: mileage,
          startTime: startTime,
          endTime: endTime,
          left: left,
          right: right,
          front: front,
          createdAt: createdAt,
        );

  factory DrivingEndData.fromJson(Map<String, dynamic> json) {
  double parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
  int parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
  DateTime parseDate(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (v is String && v.isNotEmpty) {
      final s = v.contains(' ') ? v.replaceFirst(' ', 'T') : v;
      return DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  return DrivingEndData(
    deviceId: parseInt(json['deviceId']),
    status: parseInt(json['status']),
    mileage: parseDouble(json['mileage']),
    startTime: parseDate(json['startTime']),
    endTime: parseDate(json['endTime']),
    left: parseInt(json['left']),
    right: parseInt(json['right']),
    front: parseInt(json['front']),
    createdAt: parseDate(json['createdAt']),
    bias: parseInt(json['bias']),
    headway: parseInt(json['headway']),
  );
}

}
