import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/shared/design_system/app_theme.dart';
import '../widgets/alertas_fallo_correo.dart';

class NotificacionesPage extends StatelessWidget {
  final void Function(String codigo) onReintentarEnvio;

  const NotificacionesPage({super.key, required this.onReintentarEnvio});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('historial_correos')
            .where('delivery.state', isEqualTo: 'ERROR')
            .snapshots(),
        builder: (context, snapshot) {
          final theme = Theme.of(context);
          final tieneDatos =
              snapshot.hasData && snapshot.data!.docs.isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          color: AppTheme.danger,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Correos con fallo de envío',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toca cualquier alerta para reintentar el envío.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    if (!snapshot.hasData)
                      const Center(child: CircularProgressIndicator())
                    else if (!tieneDatos)
                      _EmptyState()
                    else
                      AlertasFalloCorreo(onReintentar: onReintentarEnvio),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 64,
              color: theme.primaryColor.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin notificaciones',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Todos los correos se enviaron correctamente.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}