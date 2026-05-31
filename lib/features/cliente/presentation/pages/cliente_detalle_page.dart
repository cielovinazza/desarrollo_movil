import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/features/cotizacion/presentation/pages/ver_pdf_page.dart';
import '../../../cliente/domain/entities/cliente.dart';
import '../../../cotizacion/data/dtos/cotizacion_dtos.dart';
import '../../../cotizacion/data/datasources/cotizacion_firebase_datasource.dart';
import '../../../../core/utils/currency_formatter.dart';

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
      clienteNombre: widget.cliente.nombre,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ficha del Cliente',
        style: TextStyle(fontWeight: FontWeight.bold),),
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
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
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

//tarjeta con info del cliente
class _ClienteCard extends StatelessWidget {
  final Cliente cliente;

  const _ClienteCard({required this.cliente});

  @override
  Widget build(BuildContext context) {
    final iniciales = cliente.nombre.isNotEmpty ? cliente.nombre.substring(0, 1).toUpperCase() : 'C';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 7, 51, 35), 
            Color.fromARGB(255, 15, 90, 58),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F5A3C).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
              
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  child: Text(
                    iniciales,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    cliente.nombre,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 230, 230, 230),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(color: Colors.white24, height: 1, thickness: 0.5)
            ),
            _infoRow(Icons.badge_outlined, 'RUT', cliente.rut),
            _infoRow(Icons.email_outlined, 'Email', cliente.correo),
            _infoRow(Icons.phone_outlined, 'Teléfono', cliente.telefono),
            _infoRow(
              Icons.location_on_outlined, 
              'Dirección', 
              cliente.direccion ?? 'No especificada',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 10),
          Text(
            '$label: ', 
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70, fontSize: 14)
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
class _CotizacionItem extends StatelessWidget {
  final CotizacionDto cotizacion;

  const _CotizacionItem({required this.cotizacion});

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Aprobada por el Cliente': return Colors.green;
      case 'Rechazada por el Cliente': return Colors.red;
      case 'En Proceso': return Colors.orange;
      case 'Enviada': return Colors.purple;
      case 'Lista para Envío': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalFormateado = '\$${CurrencyFormatter.format(cotizacion.totalFinal)} CLP';
    final colorEstado = _getEstadoColor(cotizacion.estado);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F5A3C).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.description_outlined, color: Color(0xFF0F5A3C), size: 22),
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
            Text(
              totalFormateado,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F5A3C),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorEstado.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cotizacion.estado,
                      style: TextStyle(
                        color: colorEstado, 
                        fontSize: 11, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ver. ${cotizacion.version}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: cotizacion.pdfUrl != null
            ? IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerPdfPage(
                        url: cotizacion.pdfUrl!,
                        codigoCotizacion: cotizacion.codigo,
                      ),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }
}