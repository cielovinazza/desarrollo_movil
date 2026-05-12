import 'package:flutter/material.dart';
import '../../domain/usecases/get_clientes_usecase.dart';
import '../../domain/entities/clientes_entity.dart';

class ClientesPage extends StatelessWidget {

  final GetClientesUseCase useCase;

  const ClientesPage({super.key, required this.useCase});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Clientes"),
      ),
      body: FutureBuilder<List<Cliente>>(
        future: useCase(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error cargando clientes"));
          }

          final clientes = snapshot.data ?? [];

          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {

              final cliente = clientes[index];

              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(cliente.nombre),
                subtitle: Text("ID: ${cliente.id}"),
              );
            },
          );
        },
      ),
    );
  }
}