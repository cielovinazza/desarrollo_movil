import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:project/features/materiales/domain/entities/material.dart';
import 'package:project/features/materiales/utils/csv_parser.dart';
import '../../../../core/utils/currency_formatter.dart';

class MaterialLista extends StatelessWidget {
  final List<MaterialEntity> items;
  final Color verdeApp;
  final VoidCallback onAgregar;
  final Function(int) onEliminar;
  final Function(int) onEditar;
  final Function(List<MaterialEntity>) onImportarCSV;

  const MaterialLista({
    super.key,
    required this.items,
    required this.verdeApp,
    required this.onAgregar,
    required this.onEliminar,
    required this.onEditar,
    required this.onImportarCSV,
  });

  double get total => items.fold(0.0, (suma, m) => suma + m.subtotal);

  Future<void> _seleccionarCSV(BuildContext context) async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (resultado == null || resultado.files.isEmpty) return;

    final archivo = resultado.files.first;
    if (archivo.bytes == null) return;

    if (!context.mounted) return;

    _procesarCSV(context, utf8.decode(archivo.bytes!));
  }

  void _procesarCSV(BuildContext context, String contenido) {
    final parseado = parsearCSV(contenido);
    onImportarCSV(parseado.materialesValidos);

    final tieneErrorEncabezado =
        parseado.filasRechazadas.isNotEmpty &&
        parseado.filasRechazadas.first.contains('Encabezado inválido');

    if (tieneErrorEncabezado) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Error en encabezados'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'El archivo CSV no tiene los encabezados correctos.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('Se requieren exactamente estos encabezados:'),
              const SizedBox(height: 8),
              _encabezadoRequerido('Nombre_Material'),
              _encabezadoRequerido('Unidad_Medida'),
              _encabezadoRequerido('Costo_Unitario_CLP'),
              const SizedBox(height: 12),
              const Text(
                'Verifica mayúsculas, guiones bajos y espacios.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    if (parseado.filasRechazadas.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) {
          final esOscuroDialog = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(child: Text('Importación parcial')),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Importados: ${parseado.materialesValidos.length}',
                    style: TextStyle(
                      color: esOscuroDialog ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Rechazados: ${parseado.filasRechazadas.length}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Filas con error:',
                    style: TextStyle(
                      color: esOscuroDialog ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: parseado.filasRechazadas.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '• ${parseado.filasRechazadas[i]}',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: esOscuroDialog
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          );
        },
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          'Se importaron ${parseado.materialesValidos.length} materiales correctamente',
        ),
      ),
    );
  }

  Widget _encabezadoRequerido(String nombre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_box_outline_blank,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            nombre,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
              'Materiales',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _seleccionarCSV(context),
                  icon: const Icon(Icons.upload_file_outlined, size: 16),
                  label: const Text(
                    'CSV',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: verdeApp,
                    side: BorderSide(color: verdeApp, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                    Icons.inventory_2_outlined,
                    color: Colors.grey,
                    size: 36,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No has añadido materiales todavía.',
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

        if (items.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final material = items[index];

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: esOscuro
                          ? Colors.grey.shade700
                          : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.02,
                        ),
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
                        Icons.inventory_2_outlined,
                        color: verdeApp,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      material.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: esOscuro ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${material.cantidad.toStringAsFixed(0)} ${material.unidadMedida} × ${CurrencyFormatter.format(material.costoUnitario)}',
                        style: TextStyle(
                          color: esOscuro
                              ? Colors.white70
                              : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyFormatter.format(material.subtotal),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: esOscuro ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.orange,
                            size: 20,
                          ),
                          onPressed: () => onEditar(index),
                        ),
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
              },
            ),
          ),
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
                'Total Materiales:',
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
