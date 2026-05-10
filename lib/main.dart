import 'package:flutter/material.dart';

import 'package:project/features/cliente/data/datasources/clientes_local_datasource.dart';
import 'package:project/features/cliente/data/repositories/clientes_repository_impl.dart';
import 'package:project/features/cliente/domain/usecases/get_clientes_usecase.dart';
import 'package:project/features/cliente/presentation/pages/clientes_page.dart';

void main() {

  final dataSource = ClientesLocalDataSource();
  final repository = ClientesRepositoryImpl(dataSource);
  final useCase = GetClientesUseCase(repository);

  runApp(MyApp(useCase: useCase));
}

class MyApp extends StatelessWidget {

  final GetClientesUseCase useCase;

  const MyApp({super.key, required this.useCase});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ClientesPage(useCase: useCase),
    );
  }
}