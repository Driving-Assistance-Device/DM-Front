class Device {
  final int deviceId;
  final String code;
  final bool status;

  Device({
    required this.deviceId,
    required this.code,
    required this.status,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    bool normalizeStatus(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v == 1; // 1 운전중
      if (v is String) {
        final s = v.toLowerCase();
        return s == 'true' || s == '1';
      }
      return false;
    }

    return Device(
      deviceId: json['deviceId'],
      code: json['code'],
      status: normalizeStatus(json['status']),
    );
  }

}
