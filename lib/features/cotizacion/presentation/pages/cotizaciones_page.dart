import 'package:flutter/material.dart';
import 'package:project/shared/design_system/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'crear_cotizacion_page.dart';
import '../../domain/usecases/obtener_cotizacion.dart';
import '../../data/dtos/cotizacion_dtos.dart';
import '../../data/datasources/cotizacion_firebase_datasource.dart';
import '../../data/repositories/cotizacion_repository_impl.dart';
import '../../domain/usecases/actualizar_estado_cotizacion.dart';
import '../../../../core/utils/currency_formatter.dart';

class CotizacionesPage extends StatefulWidget {
  const CotizacionesPage({super.key});

  @override
  State<CotizacionesPage> createState() => _CotizacionesPageState();
}

class _CotizacionesPageState extends State<CotizacionesPage> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController idSearchController = TextEditingController();

  late final ActualizarEstadoCotizacion actualizarEstadoUseCase;
  late final ObtenerCotizacion obtenerCotizacionesUseCase;
  late final CotizacionRepositoryImpl repository;

  List<CotizacionDto> cotizaciones = [];
  bool cargando = true;

  String filterCliente = '';
  String filterId = '';
  String? estadoFiltro;
  DateTime? fechaInicioFiltro;
  DateTime? fechaFinFiltro;

  @override
  void initState() {
    super.initState();

    final datasource = CotizacionFirestoreDataSource(
      FirebaseFirestore.instance,
    );

    repository = CotizacionRepositoryImpl(datasource);

    actualizarEstadoUseCase = ActualizarEstadoCotizacion(repository);

    obtenerCotizacionesUseCase = ObtenerCotizacion(repository);

    cargarCotizacion();
  }

  Future<void> cargarCotizacion() async {
    if (!mounted) return;
    setState(() => cargando = true);
    try {
      final data = await obtenerCotizacionesUseCase(
        idBusqueda: filterId.isEmpty ? null : filterId,
        clienteNombre: filterCliente.isEmpty ? null : filterCliente,
        estado: estadoFiltro,
        fechaInicio: fechaInicioFiltro,
        fechaFin: fechaFinFiltro,
      );

      if (!mounted) return;
      setState(() {
        cotizaciones = data;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => cargando = false);
      _mostrarDialogoError('Error de consulta', e.toString());
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    idSearchController.dispose();
    super.dispose();
  }

  Future<void> cambiarEstado(
    CotizacionDto cotizacion,
    String nuevoEstado,
  ) async {
    try {
      await actualizarEstadoUseCase(
        cotizacion.id,
        cotizacion.estado,
        nuevoEstado,
      );

      await cargarCotizacion();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cotización actualizada a: $nuevoEstado'),
          backgroundColor: estadoColor(nuevoEstado),
        ),
      );
    } catch (e) {
      _mostrarDialogoError(
        'Transición de Estado Inválida',
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void _mostrarDialogoError(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SelectableText(
          mensaje,
        ), // 👈 Cambia 'Text' por 'SelectableText'
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Color estadoColor(String estado) {
    switch (estado) {
      case 'Aprobada por el Cliente':
      case 'Aceptada':
        return AppTheme.primary;
      case 'Rechazada por el Cliente':
      case 'Rechazada':
        return AppTheme.danger;
      case 'Lista para Envío':
        return Colors.blue;
      case 'Enviada':
        return Colors.purple;
      default:
        return AppTheme.warning;
    }
  }

  int contarPorEstado(String estado) {
    return cotizaciones.where((c) => c.estado == estado).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearCotizacionPage()),
          );
          await cargarCotizacion();
        },
      ),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: const Text(
          'Cotizaciones',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarCotizacion,
          ),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('cotizaciones')
                .snapshots(includeMetadataChanges: true),
            builder: (context, snapshot) {
              final hasPending =
                  snapshot.hasData && snapshot.data!.metadata.hasPendingWrites;
              if (!hasPending) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                color: Colors.orange[100],
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: const Text(
                  'Sincronizando cambios locales con el servidor...',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Revise, filtre y actualice el flujo de estados de sus cotizaciones en tiempo real.',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 15),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _ResumenCard(
                          title: 'Total',
                          value: cotizaciones.length.toString(),
                          icon: Icons.description_outlined,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResumenCard(
                          title: 'En Proceso',
                          value:
                              (contarPorEstado('En Proceso') +
                                      contarPorEstado('Pendiente'))
                                  .toString(),
                          icon: Icons.pending_actions,
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ResumenCard(
                          title: 'Aprobadas',
                          value:
                              (contarPorEstado('Aprobada por el Cliente') +
                                      contarPorEstado('Aceptada'))
                                  .toString(),
                          icon: Icons.check_circle_outline,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResumenCard(
                          title: 'Rechazadas',
                          value:
                              (contarPorEstado('Rechazada por el Cliente') +
                                      contarPorEstado('Rechazada'))
                                  .toString(),
                          icon: Icons.cancel_outlined,
                          color: AppTheme.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ExpansionTile(
                        title: const Text(
                          'Filtros Avanzados',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        initiallyExpanded: false,
                        children: [
                          TextField(
                            controller: idSearchController,
                            textCapitalization: TextCapitalization.characters,
                            enableSuggestions: false,
                            autocorrect: false,
                            onChanged: (value) {
                              filterId = value.trim().toUpperCase();
                              cargarCotizacion();
                            },
                            decoration: InputDecoration(
                              labelText: 'Buscar por codigo de documento único',
                              prefixIcon: Icon(Icons.key),
                              hintText: 'Ej: CT-001, CT-002, etc.',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: searchController,
                            onChanged: (value) {
                              filterCliente = value;
                              cargarCotizacion();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Buscar por nombre del cliente',
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: estadoFiltro,
                            decoration: const InputDecoration(
                              labelText: 'Filtrar por Estado',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Todos los estados'),
                              ),
                              DropdownMenuItem(
                                value: 'En Proceso',
                                child: Text('En Proceso'),
                              ),
                              DropdownMenuItem(
                                value: 'Lista para Envío',
                                child: Text('Lista para Envío'),
                              ),
                              DropdownMenuItem(
                                value: 'Enviada',
                                child: Text('Enviada'),
                              ),
                              DropdownMenuItem(
                                value: 'Aprobada por el Cliente',
                                child: Text('Aprobada por el Cliente'),
                              ),
                              DropdownMenuItem(
                                value: 'Rechazada por el Cliente',
                                child: Text('Rechazada por el Cliente'),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() => estadoFiltro = val);
                              cargarCotizacion();
                            },
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.date_range),
                                  label: Text(
                                    fechaInicioFiltro == null
                                        ? 'Desde'
                                        : '${fechaInicioFiltro!.day}/${fechaInicioFiltro!.month}/${fechaInicioFiltro!.year}',
                                  ),
                                  onPressed: () async {
                                    final fecha = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );

                                    if (fecha != null) {
                                      setState(() {
                                        fechaInicioFiltro = fecha;
                                      });

                                      cargarCotizacion();
                                    }
                                  },
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.date_range),
                                  label: Text(
                                    fechaFinFiltro == null
                                        ? 'Hasta'
                                        : '${fechaFinFiltro!.day}/${fechaFinFiltro!.month}/${fechaFinFiltro!.year}',
                                  ),
                                  onPressed: () async {
                                    final fecha = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );

                                    if (fecha != null) {
                                      setState(() {
                                        fechaFinFiltro = fecha;
                                      });

                                      cargarCotizacion();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          ///aqui termina el row
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (cargando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (cotizaciones.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: Text(
                          'No se encontraron cotizaciones en la base de datos.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cotizaciones.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final cotizacion = cotizaciones[index];

                        return _CotizacionCard(
                          codigo: cotizacion.codigo,
                          cliente: cotizacion.clienteNombre,
                          direccion: cotizacion.direccion,
                          fecha: cotizacion.fechaCreacion != null
                              ? '${cotizacion.fechaCreacion!.toDate().day.toString().padLeft(2, '0')}-'
                                    '${cotizacion.fechaCreacion!.toDate().month.toString().padLeft(2, '0')}-'
                                    '${cotizacion.fechaCreacion!.toDate().year}'
                              : 'Sin Fecha',
                          monto:
                              '${CurrencyFormatter.format(cotizacion.totalFinal)} CLP',
                          estado: cotizacion.estado,
                          estadoColor: estadoColor(cotizacion.estado),
                          onEstadoCambiado: (nuevoEstado) =>
                              cambiarEstado(cotizacion, nuevoEstado),
                        );
                      },
                    ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ResumenCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CotizacionCard extends StatelessWidget {
  final String codigo;
  final String cliente;
  final String direccion;
  final String fecha;
  final String monto;
  final String estado;
  final Color estadoColor;
  final ValueChanged<String> onEstadoCambiado;

  const _CotizacionCard({
    required this.codigo,
    required this.cliente,
    required this.direccion,
    required this.fecha,
    required this.monto,
    required this.estado,
    required this.estadoColor,
    required this.onEstadoCambiado,
  });

  @override
  Widget build(BuildContext context) {
    String estadoNormalizado = estado;
    if (estado == 'Pendiente') estadoNormalizado = 'En Proceso';
    if (estado == 'Aceptada') estadoNormalizado = 'Aprobada por el Cliente';
    if (estado == 'Rechazada') estadoNormalizado = 'Rechazada por el Cliente';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEBF5FB),
                child: Icon(
                  Icons.description_outlined,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      codigo.isEmpty ? 'Generando código...' : codigo,
                      style: const TextStyle(color: AppTheme.textGrey),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  estado,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: estadoColor,
              ),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 18),
              const SizedBox(width: 8),
              Text(fecha),
              const Spacer(),
              Text(
                monto,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Cambiar Estado:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: estadoNormalizado,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'En Proceso',
                      child: Text('En Proceso', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'Lista para Envío',
                      child: Text(
                        'Lista para Envío',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Enviada',
                      child: Text('Enviada', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'Aprobada por el Cliente',
                      child: Text(
                        'Aprobada por el Cliente',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Rechazada por el Cliente',
                      child: Text(
                        'Rechazada por el Cliente',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null && val != estado) {
                      onEstadoCambiado(val);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
