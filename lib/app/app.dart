import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/app_theme.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main_layout.dart';
import 'app_controller.dart';

class SalespersonApp extends StatelessWidget {
  const SalespersonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Bio Care Sales',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: context.select<AppController, ThemeMode>(
            (controller) => controller.resolvedThemeMode,
          ),
          home: Consumer<AppController>(
            builder: (context, controller, _) {
              if (!controller.initialized) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return controller.authenticated
                  ? const MainLayout()
                  : const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
