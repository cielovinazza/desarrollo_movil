// lib/features/cliente/presentation/pages/editar_cliente_page.dart

import 'package:flutter/material.dart';
import '../../data/repositories/cliente_repository_impl.dart';
import '../../domain/entities/cliente.dart';
import '../../data/datasources/clientes_local_datasource.dart';

class EditarClientePage extends StatefulWidget {
  final Cliente cliente;

  const EditarClientePage({
    super.key,
    required this.cliente,
  });

  @override
  State<EditarClientePage> createState() => _EditarClientePageState();
}

class _EditarClientePageState extends State<EditarClientePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nombreController;
  late TextEditingController rutController;
  late TextEditingController correoController;
  late TextEditingController telefonoController;
  late TextEditingController direccionController;

  @override
  void initState() {
    super.initState();

    nombreController = TextEditingController(text: widget.cliente.nombre);
    rutController = TextEditingController(text: widget.cliente.rut);
    correoController = TextEditingController(text: widget.cliente.correo);
    telefonoController = TextEditingController(text: widget.cliente.telefono);
    direccionController = TextEditingController(
      text: widget.cliente.direccion ?? '',
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    rutController.dispose();
    correoController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    super.dispose();
  }

  Future<void> guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final clienteActualizado = Cliente(
      id: widget.cliente.id,
      nombre: nombreController.text.trim(),
      rut: rutController.text.trim(),
      correo: correoController.text.trim(),
      telefono: telefonoController.text.trim(),
      direccion: direccionController.text.trim().isEmpty
          ? null
          : direccionController.text.trim(),
    );

    // SOLUCIÓN ERROR 1: Dejamos el constructor del DataSource vacío ya que es un Singleton
    final repo = ClienteRepositoryImpl(ClientesLocalDataSource());
    await repo.editarCliente(clienteActualizado);

    // SOLUCIÓN ADVERTENCIA 2 y 3 (use_build_context_synchronously):
    // Verificamos si el widget sigue montado en el árbol antes de usar el 'context'
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cliente actualizado correctamente'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar cliente'),
      ),
      body: SingleChildScrollView( // Agregado para evitar errores de desborde de pantalla con el teclado
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: rutController,
                decoration: const InputDecoration(
                  labelText: 'RUT',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: guardarCambios,
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}