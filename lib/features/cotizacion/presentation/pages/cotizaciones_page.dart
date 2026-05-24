import 'package:flutter/material.dart';
import 'package:project/shared/design_system/app_theme.dart';
import 'crear_cotizacion_page.dart';
import '../../domain/usecases/obtener_cotizacion.dart';
import '../../data/dtos/cotizacion_dtos.dart';
import '../../data/datasources/cotizacion_firebase_datasource.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/cotizacion_repository_impl.dart';

import '../../domain/usecases/actualizar_estado_cotizacion.dart';

class CotizacionesPage extends StatefulWidget {
  const CotizacionesPage({super.key});

  @override
  State<CotizacionesPage> createState() => _CotizacionesPageState();
}

class _CotizacionesPageState extends State<CotizacionesPage> {
  final TextEditingController searchController = TextEditingController();

  late final ActualizarEstadoCotizacion actualizarEstadoUseCase;

  late final ObtenerCotizacion obtenerCotizacionesUseCase;
  List<CotizacionDto> cotizaciones = [];

  late final CotizacionRepositoryImpl repository;

  bool cargando = true;

  String searchText = '';

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
    final data = await obtenerCotizacionesUseCase();

    setState(() {
      cotizaciones = data;

      cargando = false;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<CotizacionDto> get filteredCotizaciones {
    if (searchText.isEmpty) {
      return cotizaciones;
    }

    return cotizaciones.where((cotizacion) {
      final cliente = cotizacion.clienteNombre.toLowerCase();

      final query = searchText.toLowerCase();

      return cliente.contains(query);
    }).toList();
  }

  Future<void> cambiarEstado(String id, String nuevoEstado) async {
    await actualizarEstadoUseCase(id, nuevoEstado);

    await cargarCotizacion();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cotización marcada como $nuevoEstado')),
    );
  }

  Color estadoColor(String estado) {
    switch (estado) {
      case 'Aceptada':
        return AppTheme.primary;
      case 'Rechazada':
        return AppTheme.danger;
      default:
        return AppTheme.warning;
    }
  }

  int contarPorEstado(String estado) {
    return cotizaciones.where((c) {
      return c.estado == estado;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final lista = filteredCotizaciones;

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
                color: Colors.orange[100],
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_upload_outlined, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Sincronizando datos...'),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Historial de Cotizaciones',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Revise, busque y actualice el estado de sus cotizaciones guardadas.',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 15,
                        ),
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
                              title: 'Pendientes',
                              value: contarPorEstado('Pendiente').toString(),
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
                              title: 'Aceptadas',
                              value: contarPorEstado('Aceptada').toString(),
                              icon: Icons.check_circle_outline,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ResumenCard(
                              title: 'Rechazadas',
                              value: contarPorEstado('Rechazada').toString(),
                              icon: Icons.cancel_outlined,
                              color: AppTheme.danger,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchText = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar por cliente o código...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      if (lista.isEmpty && searchText.isNotEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Text(
                              'No se encontraron cotizaciones para su búsqueda.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      else if (cargando)
                        const Center(child: CircularProgressIndicator())
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: lista.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final cotizacion = lista[index];
                            final estado = cotizacion.estado;

                            return _CotizacionCard(
                              codigo: cotizacion.codigo,
                              cliente: cotizacion.clienteNombre,
                              direccion: cotizacion.direccion,
                              fecha: cotizacion.fechaCreacion != null
                                  ? '${cotizacion.fechaCreacion!.toDate().day.toString().padLeft(2, '0')}-'
                                        '${cotizacion.fechaCreacion!.toDate().month.toString().padLeft(2, '0')}-'
                                        '${cotizacion.fechaCreacion!.toDate().year}'
                                  : '',
                              monto:
                                  '\$${cotizacion.totalFinal.toStringAsFixed(0)}',
                              estado: estado,
                              estadoColor: estadoColor(estado),
                              onAceptada: () =>
                                  cambiarEstado(cotizacion.id, 'Aceptada'),
                              onRechazada: () =>
                                  cambiarEstado(cotizacion.id, 'Rechazada'),
                              onPendiente: () =>
                                  cambiarEstado(cotizacion.id, 'Pendiente'),
                              version: cotizacion.version,
                              onEditar: () async {
                                if (cotizacion.estado == 'Rechazada') {
                                  await repository.crearNuevaVersion(
                                    cotizacion.id,
                                  );
                                }

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Edición próximamente'),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
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
  final VoidCallback onAceptada;
  final VoidCallback onRechazada;
  final VoidCallback onPendiente;
  final VoidCallback onEditar;
  final int version;

  const _CotizacionCard({
    required this.codigo,
    required this.cliente,
    required this.direccion,
    required this.fecha,
    required this.monto,
    required this.estado,
    required this.estadoColor,
    required this.onAceptada,
    required this.onRechazada,
    required this.onPendiente,
    required this.onEditar,
    required this.version,
  });

  @override
  Widget build(BuildContext context) {
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
                backgroundColor: AppTheme.softBlue,
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
                      '$codigo  •  V$version',
                      style: const TextStyle(color: AppTheme.textGrey),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  estado,
                  style: const TextStyle(color: Colors.white),
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

          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.warning,
                        side: BorderSide(color: AppTheme.warning),
                      ),
                      onPressed: onPendiente,
                      child: const Text('Pendiente'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onAceptada,
                      child: const Text('Aceptar'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: BorderSide(color: AppTheme.danger),
                      ),
                      onPressed: onRechazada,
                      child: const Text('Rechazar'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Ver detalle'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(cliente),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Código: $codigo'),
                                Text('Dirección: $direccion'),
                                Text('Fecha: $fecha'),
                                Text('Monto: $monto'),
                                Text('Estado: $estado'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                      onPressed: onEditar,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
