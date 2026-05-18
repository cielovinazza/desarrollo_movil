import 'package:flutter/material.dart';
import 'package:project/features/auth/presentation/pages/login_page.dart';
import 'package:project/core/di/injection.dart';
import 'package:project/shared/design_system/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema de Cotizaciones',
      theme: AppTheme.lightTheme,
      home: LoginPage(useCase: loginUseCase),
    );
  }
}