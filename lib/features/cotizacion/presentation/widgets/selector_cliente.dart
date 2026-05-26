import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:project/features/cliente/data/datasources/clientes_remote_datasource.dart';
import 'package:project/features/cliente/data/repositories/cliente_repository_impl.dart';
import 'package:project/features/cliente/domain/entities/cliente.dart';
import 'package:project/features/cliente/domain/usecases/listar_clientes.dart';
import 'package:project/features/cliente/presentation/pages/registro_cliente_page.dart';
import '../../../cliente/presentation/formatters/mascara_rut_formatters.dart';

class SelectorCliente extends StatefulWidget {
  final TextEditingController controller;
  final Function(Cliente) onClienteSeleccionado;

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
  final TextEditingController _rutController = TextEditingController();

  List<Cliente> clientes = [];
  Cliente? clienteSeleccionado;

  bool buscando = false;
  String? mensaje;

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

  @override
  void dispose() {
    _rutController.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes() async {
    final resultado = await listarClientesUseCase();
    setState(() {
      clientes = resultado;
    });
  }

  String _normalizarRut(String rut) {
    return rut.replaceAll('.', '').replaceAll('-', '').trim().toLowerCase();
  }

  Future<void> _buscarClientePorRut() async {
    final rutBuscado = _rutController.text.trim();

    if (rutBuscado.isEmpty) {
      setState(() {
        mensaje = 'Ingrese un RUT para buscar';
        clienteSeleccionado = null;
      });
      return;
    }

    setState(() {
      buscando = true;
      mensaje = null;
    });

    // Recargamos la lista por si se registró un cliente recientemente
    await _cargarClientes();

    final rutNormalizado = _normalizarRut(rutBuscado);
    Cliente? encontrado;

    for (final cliente in clientes) {
      if (_normalizarRut(cliente.rut) == rutNormalizado) {
        encontrado = cliente;
        break;
      }
    }

    if (encontrado != null) {
      setState(() {
        clienteSeleccionado = encontrado;
        widget.controller.text = encontrado!.nombre;
        buscando = false;
        mensaje = 'Cliente encontrado correctamente';
      });

      widget.onClienteSeleccionado(encontrado);
    } else {
      setState(() {
        clienteSeleccionado = null;
        buscando = false;
        mensaje = 'Cliente no encontrado. Debe registrar un nuevo cliente.';
      });

      final registrar = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cliente no encontrado'),
          content: Text(
            'No existe un cliente con el RUT "$rutBuscado". ¿Deseas registrarlo ahora?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: verdeApp,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Registrar cliente'),
            ),
          ],
        ),
      );

      if (registrar == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RegistroClientePage(),
          ),
        );
        // Volver a cargar la lista tras el registro
        await _cargarClientes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: verdeApp.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cliente',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Ingrese el RUT del cliente para buscarlo en el sistema',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          
          // Input de texto para el RUT
          TextFormField(
            controller: _rutController,
            keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9kK]'),
                  ),

                  RutInputFormatter(),

                ],
            decoration: InputDecoration(
              labelText: 'RUT del cliente',
              hintText: 'Ej: 12.345.678-9',
              prefixIcon: Icon(
                Icons.badge_outlined,
                color: verdeApp,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: buscando ? null : _buscarClientePorRut,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: verdeApp.withValues(alpha: 0.25),
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
            onFieldSubmitted: (_) => buscando ? null : _buscarClientePorRut(),
          ),

          const SizedBox(height: 12),

          // Botón de búsqueda extendido
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: buscando ? null : _buscarClientePorRut,
              icon: buscando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(buscando ? 'Buscando...' : 'Buscar cliente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: verdeApp,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Feedback visual: Mensajes de estado (Éxito o Error)
          if (mensaje != null) ...[
            const SizedBox(height: 12),
            Text(
              mensaje!,
              style: TextStyle(
                color: clienteSeleccionado == null ? Colors.orange.shade800 : verdeApp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          // Tarjeta que aparece solo si el cliente fue exitosamente seleccionado
          if (clienteSeleccionado != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: verdeApp.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: verdeApp.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: verdeApp, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clienteSeleccionado!.nombre,
                          style: TextStyle(
                            color: verdeApp,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'RUT: ${clienteSeleccionado!.rut}',
                          style: TextStyle(
                            color: verdeApp.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
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