import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/features/cliente/presentation/pages/cliente_detalle_page.dart';
import 'registro_cliente_page.dart';
import '../../data/datasources/clientes_remote_datasource.dart';
import '../../data/repositories/cliente_repository_impl.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/usecases/listar_clientes.dart';
import 'editar_cliente_page.dart';
//AGREGAMOS LA IMPORTACIÓN DE LA PÁGINA DE COTIZACIÓN
import '../../../cotizacion/presentation/pages/crear_cotizacion_page.dart';

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
  bool _isLoading = true;

  final Color greenPrimary = const Color(0xFF0F5A3C); 

  @override
  void initState() {
    super.initState();
    listarClientesUseCase = ListarClientes(repository);
    _buscadorController.addListener(_filtrarClientes);
    cargarClientes();
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  Future<void> cargarClientes() async {
    try {
      final resultado = await listarClientesUseCase();
      if (!mounted) return;
      setState(() {
        clientes = resultado;
        clientesFiltrados = resultado;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _filtrarClientes() {
    final textoBusqueda = _buscadorController.text.toLowerCase().trim();
    setState(() {
      if (textoBusqueda.isEmpty) {
        clientesFiltrados = clientes;
      } else {
        clientesFiltrados = clientes.where((cliente) {
          return cliente.nombre.toLowerCase().contains(textoBusqueda) ||
                 cliente.rut.toLowerCase().contains(textoBusqueda);
        }).toList();
      }
    });
  }

  Future<bool?> _confirmarEliminar(Cliente cliente) async {
    if (cliente.id == null || cliente.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede eliminar un cliente sin ID')),
      );
      return false;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Eliminar cliente'),
          content: Text('¿Seguro que deseas eliminar a ${cliente.nombre}?\n\nEsta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return false;

    try {
      await repository.eliminarCliente(cliente.id!);
      if (!mounted) return true;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente eliminado correctamente'), behavior: SnackBarBehavior.floating),
      );
      cargarClientes();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          'Clientes',
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _buscadorController,
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente por nombre o RUT...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildPanel(),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CLIENTES RECIENTES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyMedium?.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Desliza → para eliminar',
                        style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color, fontStyle: FontStyle.italic),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: clientesFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_search_outlined, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'No se encontraron clientes para tu búsqueda.',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                // CRITERIO DE ACEPTACIÓN 2: Opción dinámica global para crear cliente contextual
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    backgroundColor: theme.primaryColor.withValues(alpha: 0.08),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const RegistroClientePage()),
                                    );
                                    cargarClientes();
                                  },
                                  icon: Icon(Icons.person_add_alt_1, color: theme.primaryColor, size: 18),
                                  label: Text(
                                    'Crear "${_buscadorController.text.trim()}"',
                                    style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: clientesFiltrados.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final cliente = clientesFiltrados[index];
                              
                              return Dismissible(
                                key: Key(cliente.id ?? index.toString()),
                                direction: DismissDirection.startToEnd,
                                confirmDismiss: (direction) => _confirmarEliminar(cliente),
                                background: Container(
                                  padding: const EdgeInsets.only(left: 20),
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_sweep_rounded, color: Colors.red[800], size: 28),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Eliminar Cliente', 
                                        style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold)
                                      ),
                                    ],
                                  ),
                                ),
                                child: _ClienteCardWidget(
                                  cliente: cliente,
                                  primaryColor: theme.primaryColor,
                                  onEdit: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => EditarClientePage(cliente: cliente)),
                                    );
                                    cargarClientes();
                                  },
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

  Widget _buildPanel() {
    final theme = Theme.of(context);
    final int totalEmpresas = clientes.where((c) {
      final cleanRut = c.rut.replaceAll('.', '').replaceAll('-', '');
      return cleanRut.startsWith('76') || cleanRut.startsWith('77');
    }).length;

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 105, 
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL CLIENTES',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${clientes.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.people_outline, color: Colors.white.withValues(alpha: 0.3), size: 28),
                  ],
                )
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Material(
                color: const Color(0xFFE3F2FD), 
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                     await Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroClientePage()));
                     cargarClientes(); 
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: const Color(0xFFE8EAF6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACCIONES',
                              style: TextStyle(color: Colors.blue[900]!.withValues(alpha: 0.6), fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Añadir Cliente',
                              style: TextStyle(color: Colors.indigo[900], fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Icon(Icons.person_add_alt_1_outlined, color: Colors.indigo[800], size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EMPRESAS', style: TextStyle(color: Colors.indigo[900]!.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
                    const SizedBox(height: 2),
                    Text('$totalEmpresas', style: TextStyle(color: Colors.indigo[900], fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

class _ClienteCardWidget extends StatelessWidget {
  final Cliente cliente;
  final Color primaryColor;
  final VoidCallback onEdit;

  const _ClienteCardWidget({
    required this.cliente,
    required this.primaryColor,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cleanRut = cliente.rut.replaceAll('.', '').replaceAll('-', '');
    final bool isEmpresa = cleanRut.startsWith('76') || cleanRut.startsWith('77');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetalleClientePage(cliente: cliente)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEmpresa ? Icons.business : Icons.person_outline,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'RUT: ${cliente.rut}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1, thickness: 0.5),
              ),

              _buildDataRow(Icons.mail_outline, cliente.correo),
              const SizedBox(height: 6),
              _buildDataRow(Icons.phone_outlined, cliente.telefono),
              const SizedBox(height: 6),
              _buildDataRow(Icons.location_on_outlined, cliente.direccion ?? 'Sin dirección'),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.black87),
                      label: const Text('Editar', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      // IMPLEMENTACIÓN DEL FLUJO DIRECTO CON PASO DE PARÁMETRO
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CrearCotizacionPage(
                              clienteInyectado: cliente,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.request_quote_outlined, size: 18),
                      label: const Text('Cotizar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}