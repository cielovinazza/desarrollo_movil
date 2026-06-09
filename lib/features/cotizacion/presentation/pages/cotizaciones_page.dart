import 'package:flutter/material.dart';
import 'package:project/features/cotizacion/presentation/pages/ver_pdf_page.dart';
import 'package:project/shared/design_system/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'crear_cotizacion_page.dart';
import '../../domain/usecases/obtener_cotizacion.dart';
import '../../data/dtos/cotizacion_dtos.dart';
import '../../data/datasources/cotizacion_firebase_datasource.dart';
import '../../data/repositories/cotizacion_repository_impl.dart';
import '../../domain/usecases/actualizar_estado_cotizacion.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'generar_pdf_page.dart';
import '../../../../shared/widgets/app_dialogs.dart';

class CotizacionesPage extends StatefulWidget {
  final bool filtrarMesActual;

  const CotizacionesPage({super.key, this.filtrarMesActual = false});

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
  bool enviandoCorreo = false;

  String filterCliente = '';
  String filterId = '';
  String? estadoFiltro;
  DateTime? fechaInicioFiltro;
  DateTime? fechaFinFiltro;

  @override
  void initState() {
    super.initState();

    if (widget.filtrarMesActual) {
      final ahora = DateTime.now();

      fechaInicioFiltro = DateTime(ahora.year, ahora.month, 1);

      fechaFinFiltro = DateTime(ahora.year, ahora.month + 1, 0);
    }

    final datasource = CotizacionFirestoreDataSource(
      FirebaseFirestore.instance,
    );
    repository = CotizacionRepositoryImpl(datasource);
    actualizarEstadoUseCase = ActualizarEstadoCotizacion(repository);
    obtenerCotizacionesUseCase = ObtenerCotizacion(repository);
    cargarCotizacion();
  }

  @override
  void didUpdateWidget(CotizacionesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filtrarMesActual && !oldWidget.filtrarMesActual) {
      final ahora = DateTime.now();
      fechaInicioFiltro = DateTime(ahora.year, ahora.month, 1);
      fechaFinFiltro = DateTime(ahora.year, ahora.month + 1, 0);
      cargarCotizacion();
    } else if (!widget.filtrarMesActual && oldWidget.filtrarMesActual) {
      fechaInicioFiltro = null;
      fechaFinFiltro = null;
      cargarCotizacion();
    }
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
      AppDialogs.mostrarError(context, 'Error de consulta', e.toString());
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
      if (nuevoEstado == 'Enviada') {
        await procesarEnvioCorreo(cotizacion);
        return;
      }
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
      AppDialogs.mostrarError(
        context,
        'Transición de Estado Inválida',
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> procesarEnvioCorreo(CotizacionDto cotizacion) async {
    setState(() => enviandoCorreo = true);
    try {
      await repository.enviarCotizacionPorCorreo(cotizacion);
      await cargarCotizacion();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Correo enviado con éxito!'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (e) {
      AppDialogs.mostrarError(
        context,
        'Error al enviar correo',
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => enviandoCorreo = false);
    }
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
        return AppTheme.primary.withValues(alpha: 0.7);
      case 'Enviada':
        return Colors.blueGrey;
      default:
        return AppTheme.warning;
    }
  }

  int contarPorEstado(String estado) {
    return cotizaciones.where((c) => c.estado == estado).length;
  }

  bool _estacargando = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    return Stack(
      children: [
        Scaffold(
          floatingActionButton: FloatingActionButton(
            backgroundColor: _estacargando ? Colors.grey : theme.primaryColor,
            foregroundColor: Colors.white,
            tooltip: 'Nueva cotización',
            onPressed: _estacargando
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CrearCotizacionPage(),
                      ),
                    );
                    if (!mounted) return;

                    setState(() => _estacargando = true);

                    try {
                      await cargarCotizacion();
                    } finally {
                      if (mounted) {
                        setState(() => _estacargando = false);
                      }
                    }
                  },
            child: _estacargando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add, size: 28),
          ),
          appBar: AppBar(
            elevation: 0,
            title: const Text('Cotizaciones'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: cargarCotizacion,
                color: theme.appBarTheme.foregroundColor,
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
                      snapshot.hasData &&
                      snapshot.data!.metadata.hasPendingWrites;
                  if (!hasPending) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    color: AppTheme.warning.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sincronizando cambios locales...',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
                      const SizedBox(height: 16),
                      Text(
                        'Cotizaciones por Estado',
                        style: textTheme.titleLarge?.copyWith(
                          color: AppTheme.darkPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? theme.cardColor
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ItemResumenNeutro(
                              label: 'Total',
                              value: cotizaciones.length.toString(),
                              colorText:
                                  theme.textTheme.bodyLarge?.color ??
                                  AppTheme.textDark,
                            ),
                            _buildVerticalDivider(theme),
                            _ItemResumenNeutro(
                              label: 'Enviadas',
                              value:
                                  (contarPorEstado('Enviada') +
                                          contarPorEstado('Pendiente'))
                                      .toString(),
                              colorText: Colors.blueGrey,
                            ),
                            _buildVerticalDivider(theme),
                            _ItemResumenNeutro(
                              label: 'Aprobadas',
                              value:
                                  (contarPorEstado('Aprobada por el Cliente') +
                                          contarPorEstado('Aceptada'))
                                      .toString(),
                              colorText: AppTheme.primary,
                            ),
                            _buildVerticalDivider(theme),
                            _ItemResumenNeutro(
                              label: 'Rechazadas',
                              value:
                                  (contarPorEstado('Rechazada por el Cliente') +
                                          contarPorEstado('Rechazada'))
                                      .toString(),
                              colorText: AppTheme.danger,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ExpansionTile(
                            title: Text(
                              'Filtros Avanzados',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            childrenPadding: const EdgeInsets.all(12),
                            expandedCrossAxisAlignment:
                                CrossAxisAlignment.start,
                            shape: const Border(),
                            children: [
                              TextField(
                                controller: idSearchController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                enableSuggestions: false,
                                autocorrect: false,
                                onChanged: (value) {
                                  filterId = value.trim().toUpperCase();
                                  cargarCotizacion();
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Buscar por código único',
                                  prefixIcon: Icon(Icons.key),
                                  hintText: 'Ej: CT-001',
                                ),
                              ),
                              const SizedBox(height: 12),
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
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: estadoFiltro,
                                decoration: const InputDecoration(
                                  labelText: 'Filtrar por Estado',
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
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  //fecha desde
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
                                      onPressed: () async {
                                        final fecha = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              fechaInicioFiltro ??
                                              DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2100),
                                        );
                                        if (fecha != null) {
                                          setState(
                                            () => fechaInicioFiltro = fecha,
                                          );
                                          cargarCotizacion();
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.date_range,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                fechaInicioFiltro == null
                                                    ? 'Desde'
                                                    : '${fechaInicioFiltro!.day}/${fechaInicioFiltro!.month}/${fechaInicioFiltro!.year}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          // si hay fecha seleccionada, muestra una X para borrarla
                                          if (fechaInicioFiltro != null)
                                            GestureDetector(
                                              onTap: () {
                                                setState(
                                                  () =>
                                                      fechaInicioFiltro = null,
                                                );
                                                cargarCotizacion();
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(4.0),
                                                child: Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // fecha hasta
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
                                      onPressed: () async {
                                        final fecha = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              fechaFinFiltro ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2100),
                                        );
                                        if (fecha != null) {
                                          setState(
                                            () => fechaFinFiltro = fecha,
                                          );
                                          cargarCotizacion();
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.date_range,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                fechaFinFiltro == null
                                                    ? 'Hasta'
                                                    : '${fechaFinFiltro!.day}/${fechaFinFiltro!.month}/${fechaFinFiltro!.year}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (fechaFinFiltro != null)
                                            GestureDetector(
                                              onTap: () {
                                                setState(
                                                  () => fechaFinFiltro = null,
                                                );
                                                cargarCotizacion();
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(4.0),
                                                child: Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (cargando)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (cotizaciones.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30),
                            child: Text(
                              'No se encontraron cotizaciones.',
                              style: textTheme.titleMedium?.copyWith(
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cotizaciones.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final cotizacion = cotizaciones[index];
                            return _CotizacionCard(
                              cotizacionRaw: cotizacion,
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
                              onEnviarCorreoSolicitado: () =>
                                  procesarEnvioCorreo(cotizacion),
                              onRecargar: cargarCotizacion,
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
        ),
        if (enviandoCorreo)
          Container(
            color: Colors.black45,
            child: const Center(
              child: Card(
                margin: EdgeInsets.all(24),
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Enviando cotización por correo...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ], // Stack
    );
  }

  Widget _buildVerticalDivider(ThemeData theme) {
    return Container(
      height: 30,
      width: 1,
      color: theme.dividerColor.withValues(alpha: 0.2),
    );
  }
}

class _ItemResumenNeutro extends StatelessWidget {
  final String label;
  final String value;
  final Color colorText;

  const _ItemResumenNeutro({
    required this.label,
    required this.value,
    required this.colorText,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CotizacionCard extends StatelessWidget {
  final CotizacionDto cotizacionRaw;
  final String codigo;
  final String cliente;
  final String direccion;
  final String fecha;
  final String monto;
  final String estado;
  final Color estadoColor;
  final ValueChanged<String> onEstadoCambiado;
  final VoidCallback onEnviarCorreoSolicitado;
  final Future<void> Function() onRecargar;

  const _CotizacionCard({
    required this.cotizacionRaw,
    required this.codigo,
    required this.cliente,
    required this.direccion,
    required this.fecha,
    required this.monto,
    required this.estado,
    required this.estadoColor,
    required this.onEstadoCambiado,
    required this.onEnviarCorreoSolicitado,
    required this.onRecargar,
  });

  @override
  Widget build(BuildContext context) {
    String estadoNormalizado = estado;
    if (estado == 'Pendiente') estadoNormalizado = 'En Proceso';
    if (estado == 'Aceptada') estadoNormalizado = 'Aprobada por el Cliente';
    if (estado == 'Rechazada') estadoNormalizado = 'Rechazada por el Cliente';

    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final bool tienePdf =
        cotizacionRaw.pdfUrl != null && cotizacionRaw.pdfUrl!.isNotEmpty;
    final bool noTienePdf = !tienePdf;

    final bool esListaParaEnvio = estado == 'Lista para Envío';
    final bool esRechazada =
        estado == 'Rechazada por el Cliente' || estado == 'Rechazada';
    final bool esEnProceso = estado == 'En Proceso';
    final bool esEnviadaOAprobada =
        estado == 'Enviada' ||
        estado == 'Aprobada por el Cliente' ||
        estado == 'Aceptada';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                child: Icon(
                  Icons.description_outlined,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme
                            .textDark, // Mantener color de texto solicitado
                      ),
                    ),
                    Text(
                      codigo.isEmpty ? 'Generando código...' : codigo,
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  estado,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: estadoColor,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: theme.hintColor,
              ),
              const SizedBox(width: 6),
              Text(fecha, style: textTheme.bodyMedium),
              Expanded(
                child: Text(
                  monto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Estado:',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: estadoNormalizado,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: textTheme.bodyMedium,
                  items: const [
                    DropdownMenuItem(
                      value: 'En Proceso',
                      child: Text('En Proceso'),
                    ),
                    DropdownMenuItem(
                      value: 'Lista para Envío',
                      child: Text('Lista para Envío'),
                    ),
                    DropdownMenuItem(value: 'Enviada', child: Text('Enviada')),
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
                    if (val != null && val != estado) {
                      onEstadoCambiado(val);
                    }
                  },
                ),
              ),
            ],
          ),
          if (esListaParaEnvio) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (noTienePdf) {
                          final resultado = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  GenerarPdfPage(cotizacion: cotizacionRaw),
                            ),
                          );
                          if (resultado == true) {
                            await onRecargar();
                          }
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VerPdfPage(
                                url: cotizacionRaw.pdfUrl,
                                codigoCotizacion: cotizacionRaw.codigo,
                              ),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        noTienePdf
                            ? Icons.picture_as_pdf_outlined
                            : Icons.picture_as_pdf,
                        size: 16,
                      ),
                      label: Text(noTienePdf ? 'Generar PDF' : 'Ver PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tienePdf
                            ? theme.colorScheme.error
                            : theme.primaryColor,
                        side: BorderSide(
                          color: tienePdf
                              ? theme.colorScheme.error
                              : theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onEnviarCorreoSolicitado,
                      icon: const Icon(Icons.mail, size: 16),
                      label: const Text('Enviar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (esRechazada) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  if (tienePdf)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VerPdfPage(
                                url: cotizacionRaw.pdfUrl,
                                codigoCotizacion: cotizacionRaw.codigo,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text('Ver PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error),
                        ),
                      ),
                    ),
                  if (tienePdf) const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CrearCotizacionPage(
                              cotizacionAEditar: cotizacionRaw,
                            ),
                          ),
                        );
                        await onRecargar();
                      },
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text(
                        'Editar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (esEnProceso) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CrearCotizacionPage(cotizacionAEditar: cotizacionRaw),
                    ),
                  );
                  await onRecargar();
                },
                icon: const Icon(Icons.edit_note, size: 20),
                label: const Text(
                  'Editar Cotización',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          if (esEnviadaOAprobada && tienePdf) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerPdfPage(
                        url: cotizacionRaw.pdfUrl,
                        codigoCotizacion: cotizacionRaw.codigo,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('Ver PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
