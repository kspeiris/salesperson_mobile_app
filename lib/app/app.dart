import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import 'app_controller.dart';

class SalespersonApp extends StatelessWidget {
  const SalespersonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Salesperson Daily Recorder',
      theme: AppTheme.lightTheme,
      home: Consumer<AppController>(
        builder: (context, controller, _) {
          if (!controller.initialized) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return controller.authenticated ? const DashboardScreen() : const LoginScreen();
        },
      ),
    );
  }
}
