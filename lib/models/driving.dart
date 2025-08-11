class DrivingRecord {
  final int drivingId;
  final double mileage;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime createdAt;

  final int? headway;
  final int? bias;
  final int? left;
  final int? right;
  final int? front;

  DrivingRecord({
    required this.drivingId,
    required this.mileage,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    this.headway,
    this.bias,
    this.left,
    this.right,
    this.front,
  });

  factory DrivingRecord.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (v is String && v.isNotEmpty) {
        final s = v.contains(' ') ? v.replaceFirst(' ', 'T') : v;
        return DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    int? parseIntOrNull(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return DrivingRecord(
      drivingId: json['drivingId'],
      mileage: parseDouble(json['mileage']),
      startTime: parseDate(json['startTime']),
      endTime: parseDate(json['endTime']),
      createdAt: parseDate(json['createdAt']),
      headway: parseIntOrNull(json['headway']),
      bias: parseIntOrNull(json['bias']),
      left: parseIntOrNull(json['left']),
      right: parseIntOrNull(json['right']),
      front: parseIntOrNull(json['front']),
    );
  }
}


class DrivingTotalResponse {
  final String userName;
  final List<DrivingRecord> drivings;

  DrivingTotalResponse({
    required this.userName,
    required this.drivings,
  });

  factory DrivingTotalResponse.fromJson(dynamic json) {
    if (json is List) {
      return DrivingTotalResponse(
        userName: '',
        drivings: json.map((e) => DrivingRecord.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } else if (json is Map<String, dynamic>) {
      final list = (json['drivings'] as List?) ?? const [];
      return DrivingTotalResponse(
        userName: (json['user'] != null && json['user'] is Map && json['user']['name'] != null)
            ? json['user']['name'] as String
            : '',
        drivings: list.map((e) => DrivingRecord.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } else {
      return DrivingTotalResponse(userName: '', drivings: const []);
    }
  }
}

class DrivingTotalCount {
  final double totalDistance;
  final int count;

  DrivingTotalCount({
    required this.totalDistance,
    required this.count,
  });

  factory DrivingTotalCount.fromJson(Map<String, dynamic> json) {
    return DrivingTotalCount(
      totalDistance: json['totalDistance'].toDouble(),
      count: json['count'],
    );
  }
}


//recommend
class UserRecommendation {
  final String recommend1;
  final String recommend2;
  final String recommend3;

  UserRecommendation({
    required this.recommend1,
    required this.recommend2,
    required this.recommend3,
  });

  factory UserRecommendation.fromJson(Map<String, dynamic> json) {
    return UserRecommendation(
      recommend1: json['recommend1'],
      recommend2: json['recommend2'],
      recommend3: json['recommend3'],
    );
  }
}