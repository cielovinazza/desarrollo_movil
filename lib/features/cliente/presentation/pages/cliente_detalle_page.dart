import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/features/cotizacion/presentation/pages/ver_pdf_page.dart';
import '../../../cliente/domain/entities/cliente.dart';
import '../../../cotizacion/data/dtos/cotizacion_dtos.dart';
import '../../../cotizacion/data/datasources/cotizacion_firebase_datasource.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../cotizacion/presentation/pages/crear_cotizacion_page.dart';

class DetalleClientePage extends StatefulWidget {
  final Cliente cliente;

  const DetalleClientePage({super.key, required this.cliente});

  @override
  State<DetalleClientePage> createState() => _DetalleClientePageState();
}

class _DetalleClientePageState extends State<DetalleClientePage> {
  late CotizacionFirestoreDataSource _cotizacionDataSource;
  late Future<List<CotizacionDto>> _historialCotizacionesFuture;

  @override
  void initState() {
    super.initState();
    _cotizacionDataSource = CotizacionFirestoreDataSource(FirebaseFirestore.instance);
    _historialCotizacionesFuture = _cotizacionDataSource.obtenerCotizacion(
      clienteId: widget.cliente.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ficha del Cliente',),
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _ClienteCard(cliente: widget.cliente),
            const SizedBox(height: 28),
            Text(
              'Historial de Cotizaciones',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<CotizacionDto>>(
                future: _historialCotizacionesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Error al cargar cotizaciones: ${snapshot.error}',
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final cotizaciones = snapshot.data ?? [];

                  if (cotizaciones.isEmpty) {
                    return Center(
                      child: Text(
                        'Cliente sin historial de cotizaciones.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: cotizaciones.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _CotizacionItem(cotizacion: cotizaciones[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _ClienteCard extends StatelessWidget {
  final Cliente cliente;

  const _ClienteCard({required this.cliente});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final esOscuro = theme.brightness == Brightness.dark;
    final cleanRut = cliente.rut.replaceAll('.', '').replaceAll('-', '');
    final bool isEmpresa = cleanRut.startsWith('76') || cleanRut.startsWith('77');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: esOscuro ? theme.primaryColor.withValues(alpha: 0.1) :const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEmpresa ? Icons.business : Icons.person_outline,
                    color: primaryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18,
                          color: esOscuro ? Colors.white :Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'RUT: ${cliente.rut}',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color, 
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14.0),
              child: Divider(height: 1, thickness: 0.5),
            ),

            _buildInfoRow(Icons.mail_outline, cliente.correo),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone_outlined, cliente.telefono),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_outlined, cliente.direccion ?? 'Sin dirección'),
          ],
        ),
      ),
    );
  }
  Widget _buildInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey[700], 
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
class _CotizacionItem extends StatelessWidget {
  final CotizacionDto cotizacion;

  const _CotizacionItem({required this.cotizacion});

  Color _getEstadoColor(BuildContext context, String estado) {
    final theme = Theme.of(context);
    switch (estado) {
      case 'Aprobada por el Cliente':
        return theme.primaryColor;
      case 'Rechazada por el Cliente':
        return theme.colorScheme.error;
      case 'En Proceso':
        return Colors.orange;
      case 'Enviada':
        return Colors.blueGrey;
      case 'Lista para Envío':
        return theme.primaryColor.withValues(alpha: 0.7);
      default:
        return theme.hintColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalFormateado = '${CurrencyFormatter.format(cotizacion.totalFinal)} CLP';
    final colorEstado = _getEstadoColor(context, cotizacion.estado);
    final puedeEditar = cotizacion.estado == 'En Proceso' || cotizacion.estado == 'Rechazada por el Cliente';

    final bool tienePdf = cotizacion.pdfUrl != null && cotizacion.pdfUrl!.isNotEmpty;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        onTap: tienePdf
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VerPdfPage(
                      url: cotizacion.pdfUrl!,
                      codigoCotizacion: cotizacion.codigo,
                    ),
                  ),
                );
              }
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.description_outlined, color: theme.primaryColor, size: 22),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                cotizacion.codigo.isNotEmpty ? cotizacion.codigo : 'Sin Código',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                totalFormateado,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Obra: ${cotizacion.direccion}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: colorEstado,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      cotizacion.estado,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorEstado,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Ver. ${cotizacion.version}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                  if (tienePdf) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 13,
                      color: theme.hintColor,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        trailing: puedeEditar
            ? IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar cotización',
                onPressed: () async {
                  final actualizado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CrearCotizacionPage(
                        cotizacionAEditar: cotizacion,
                      ),
                    ),
                  );

                  if (actualizado == true && context.mounted) {
                    final state =
                        context.findAncestorStateOfType<_DetalleClientePageState>();

                    state?.setState(() {
                      state._historialCotizacionesFuture =
                          state._cotizacionDataSource.obtenerCotizacion(
                            clienteNombre: state.widget.cliente.nombre,
                          );
                    });
                  }
                },
              )
            : null,
      ),
    );
  }
}