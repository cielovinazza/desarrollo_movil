import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/features/cliente/data/datasources/clientes_remote_datasource.dart';
import 'package:project/features/cliente/data/repositories/cliente_repository_impl.dart';
import 'package:project/features/cliente/domain/entities/cliente.dart';
import 'package:project/features/cliente/domain/usecases/listar_clientes.dart';

class SelectorCliente extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onClienteSeleccionado;

  const SelectorCliente({
    super.key,
    required this.controller,
    required this.onClienteSeleccionado,
  });

  @override
  State<SelectorCliente> createState() => _SelectorClienteState();
}

class _SelectorClienteState extends State<SelectorCliente> {
  late final ListarClientes listarClientesUseCase;

  List<Cliente> clientes = [];
  Cliente? clienteSeleccionado;

  final Color verdeApp = const Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();

    final repository = ClienteRepositoryImpl(
      ClientesRemoteDataSource(FirebaseFirestore.instance),
    );

    listarClientesUseCase = ListarClientes(repository);

    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    final resultado = await listarClientesUseCase();

    setState(() {
      clientes = resultado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: verdeApp.withValues(alpha:0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      'Selecciona el cliente para la cotización',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<Cliente>(
            initialValue: clienteSeleccionado,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Seleccionar cliente',
              prefixIcon: Icon(
                Icons.person,
                color: verdeApp,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: verdeApp.withValues(alpha:0.25),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: verdeApp,
                  width: 2,
                ),
              ),
            ),
            items: clientes.map((cliente) {
              return DropdownMenuItem<Cliente>(
                value: cliente,
                child: Text(
                  '${cliente.nombre} - ${cliente.rut}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (cliente) {
              if (cliente == null) return;

              setState(() {
                clienteSeleccionado = cliente;
              });

              widget.controller.text = cliente.nombre;
              widget.onClienteSeleccionado(cliente.id!.toString());
            },
          ),

          if (clienteSeleccionado != null) ...[
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: verdeApp.withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: verdeApp,
                    size: 20,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Cliente seleccionado: ${clienteSeleccionado!.nombre}',
                      style: TextStyle(
                        color: verdeApp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}