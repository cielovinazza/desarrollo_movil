import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

import 'package:project/features/auth/data/datasources/auth_firebase_datasource.dart';
import 'package:project/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:project/features/auth/domain/usecases/login_usecase.dart';
import 'package:project/features/auth/presentation/pages/login_page.dart';

import 'package:project/shared/widgets/inactivity_detector.dart';
import 'package:project/navigation/main_navigation.dart';
import 'shared/design_system/app_theme.dart';
import 'package:project/core/network/connectivity_sync_service.dart';

late final ConnectivitySyncService _syncService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final dataSource = AuthFirebaseDataSource();
  final repository = AuthRepositoryImpl(dataSource);
  final useCase = LoginUseCase(repository);

  _syncService = ConnectivitySyncService();
  await _syncService.iniciar();

  runApp(MyApp(useCase: useCase));
}

class MyApp extends StatefulWidget {
  final LoginUseCase useCase;

  const MyApp({super.key, required this.useCase});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncService.sincronizarPendientes();
    }
  }

  void cambiarTema(bool oscuro) {
    setState(() {
      _themeMode = oscuro ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return FutureBuilder(
              future: Future.delayed(const Duration(milliseconds: 500)),
              builder: (context, delaySnapshot) {
                if (delaySnapshot.connectionState != ConnectionState.done) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                return InactivityDetector(
                  child: MainNavigation(
                    isDarkMode: _themeMode == ThemeMode.dark,
                    onThemeChanged: cambiarTema,
                  ),
                );
              },
            );
          }

          return LoginPage(useCase: widget.useCase);
        },
      ),
    );
  }
}
