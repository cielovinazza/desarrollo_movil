import 'package:flutter/material.dart';
import 'package:project/features/materiales/domain/entities/material.dart';

class MaterialDialog extends StatefulWidget {
  final Color verdeApp;
  final MaterialEntity? materialEditando;

  const MaterialDialog({
    super.key,
    required this.verdeApp,
    this.materialEditando,
  });

  @override
  State<MaterialDialog> createState() => _MaterialDialogState();
}

class _MaterialDialogState extends State<MaterialDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _unidadController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _costoController = TextEditingController();

  double _subtotal = 0;

  @override
  void initState() {
    super.initState();

    if (widget.materialEditando != null) {
      final m = widget.materialEditando!;
      _nombreController.text = m.nombre;
      _unidadController.text = m.unidadMedida;
      _cantidadController.text = m.cantidad.toString();
      _costoController.text = m.costoUnitario.toString();
      _calcularSubtotal();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _unidadController.dispose();
    _cantidadController.dispose();
    _costoController.dispose();
    super.dispose();
  }

  void _calcularSubtotal() {
    final cantidad = double.tryParse(_cantidadController.text) ?? 0;
    final costo = double.tryParse(_costoController.text) ?? 0;
    setState(() {
      _subtotal = cantidad * costo;
    });
  }

  void _filtrarNumero(TextEditingController controller, String value) {
    final filtrado = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (filtrado != value) {
      controller.value = TextEditingValue(
        text: filtrado,
        selection: TextSelection.collapsed(offset: filtrado.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.materialEditando != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.inventory_2_outlined, color: widget.verdeApp),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              esEdicion ? 'Editar Material' : 'Agregar Material',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del material',
                  hintText: 'Ej: Cemento, Arena, Tubo PVC',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unidadController,
                decoration: const InputDecoration(
                  labelText: 'Unidad de medida',
                  hintText: 'Ej: kg, m², saco, unidad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Ingresa la unidad' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cantidadController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) {
                  _filtrarNumero(_cantidadController, v);
                  _calcularSubtotal();
                },
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  hintText: 'Ej: 10',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa la cantidad';
                  final n = double.tryParse(value);
                  if (n == null || n <= 0) return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) {
                  _filtrarNumero(_costoController, v);
                  _calcularSubtotal();
                },
                decoration: const InputDecoration(
                  labelText: 'Costo unitario (CLP)',
                  hintText: 'Ej: 5500',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa el costo';
                  final n = double.tryParse(value);
                  if (n == null || n <= 0) return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.verdeApp.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      '\$${_subtotal.toStringAsFixed(0)} CLP',
                      style: TextStyle(
                        color: widget.verdeApp,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final material = MaterialEntity(
              nombre: _nombreController.text.trim(),
              unidadMedida: _unidadController.text.trim(),
              cantidad: double.parse(_cantidadController.text),
              costoUnitario: double.parse(_costoController.text),
            );
            Navigator.pop(context, material);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.verdeApp,
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}