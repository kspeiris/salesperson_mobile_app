import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/app_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final controller = AppController();
  
  // Start initialization without blocking the app startup
  controller.initialize();

  runApp(
    ChangeNotifierProvider<AppController>.value(
      value: controller,
      child: const SalespersonApp(),
    ),
  );
}
