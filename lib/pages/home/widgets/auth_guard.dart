import 'package:dm1/auth_manager.dart';
import 'package:dm1/routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthManager>();

    if (!auth.isLoggedIn) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      });
      return const SizedBox.shrink();
    }

    return child;
  }
}
