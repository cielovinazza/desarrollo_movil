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
import '../widgets/panel_filtros.dart';

class CotizacionesPage extends StatefulWidget {
  final bool filtrarMesActual;
  final String? codigoParaReintentar;
  final VoidCallback? onReintentoCompletado;

  const CotizacionesPage({super.key, this.filtrarMesActual = false,
   this.codigoParaReintentar,
  this.onReintentoCompletado,});

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
    cargarCotizacion().then((_) {
      if (widget.codigoParaReintentar != null) {
        _ejecutarReintento(widget.codigoParaReintentar!);
      }
    });
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

    final codigoNuevo = widget.codigoParaReintentar;
    final codigoAnterior = oldWidget.codigoParaReintentar;
    if (codigoNuevo != null && codigoNuevo != codigoAnterior) {
      _ejecutarReintento(codigoNuevo);
    }
  }

  Future<void> _ejecutarReintento(String codigo) async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    CotizacionDto? cotizacion;
    try {
      cotizacion = cotizaciones.firstWhere((c) => c.codigo == codigo);
    } catch (_) {
      final snap = await FirebaseFirestore.instance
          .collection('cotizaciones')
          .where('codigo', isEqualTo: codigo)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        cotizacion = CotizacionDto.fromMap(
          snap.docs.first.id,
          snap.docs.first.data(),
        );
      }
    }

    if (!mounted) return;
    if (cotizacion == null) {
      AppDialogs.mostrarError(
        context,
        'No encontrada',
        'No se encontró la cotización $codigo para reintentar el envío.',
      );
      widget.onReintentoCompletado?.call();
      return;
    }

    await mostrarModalResumenEnvio(cotizacion);
    widget.onReintentoCompletado?.call();
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

  Future<String?> mostrarModalObservacionEstado(String nuevoEstado) async {
    final observacionController = TextEditingController();

    final resultado = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar estado'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nuevo estado: $nuevoEstado'),
              const SizedBox(height: 12),
              TextField(
                controller: observacionController,
                minLines: 4,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                maxLength: 250,
                decoration: InputDecoration(
                  labelText: nuevoEstado == 'Rechazada por el Cliente'
                      ? 'Motivo de rechazo'
                      : 'Observaciones',
                  hintText: nuevoEstado == 'Rechazada por el Cliente'
                      ? 'Ingrese el motivo del rechazo'
                      : 'Ingrese una observación opcional',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final texto = observacionController.text.trim();

              final cantidadPalabras = texto
                  .split(RegExp(r'\s+'))
                  .where((p) => p.isNotEmpty)
                  .length;

              final requiereObservacion =
                  nuevoEstado == 'Rechazada por el Cliente';

              if (requiereObservacion && cantidadPalabras < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Debe ingresar un motivo de rechazo de al menos 3 palabras.',
                    ),
                  ),
                );
                return;
              }

              Navigator.pop(context, texto);
            },
            child: const Text('Guardar cambio'),
          ),
        ],
      ),
    );

    observacionController.dispose();
    return resultado;
  }

  Future<void> cambiarEstado(
    CotizacionDto cotizacion,
    String nuevoEstado,
  ) async {
    try {
      final observacion = await mostrarModalObservacionEstado(nuevoEstado);

      if (observacion == null) {
        return;
      }

      if (nuevoEstado == 'Enviada') {
        await mostrarModalResumenEnvio(cotizacion);
        return;
      }

      await actualizarEstadoUseCase(
        cotizacion.id,
        cotizacion.estado,
        nuevoEstado,
        observacion: observacion,
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

  Future<void> mostrarModalResumenEnvio(CotizacionDto cotizacion) async {
    final subtotalCostosDirectos =
        cotizacion.subtotalObra +
        cotizacion.subtotalMateriales +
        cotizacion.subtotalManoObra +
        cotizacion.viatico;

    final montoUtilidad =
        subtotalCostosDirectos * (cotizacion.porcentajeUtilidad / 100);

    final baseConUtilidad = subtotalCostosDirectos + montoUtilidad;

    final montoIva = baseConUtilidad * (cotizacion.porcentajeIva / 100);

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Resumen de cotización'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Código: ${cotizacion.codigo}'),
              Text('Cliente: ${cotizacion.clienteNombre}'),
              Text('RUT: ${cotizacion.clienteRut}'),
              Text('Correo: ${cotizacion.clienteEmail}'),

              const Divider(height: 24),

              Text(
                'Trabajos/Obra: ${CurrencyFormatter.format(cotizacion.subtotalObra)} CLP',
              ),
              Text(
                'Materiales: ${CurrencyFormatter.format(cotizacion.subtotalMateriales)} CLP',
              ),
              Text(
                'Mano de obra: ${CurrencyFormatter.format(cotizacion.subtotalManoObra)} CLP',
              ),
              Text(
                'Viáticos: ${CurrencyFormatter.format(cotizacion.viatico)} CLP',
              ),

              const Divider(height: 24),

              Text(
                'Subtotal costos directos: ${CurrencyFormatter.format(subtotalCostosDirectos)} CLP',
              ),
              Text(
                'Utilidad (${cotizacion.porcentajeUtilidad}%): ${CurrencyFormatter.format(montoUtilidad)} CLP',
              ),
              Text(
                'IVA (${cotizacion.porcentajeIva}%): ${CurrencyFormatter.format(montoIva)} CLP',
              ),

              const Divider(height: 24),

              Text(
                'TOTAL FINAL: ${CurrencyFormatter.format(cotizacion.totalFinal)} CLP',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                '¿Desea confirmar el envío de esta cotización al cliente?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar envío'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await procesarEnvioCorreo(cotizacion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final esOscuro = theme.brightness == Brightness.dark;
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
                          color: esOscuro
                              ? AppTheme.lightGreen
                              : AppTheme.darkPrimary,
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
                      PanelFiltros(
                        idSearchController: idSearchController,
                        searchController: searchController,
                        estadoFiltro: estadoFiltro,
                        fechaInicioFiltro: fechaInicioFiltro,
                        fechaFinFiltro: fechaFinFiltro,
                        onFiltroIdChanged: (val) {
                          filterId = val.trim().toUpperCase();
                          cargarCotizacion();
                        },
                        onFiltroClienteChanged: (val) {
                          filterCliente = val;
                          cargarCotizacion();
                        },
                        onEstadoChanged: (val) {
                          setState(() => estadoFiltro = val);
                          cargarCotizacion();
                        },
                        onFechaInicioChanged: (val) {
                          setState(() => fechaInicioFiltro = val);
                          cargarCotizacion();
                        },
                        onFechaFinChanged: (val) {
                          setState(() => fechaFinFiltro = val);
                          cargarCotizacion();
                        },
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
                                ? () {
                                    final date = DateTime.parse(cotizacion.fechaCreacion!).toLocal();
                                    final day = date.day.toString().padLeft(2, '0');
                                    final month = date.month.toString().padLeft(2, '0');
                                    return '$day-$month-${date.year}';
                                  }()
                                : 'Sin Fecha',
                              monto:
                                  '${CurrencyFormatter.format(cotizacion.totalFinal)} CLP',
                              estado: cotizacion.estado,
                              estadoColor: estadoColor(cotizacion.estado),
                              onEstadoCambiado: (nuevoEstado) =>
                                  cambiarEstado(cotizacion, nuevoEstado),
                              onEnviarCorreoSolicitado: () =>
                                  mostrarModalResumenEnvio(cotizacion),
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

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        if (tienePdf) {
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
      child: Container(
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
                          // Mantener color de texto solicitado
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
                        builder: (context) => CrearCotizacionPage(
                          cotizacionAEditar: cotizacionRaw,
                        ),
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
      ),
    );
  }
}
