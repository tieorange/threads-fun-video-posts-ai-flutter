import 'package:flutter/material.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  initCubits();
  runApp(const FunnyThreadsApp());
}

class FunnyThreadsApp extends StatelessWidget {
  const FunnyThreadsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Funny Threads AI',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
