class ApiConstants {
  static const String baseUrl = 'https://api.driving.p-e.kr';
  static const String wsUrl = 'wss://api.driving.p-e.kr/ws';
  
  static const String signUp = '/v1/api/auth/signup';
  static const String signIn = '/v1/api/auth/signin';
  static const String signOut = '/v1/api/auth/signout';
  static const String refreshToken = '/v1/api/auth/refresh';
  static const String protected = '/v1/api/auth/protected';
  
  // 사용자
  static const String userProfile = '/v1/api/user';
  static const String userRecommend = '/v1/api/user/recommend';
  
  // 운전데이터
  static const String latestDriving = '/v1/api/driving/';
  static const String totalDriving = '/v1/api/driving/total';
  static const String drivingCount = '/v1/api/driving/total/count';
  
  // 헤더
  static const Map<String, String> jsonHeader = {
    'Content-Type': 'application/json'
  };
  
  static Map<String, String> authHeader(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token'
  };
}