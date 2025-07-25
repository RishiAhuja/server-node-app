import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/themes/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/ssh/views/ssh_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SSHClientApp());
}

class SSHClientApp extends StatelessWidget {
  const SSHClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SSHScreen(),
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
