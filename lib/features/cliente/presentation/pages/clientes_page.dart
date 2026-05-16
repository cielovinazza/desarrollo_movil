import 'package:flutter/material.dart';
import '../../domain/entities/cliente.dart';
import '../../../../core/di/injection.dart';
import 'registro_cliente_page.dart';


class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {

  late Future<List<Cliente>> _future;

  @override
  void initState() {
    super.initState();
    _future = getClientesUseCase();
  }

  void _recargar() {
    setState(() {
      _future = getClientesUseCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Clientes")),

      body: FutureBuilder<List<Cliente>>(
        future: _future,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final clientes = snapshot.data ?? [];

          if (clientes.isEmpty) {
            return const Center(child: Text("No hay clientes"));
          }

          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];

              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(cliente.nombre),
                subtitle: Text(cliente.rut),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RegistroClientePage(),
            ),
          );

          _recargar();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}