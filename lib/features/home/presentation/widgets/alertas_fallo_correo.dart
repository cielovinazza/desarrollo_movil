import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/shared/design_system/app_theme.dart';

class AlertasFalloCorreo extends StatefulWidget {
  final void Function(String codigo) onReintentar;

  const AlertasFalloCorreo({super.key, required this.onReintentar});

  @override
  State<AlertasFalloCorreo> createState() => _AlertasFalloCorreoState();
}

class _AlertasFalloCorreoState extends State<AlertasFalloCorreo> {
  late final Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('historial_correos')
        .where('delivery.state', isEqualTo: 'ERROR')
        .snapshots();
  }

  String _extraerCodigo(String asunto) {
    final match = RegExp(r'N°(\S+)').firstMatch(asunto);
    if (match != null) return match.group(1)!;
    return asunto.isNotEmpty ? asunto : 'Sin código';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esOscuro = theme.brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: esOscuro
                ? AppTheme.danger.withValues(alpha: 0.12)
                : AppTheme.danger.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.danger.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      color: AppTheme.danger,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Alertas Pendientes',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${docs.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final asunto =
                      (data['message']?['subject'] as String?) ?? '';
                  final codigo = _extraerCodigo(asunto);

                  return _AlertaItem(
                    codigo: codigo,
                    onReintentar: () => widget.onReintentar(codigo),
                  );
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}

class _AlertaItem extends StatelessWidget {
  final String codigo;
  final VoidCallback onReintentar;

  const _AlertaItem({required this.codigo, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onReintentar,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.danger.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Fallo al enviar $codigo. Toca para reintentar.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.refresh, color: AppTheme.danger, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
