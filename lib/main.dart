import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_manager.dart';
import 'socket_manager.dart';
import 'routes.dart';
import 'pages/exit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authManager = AuthManager();
  await authManager.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthManager>.value(value: authManager),
        ChangeNotifierProvider<SocketManager>(
          create: (_) => SocketManager(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driving manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
      builder: (context, child) => ConfirmExitWrapper(child: child!),
    );
  }
}
