// lib/features/cliente/presentation/pages/listado_cliente_page.dart

import 'package:flutter/material.dart';
import 'editar_cliente_page.dart';
// Importa tu página de registro si tienes el botón de agregar
// import 'registro_cliente_page.dart'; 

import '../../data/repositories/cliente_repository_impl.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/usecases/listar_clientes.dart';
import '../../data/datasources/clientes_local_datasource.dart';

class ListadoClientesPage extends StatefulWidget {
  const ListadoClientesPage({super.key});

  @override
  State<ListadoClientesPage> createState() => _ListadoClientesPageState();
}

class _ListadoClientesPageState extends State<ListadoClientesPage> {
  // Definimos las capas siguiendo tu arquitectura
  late final ListarClientes listarClientesUseCase;
  List<Cliente> clientes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    
    // Inicializamos las dependencias
    // Gracias al Singleton en ClientesLocalDataSource(), 
    // todas las páginas compartirán los mismos datos.
   listarClientesUseCase = ListarClientes(
    ClienteRepositoryImpl(ClientesLocalDataSource()),
  );
    cargarClientes();
  }

  Future<void> cargarClientes() async {
    setState(() => cargando = true);
    
    final resultado = await listarClientesUseCase();

    setState(() {
      clientes = resultado;
      cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de clientes'),
        centerTitle: true,
        actions: [
          // Botón para refrescar manualmente si quieres
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarClientes,
          )
        ],
      ),

      body: cargando 
          ? const Center(child: CircularProgressIndicator())
          : clientes.isEmpty
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
                          // Al volver de editar, recargamos la lista
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditarClientePage(cliente: cliente),
                            ),
                          );
                          cargarClientes();
                        },
                      ),
                    );
                  },
                ),
      
      // Si tienes un FloatingActionButton para registrar:
      /*
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/registro-cliente');
          cargarClientes(); // Recarga la lista con el nuevo cliente
        },
        child: const Icon(Icons.add),
      ),
      */
    );
  }
}