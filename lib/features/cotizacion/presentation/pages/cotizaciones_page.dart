import 'package:flutter/material.dart';
import 'package:project/shared/design_system/app_theme.dart';
import 'crear_cotizacion_page.dart';
import 'package:project/features/cotizacion/data/cotizaciones_memoria.dart';

class CotizacionesPage extends StatefulWidget {
  const CotizacionesPage({super.key});

  @override
  State<CotizacionesPage> createState() => _CotizacionesPageState();
}

class _CotizacionesPageState extends State<CotizacionesPage> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, String>> get cotizaciones =>
    CotizacionesMemoria.lista;

  String searchText = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get filteredCotizaciones {
    if (searchText.isEmpty) return cotizaciones;

    return cotizaciones.where((cotizacion) {
      final cliente = cotizacion['cliente']!.toLowerCase();
      final codigo = cotizacion['codigo']!.toLowerCase();
      final query = searchText.toLowerCase();

      return cliente.contains(query) || codigo.contains(query);
    }).toList();
  }

  void cambiarEstado(int index, String nuevoEstado) {
    setState(() {
      cotizaciones[index]['estado'] = nuevoEstado;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cotización marcada como $nuevoEstado'),
      ),
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
    return cotizaciones.where((c) => c['estado'] == estado).length;
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
          final nuevaCotizacion = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CrearCotizacionPage(),
            ),
          );

          if (nuevaCotizacion != null) {
            setState(() {
              cotizaciones.insert(0, {
                'codigo': 'COT-00${cotizaciones.length + 1}',
                'cliente': nuevaCotizacion['cliente'] ?? 'Cliente Nuevo',
                'direccion': nuevaCotizacion['direccion']?? 'Dirección Nueva',
                'fecha': nuevaCotizacion['fecha'] ?? 'Hoy',
                'monto': nuevaCotizacion['monto'] ?? '\$0',
                'estado': 'Pendiente',
              });
            });
          }
        },
      ),

      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: const Text(
          'Cotizaciones',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
      ),
      body: SingleChildScrollView(
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

                if (lista.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Text('No se encontraron cotizaciones'),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final cotizacion = lista[index];
                      final estado = cotizacion['estado']!;
                      final realIndex = cotizaciones.indexOf(cotizacion);

                      return _CotizacionCard(
                        codigo: cotizacion['codigo']!,
                        cliente: cotizacion['cliente']!,
                        direccion: cotizacion['direccion']!,
                        fecha: cotizacion['fecha']!,
                        monto: cotizacion['monto']!,
                        estado: estado,
                        estadoColor: estadoColor(estado),
                        onAceptada: () => cambiarEstado(realIndex, 'Aceptada'),
                        onRechazada: () => cambiarEstado(realIndex, 'Rechazada'),
                        onPendiente: () => cambiarEstado(realIndex, 'Pendiente'),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
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
            color: color.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),

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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                      codigo,
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                      ),
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
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
              ),
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
                        side: BorderSide(
                          color: AppTheme.warning,
                        ),
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
                        side: BorderSide(
                          color: AppTheme.danger,
                        ),
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
                      icon: const Icon(
                        Icons.visibility_outlined,
                      ),
                      label: const Text(
                        'Ver detalle',
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(cliente),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
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
                                onPressed: () =>
                                    Navigator.pop(context),
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
                      icon: const Icon(
                        Icons.edit_outlined,
                      ),
                      label: const Text('Editar'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Edición próximamente',
                            ),
                          ),
                        );
                      },
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