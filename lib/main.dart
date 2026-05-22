import 'package:flutter/material.dart';
import 'package:project/features/auth/data/datasources/auth_firebase_datasource.dart';
import 'package:project/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:project/features/auth/domain/usecases/login_usecase.dart';
import 'package:project/features/auth/presentation/pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);

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
      home: LoginPage(useCase: useCase),
    );
  }
}