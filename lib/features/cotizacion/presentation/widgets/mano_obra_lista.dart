import 'package:flutter/material.dart';
import '../../domain/entities/mano_de_obra.dart';
import '../../../../core/utils/currency_formatter.dart';

class ManoObraLista extends StatelessWidget {
  final List<ManoDeObra> items;

  final VoidCallback onAgregar;

  final Function(int) onEliminar;

  final Color verdeApp;

  const ManoObraLista({
    super.key,
    required this.items,
    required this.onAgregar,
    required this.onEliminar,
    required this.verdeApp,
  });

  double get total {
    return items.fold<double>(0, (sum, item) => sum + item.subtotal);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esOscuro = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Text(
              'Personal Asignado',

              style: TextStyle(
                fontWeight: FontWeight.bold,

                fontSize: 16,

              ),
            ),

            OutlinedButton.icon(
              onPressed: onAgregar,

              icon: const Icon(Icons.add, size: 16),

              label: const Text(
                'Añadir',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              style: OutlinedButton.styleFrom(
                foregroundColor: verdeApp,

                side: BorderSide(color: verdeApp, width: 1.5),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),

                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),

        const Divider(height: 20, thickness: 1),

        if (items.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),

              child: Column(
                children: const [
                  Icon(
                    Icons.assignment_late_outlined,
                    color: Colors.grey,
                    size: 36,
                  ),

                  SizedBox(height: 8),

                  Text(
                    'No has añadido personal todavía.',

                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

        ...items.asMap().entries.map((entry) {
          int index = entry.key;

          ManoDeObra item = entry.value;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),

            decoration: BoxDecoration(
              color: theme.cardColor,

              borderRadius: BorderRadius.circular(10),

              border: Border.all(
                color: esOscuro ? Colors.grey.shade700 : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.02),
                  blurRadius: 4,

                  offset: const Offset(0, 2),
                ),
              ],
            ),

            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),

              leading: Container(
                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(
                  color: verdeApp.withValues(alpha: 0.1),

                  shape: BoxShape.circle,
                ),

                child: Icon(
                  Icons.engineering_outlined,

                  color: verdeApp,

                  size: 22,
                ),
              ),

              title: Text(
                item.cargo,

                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,

                  fontSize: 15,
                ),
              ),

              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),

                child: Text(
                  '${item.dias.toStringAsFixed(0)} días × ${CurrencyFormatter.format(item.valorJornada)}',

                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Text(
                    CurrencyFormatter.format(item.subtotal),

                    style: TextStyle(
                      fontWeight: FontWeight.bold,

                      fontSize: 15,

                      color: esOscuro ? Colors.white : Colors.black87,
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,

                      color: Colors.redAccent,

                      size: 22,
                    ),

                    onPressed: () => onEliminar(index),
                  ),
                ],
              ),
            ),
          );
        }),

        if (items.isNotEmpty) const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: verdeApp.withValues(alpha: 0.06),

            borderRadius: BorderRadius.circular(10),

            border: Border.all(color: verdeApp.withValues(alpha: 0.2)),
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                'Subtotal Mano de Obra:',

                style: TextStyle(
                  fontWeight: FontWeight.bold,

                  color: verdeApp,

                  fontSize: 14,
                ),
              ),

              Text(
                '${CurrencyFormatter.format(total)} CLP',

                style: TextStyle(
                  fontWeight: FontWeight.bold,

                  color: verdeApp,

                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
