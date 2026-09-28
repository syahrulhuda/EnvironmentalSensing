import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EnvironmentalSensingApp());
}

/// Root Application Widget untuk Smart Environmental Sensing System (ESS)
class EnvironmentalSensingApp extends StatelessWidget {
  const EnvironmentalSensingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Environmental Sensing (ESS)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}
