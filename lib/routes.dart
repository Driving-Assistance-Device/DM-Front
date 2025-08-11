import 'package:flutter/material.dart';
import 'pages/login.dart';
import 'pages/signup.dart';
import 'pages/splashpage.dart';
import 'pages/home/driving.dart';
import 'pages/home/history.dart';
import 'pages/home/stats.dart';
import 'pages/home/profile/contents.dart';

class AppRoutes {
  static const String splash  = '/splash';
  static const String login   = '/login';
  static const String signup  = '/signup';
  static const String driving = '/home/driving';
  static const String history = '/home/history';
  static const String stats   = '/home/stats';
  static const String profile = '/home/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpPage());
      case driving:
        return MaterialPageRoute(builder: (_) => const DrivingPage());
      case history:
        return MaterialPageRoute(builder: (_) => const HistoryPage());
      case stats:
        return MaterialPageRoute(builder: (_) => const StatsPage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('해당 페이지를 찾지 못했습니다. (${settings.name})'),
            ),
          ),
        );
    }
  }
}
