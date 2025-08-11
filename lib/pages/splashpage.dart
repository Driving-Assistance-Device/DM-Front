import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_manager.dart';
import '../routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final authManager = context.read<AuthManager>();
    await authManager.init();
    if (authManager.isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.driving);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/dmlogo.png', height: 180),
      ),
    );
  }
}
