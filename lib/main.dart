import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  await controller.initialize();
  runApp(
    ChangeNotifierProvider<AppController>.value(
      value: controller,
      child: const SalespersonApp(),
    ),
  );
}
