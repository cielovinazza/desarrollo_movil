import 'package:flutter/material.dart';

import 'editar_cliente_page.dart';

import '../../data/repositories/cliente_repository_impl.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/usecases/listar_clientes.dart';

class ListadoClientesPage extends StatefulWidget {
  const ListadoClientesPage({super.key});

  @override
  State<ListadoClientesPage> createState() =>
      _ListadoClientesPageState();
}

class _ListadoClientesPageState
    extends State<ListadoClientesPage> {
  late final ListarClientes listarClientesUseCase;

  List<Cliente> clientes = [];

  @override
  void initState() {
    super.initState();

    listarClientesUseCase =
        ListarClientes(ClienteRepositoryImpl());

    cargarClientes();
  }

  Future<void> cargarClientes() async {
    final resultado = await listarClientesUseCase();

    setState(() {
      clientes = resultado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de clientes'),
        centerTitle: true,
      ),

      body: clientes.isEmpty
          ? const Center(
              child: Text('No hay clientes registrados'),
            )

          : ListView.builder(
              padding: const EdgeInsets.all(16),

              itemCount: clientes.length,

              itemBuilder: (context, index) {
                final cliente = clientes[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),

                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),

                    title: Text(
                      cliente.nombre,

                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      'RUT: ${cliente.rut}\n'
                      'Correo: ${cliente.correo}\n'
                      'Teléfono: ${cliente.telefono}\n'
                      'Dirección: ${cliente.direccion ?? "Sin dirección"}',
                    ),

                    isThreeLine: true,

                    onTap: () async {
                      await Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) =>
                              EditarClientePage(
                                cliente: cliente,
                              ),
                        ),
                      );

                      cargarClientes();
                    },
                  ),
                );
              },
            ),
    );
  }
}