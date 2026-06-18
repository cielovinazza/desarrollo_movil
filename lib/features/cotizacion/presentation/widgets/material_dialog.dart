import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/features/materiales/domain/entities/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/clp_input_formatter.dart';
import '../../../../shared/widgets/boton_bloqueo_visual.dart';

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
  final _cantidadController = TextEditingController();
  final _costoController = TextEditingController();


  final List<String> _unidadesDisponibles = [
    'kg',
    'm²',
    'm³',
    'unidad',
    'saco',
    'litro',
    'global',
    'tira',
    'plancha'
  ];

  String? _unidadSeleccionada;
  double _subtotal = 0;
  bool _formValido = false;

  @override
  void initState() {
    super.initState();

    if (widget.materialEditando != null) {
      final m = widget.materialEditando!;
      _nombreController.text = m.nombre;
      _cantidadController.text = m.cantidad.toString();
      _costoController.text = ClpInputFormatter.formatNumber(m.costoUnitario);
      
      if (!_unidadesDisponibles.contains(m.unidadMedida)) {
        _unidadesDisponibles.add(m.unidadMedida);
      }
      _unidadSeleccionada = m.unidadMedida;
      _calcularSubtotal();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cantidadController.dispose();
    _costoController.dispose();
    super.dispose();
  }

  void _validarFormulario() {
    final valido = _formKey.currentState?.validate() ?? false;

    if (_formValido != valido) {
      setState(() => _formValido = valido);
    }
  }

  void _calcularSubtotal() {
    final cantidad = double.tryParse(_cantidadController.text) ?? 0;
    final costo = ClpInputFormatter.toDouble(_costoController.text);
    setState(() {
      _subtotal = cantidad * costo;
    });
  }

  void _mostrarDialogoNuevaUnidad() {
    final nuevaUnidadController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva Unidad de Medida', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: nuevaUnidadController,
            textCapitalization: TextCapitalization.none,
            decoration: const InputDecoration(
              labelText: 'Ej: caja, rollo, m, par',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final texto = nuevaUnidadController.text.trim();
                if (texto.isNotEmpty) {
                  setState(() {
                    if (!_unidadesDisponibles.contains(texto)) {
                      _unidadesDisponibles.add(texto);
                    }
                    _unidadSeleccionada = texto;
                  });
                  _validarFormulario();
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: widget.verdeApp, foregroundColor: Colors.white),
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
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
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: _validarFormulario,
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
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresa el nombre'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unidadSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Unidad de medida',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      hint: const Text('Selecciona u. de medida'),
                      items: _unidadesDisponibles.map((String unidad) {
                        return DropdownMenuItem<String>(
                          value: unidad,
                          child: Text(unidad),
                        );
                      }).toList(),
                      onChanged: (String? nuevoValor) {
                        setState(() {
                          _unidadSeleccionada = nuevoValor;
                        });
                        _validarFormulario();
                      },
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingresa la unidad'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.verdeApp.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add, color: widget.verdeApp),
                        onPressed: _mostrarDialogoNuevaUnidad,
                        tooltip: 'Añadir nueva unidad',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _cantidadController,
                inputFormatters: [LengthLimitingTextInputFormatter(3)],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (v) => _calcularSubtotal(),
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  hintText: 'Ej: 10',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa la cantidad';
                  }
                  final n = double.tryParse(value);
                  if (n == null || n <= 0) return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [ClpInputFormatter(maxDigits: 9)],
                onChanged: (_) {
                  _calcularSubtotal();
                },
                decoration: const InputDecoration(
                  labelText: 'Costo unitario (CLP)',
                  hintText: 'Ej: 5500',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el costo';
                  }
                  final n = ClpInputFormatter.toDouble(value);
                  if (n <= 0) return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.verdeApp.withAlpha((0.08 * 255).toInt()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Subtotal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${CurrencyFormatter.format(_subtotal)} CLP',
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
        BotonBloqueoVisual(
          habilitado: _formValido,
          onPressed: () {
            if (!_formKey.currentState!.validate() || _unidadSeleccionada == null) {
              return;
            }

            final material = MaterialEntity(
              nombre: _nombreController.text.trim(),
              unidadMedida: _unidadSeleccionada!,
              cantidad: double.parse(_cantidadController.text),
              costoUnitario: ClpInputFormatter.toDouble(_costoController.text),
            );

            Navigator.pop(context, material);
          },
          texto: 'Guardar',
          colorActivo: widget.verdeApp,
        ),
      ],
    );
  }
}