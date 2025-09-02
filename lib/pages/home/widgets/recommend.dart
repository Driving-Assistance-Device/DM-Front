import 'package:dm1/models/trip.dart';

class RecommendHelper {
  static double frontPercent(int left, int right, int front) {
    final sum = left + right + front;
    if (sum <= 0) return 0.0;
    return (front * 100.0) / sum;
  }

  static String biasAdvice(num bias) {
    if (bias >= -5 && bias <= 5) {
      return '차선 중앙으로 안정적으로 주행하고 있습니다.';
    } else if (bias >= -10 && bias < -5) {
      return '약간 왼쪽으로 치우쳐 주행하고 있습니다.';
    } else if (bias > 5 && bias <= 10) {
      return '약간 오른쪽으로 치우쳐 주행하고 있습니다.';
    } else if (bias >= -50 && bias < -10) {
      return '왼쪽으로 크게 치우쳐 주행하고 있어 개선이 필요합니다.';
    } else if (bias > 10 && bias <= 50) {
      return '오른쪽으로 크게 치우쳐 주행하고 있어 개선이 필요합니다.';
    }
    if (bias < -50) return '왼쪽으로 매우 크게 치우쳐 주행하고 있어 즉시 개선이 필요합니다.';
    if (bias > 50)  return '오른쪽으로 매우 크게 치우쳐 주행하고 있어 즉시 개선이 필요합니다.';
    return '차선 유지 상태를 확인하세요.';
  }

  static String headwayAdvice(int headway) {
    switch (headway) {
      case 0:
        return '차간거리를 적정하게 유지하고 있습니다.';
      case 1:
        return '차간거리가 다소 가깝습니다.';
      case 2:
        return '차간거리가 매우 가까워 안전을 위해 조정이 필요합니다.';
      default:
        return '차간거리 정보를 확인할 수 없습니다.';
    }
  }

  static String gazeAdviceFromFrontPercent(double frontPct) {
    if (frontPct >= 85 && frontPct <= 100) {
      return '정면을 오래 주시하고 있습니다. 좌/우를 더 자주 확인해주세요.';
    } else if (frontPct >= 63 && frontPct <= 84) {
      return '시선 분배가 좋습니다. 현재 패턴을 유지해주세요.';
    } else if (frontPct >= 0 && frontPct <= 62) {
      return '정면 주시 비율이 다소 낮습니다. 전방 주시 시간을 조금만 늘려주세요.';
    }
    return '시선 정보가 올바르지 않습니다.';
  }

  static List<String> buildRecommendations({
    required num bias,
    required int headway,
    required int left,
    required int right,
    required int front,
  }) {
    final frontPct = frontPercent(left, right, front);
    return [
      biasAdvice(bias),
      headwayAdvice(headway),
      gazeAdviceFromFrontPercent(frontPct),
    ];
  }

  static List<String> fromDrivingEndData(DrivingEndData end) {
    return buildRecommendations(
      bias: end.bias,
      headway: end.headway,
      left: end.left,
      right: end.right,
      front: end.front,
    );
  }
}
