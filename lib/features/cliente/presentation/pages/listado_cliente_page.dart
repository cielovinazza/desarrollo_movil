import 'package:flutter/material.dart';
import '../../data/datasources/clientes_remote_datasource.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editar_cliente_page.dart';

import '../../data/repositories/cliente_repository_impl.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/usecases/listar_clientes.dart';

class ListadoClientesPage extends StatefulWidget {
  const ListadoClientesPage({super.key});

  @override
  State<ListadoClientesPage> createState() => _ListadoClientesPageState();
}

class _ListadoClientesPageState extends State<ListadoClientesPage> {
  late final ListarClientes listarClientesUseCase;
  final repository = ClienteRepositoryImpl(ClientesRemoteDataSource(FirebaseFirestore.instance));

  final TextEditingController _buscadorController = TextEditingController();

  List<Cliente> clientes = [];
  List<Cliente> clientesFiltrados = [];

  @override
  void initState() {
    super.initState();

    listarClientesUseCase = ListarClientes(repository);

    cargarClientes();

    _buscadorController.addListener(_filtrarClientes);
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  Future<void> cargarClientes() async {
    final resultado = await listarClientesUseCase();

    setState(() {
      clientes = resultado;
      clientesFiltrados = resultado;
    });
  }

  void _filtrarClientes() {
    final textoBusqueda = _buscadorController.text.toLowerCase().trim();

    setState(() {
      if (textoBusqueda.isEmpty) {
        clientesFiltrados = clientes;
      } else {
        clientesFiltrados = clientes.where((cliente) {
          final nombre = cliente.nombre.toLowerCase();
          final rut = cliente.rut.toLowerCase();

          return nombre.contains(textoBusqueda) || rut.contains(textoBusqueda);
        }).toList();
      }
    });
  }

  Future<void> _abrirEditarCliente(Cliente cliente) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditarClientePage(cliente: cliente)),
    );

    await cargarClientes();
    _filtrarClientes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de clientes'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _buscadorController,
              decoration: InputDecoration(
                labelText: 'Buscar cliente',
                hintText: 'Buscar por RUT o nombre',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscadorController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscadorController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: clientes.isEmpty
                  ? const Center(child: Text('No hay clientes registrados'))
                  : clientesFiltrados.isEmpty
                  ? const Center(child: Text('No se encontraron clientes'))
                  : ListView.builder(
                      itemCount: clientesFiltrados.length,
                      itemBuilder: (context, index) {
                        final cliente = clientesFiltrados[index];

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
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _abrirEditarCliente(cliente),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
