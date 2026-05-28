import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../cliente/domain/entities/cliente.dart';
import '../../../cotizacion/data/dtos/cotizacion_dtos.dart';
import '../../../cotizacion/data/datasources/cotizacion_firebase_datasource.dart';

class DetalleClientePage extends StatefulWidget {
  final Cliente cliente;

  const DetalleClientePage({Key? key, required this.cliente}) : super(key: key);

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
        title: const Text('Ficha del Cliente'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClienteCard(context),
            const SizedBox(height: 24),
            Text(
              'Historial de Cotizaciones',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
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
                      child: SingleChildScrollView(
                        child: Text(
                          'Error al cargar cotizaciones: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
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
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: cotizaciones.length,
                    itemBuilder: (context, index) {
                      final cotizacion = cotizaciones[index];
                      return _buildCotizacionItem(cotizacion);
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

  Widget _buildClienteCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.cliente.nombre,
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.badge_outlined, 'RUT:', widget.cliente.rut),
            _buildInfoRow(Icons.email_outlined, 'Email:', widget.cliente.correo),
            _buildInfoRow(Icons.phone_outlined, 'Teléfono:', widget.cliente.telefono),
            _buildInfoRow(
              Icons.location_on_outlined, 
              'Dirección:', 
              widget.cliente.direccion ?? 'No especificada',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(color: Colors.grey[800]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCotizacionItem(CotizacionDto cotizacion) {
    final totalFormateado = '\$${cotizacion.totalFinal.toStringAsFixed(0)}';
    final theme = Theme.of(context);
    
    Color estadoColor = Colors.grey;
    if (cotizacion.estado == 'Aprobada por el Cliente') estadoColor = Colors.green;
    if (cotizacion.estado == 'Rechazada por el Cliente') estadoColor = Colors.red;
    if (cotizacion.estado == 'En Proceso') estadoColor = Colors.orange;
    if (cotizacion.estado == 'Enviada') estadoColor = Colors.purple;
    if (cotizacion.estado == 'Lista para Envío') estadoColor = Colors.blue;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.description_rounded, color: theme.colorScheme.primary),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                cotizacion.codigo.isNotEmpty ? cotizacion.codigo : 'Sin Código',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              totalFormateado,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Obra: ${cotizacion.direccion}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: estadoColor),
                      ),
                      child: Text(
                        cotizacion.estado,
                        style: TextStyle(color: estadoColor, fontSize: 11, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ver. ${cotizacion.version}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: cotizacion.pdfUrl != null //implementar visualizacion de pdf, con opcion para enviar correo automatico
            ? IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                onPressed: () {},
              )
            : null,
      ),
    );
  }
}