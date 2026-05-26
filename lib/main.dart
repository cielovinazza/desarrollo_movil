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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Future.microtask(() {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  });

  final dataSource = AuthFirebaseDataSource();
  final repository = AuthRepositoryImpl(dataSource);
  final useCase = LoginUseCase(repository);

  runApp(MyApp(useCase: useCase));
}

class MyApp extends StatelessWidget {
  final LoginUseCase useCase;

  const MyApp({super.key, required this.useCase});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

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
                return const InactivityDetector(child: MainNavigation());
              },
            );
          }

          return LoginPage(useCase: useCase);
        },
      ),
    );
  }
}
