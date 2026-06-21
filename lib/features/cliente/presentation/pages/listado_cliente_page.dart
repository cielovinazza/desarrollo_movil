import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/features/cliente/presentation/formatters/mascara_rut_formatters.dart';
import 'package:project/features/cliente/presentation/pages/cliente_detalle_page.dart';
import 'registro_cliente_page.dart';
import '../../data/datasources/clientes_remote_datasource.dart';
import '../../data/repositories/cliente_repository_impl.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/usecases/listar_clientes.dart';
import 'editar_cliente_page.dart';
import '../../../cotizacion/presentation/pages/crear_cotizacion_page.dart';
import '../formatters/mascara_rut_formatters.dart';

class ListadoClientesPage extends StatefulWidget {
  const ListadoClientesPage({super.key});

  @override
  State<ListadoClientesPage> createState() => _ListadoClientesPageState();
}

class _ListadoClientesPageState extends State<ListadoClientesPage> {
  late final ListarClientes listarClientesUseCase;
  final repository = ClienteRepositoryImpl(ClientesRemoteDataSource(FirebaseFirestore.instance));
  bool get _busquedaEsRut => RegExp(r'^\d').hasMatch(_buscadorController.text.trim());
  final TextEditingController _buscadorController = TextEditingController();

  List<Cliente> clientes = [];
  List<Cliente> clientesFiltrados = [];
  bool _isLoading = true;

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
  final textoBusqueda = _buscadorController.text.trim();
  final esRut = RegExp(r'^\d').hasMatch(textoBusqueda);

  setState(() {
    if (textoBusqueda.isEmpty) {
      clientesFiltrados = clientes;
    } else if (esRut) {
      final busquedaNormalizada = textoBusqueda
          .replaceAll('.', '')
          .replaceAll('-', '')
          .toLowerCase();
      clientesFiltrados = clientes.where((cliente) {
        final rutNormalizado = cliente.rut
            .replaceAll('.', '')
            .replaceAll('-', '')
            .toLowerCase();
        return rutNormalizado.contains(busquedaNormalizada);
      }).toList();
    } else {
      clientesFiltrados = clientes.where((cliente) {
        return cliente.nombre
            .toLowerCase()
            .contains(textoBusqueda.toLowerCase());
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
    final colorScheme = theme.colorScheme;

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
                      prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                      filled: true,
                      fillColor: colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildPanel(theme),
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
                                Icon(Icons.person_search_outlined, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                                const SizedBox(height: 12),
                                Text(
                                  'No se encontraron clientes para tu búsqueda.',
                                  style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
  
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    backgroundColor: theme.primaryColor.withValues(alpha: 0.08),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () async {
                                    final texto = _buscadorController.text.trim();
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RegistroClientePage(
                                          rutInicial: _busquedaEsRut
                                          ? RutInputFormatter.formatear(texto): null, 
                                          nombreInicial: _busquedaEsRut ? null : texto,
                                        ),
                                      ),
                                    );
                                    cargarClientes();
                                  },
                                  icon: Icon(Icons.person_add_alt_1, color: theme.primaryColor, size: 18),
                                  label: Text(
                                  _busquedaEsRut
                                      ? 'Registrar RUT ${RutInputFormatter.formatear(_buscadorController.text.trim())}'
                                      : 'Registrar a "${_buscadorController.text.trim()}"',
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
                                    color: theme.brightness == Brightness.dark
                                        ? colorScheme.error.withValues(alpha: 0.25)
                                        : colorScheme.error.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_sweep_rounded, color: colorScheme.error, size: 28),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Eliminar Cliente', 
                                        style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)
                                      ),
                                    ],
                                  ),
                                ),
                                child: _ClienteCardWidget(
                                  cliente: cliente,
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

  Widget _buildPanel(ThemeData theme) {
    final colorScheme = theme.colorScheme;
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
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL CLIENTES',
                  style: TextStyle(color: colorScheme.onPrimary.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${clientes.length}',
                      style: TextStyle(color: colorScheme.onPrimary, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.people_outline, color: colorScheme.onPrimary.withValues(alpha: 0.3), size: 28),
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
                color: colorScheme.secondaryContainer,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACCIONES',
                              style: TextStyle(color: colorScheme.onSecondaryContainer.withValues(alpha: 0.6), fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Añadir Cliente',
                              style: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Icon(Icons.person_add_alt_1_outlined, color: colorScheme.onSecondaryContainer, size: 18),
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
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EMPRESAS', style: TextStyle(color: colorScheme.onSecondaryContainer.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
                    const SizedBox(height: 2),
                    Text('$totalEmpresas', style: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 14, fontWeight: FontWeight.bold)),
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
  final VoidCallback onEdit;

  const _ClienteCardWidget({
    required this.cliente,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cleanRut = cliente.rut.replaceAll('.', '').replaceAll('-', '');
    final bool isEmpresa = cleanRut.startsWith('76') || cleanRut.startsWith('77');

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
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
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEmpresa ? Icons.business : Icons.person_outline,
                      color: colorScheme.onPrimaryContainer,
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
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'RUT: ${cliente.rut}',
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12),
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

              _buildDataRow(theme, Icons.mail_outline, cliente.correo),
              const SizedBox(height: 6),
              _buildDataRow(theme, Icons.phone_outlined, cliente.telefono),
              const SizedBox(height: 6),
              _buildDataRow(theme, Icons.location_on_outlined, cliente.direccion ?? 'Sin dirección'),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: onEdit,
                      icon: Icon(Icons.edit_outlined, size: 18, color: colorScheme.onSurface),
                      label: Text('Editar', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
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

  Widget _buildDataRow(ThemeData theme, IconData icon, String value) {
    final color = theme.textTheme.bodyMedium?.color;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: color, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}