import 'package:flutter/material.dart';

import 'package:project/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:project/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:project/features/auth/domain/usecases/login_usecase.dart';
import 'package:project/features/auth/presentation/pages/login_page.dart';
import 'package:project/features/cliente/presentation/pages/registro_cliente_page.dart';

void main() {

  final dataSource = AuthMockDataSource();
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
      home: Scaffold(

        appBar: AppBar(

          title: const Text('Inicio'),

          actions: [

            IconButton(

              icon: const Icon(
                Icons.person_add,
              ),

              onPressed: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (context) =>
                        const RegistroClientePage(),
                  ),
                );
              },
            ),
          ],
        ),

        body: LoginPage(useCase: useCase),
      ),
    );
  }
}