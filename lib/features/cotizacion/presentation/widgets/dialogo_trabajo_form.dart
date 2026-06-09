import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/clp_input_formatter.dart';

class DialogoTrabajoForm extends StatefulWidget {
  final List<String> tiposDisponibles;
  final Color verdeApp;
  final void Function(String tipo, double m2, double precio, String descripcion) onGuardar;
  final void Function(String nuevoTipo) onNuevoTipoCreado;

  const DialogoTrabajoForm({
    super.key,
    required this.tiposDisponibles,
    required this.verdeApp,
    required this.onGuardar,
    required this.onNuevoTipoCreado,
  });

  @override
  State<DialogoTrabajoForm> createState() => _DialogoTrabajoFormState();
}

class _DialogoTrabajoFormState extends State<DialogoTrabajoForm> {
  late String tipoSeleccionado;
  final m2ItemController = TextEditingController();
  final precioItemController = TextEditingController();
  final descripcionItemController = TextEditingController();
  String? errorM2;
  String? errorPrecio;

  @override
  void initState() {
    super.initState();
    tipoSeleccionado = widget.tiposDisponibles.first;
  }

  @override
  void dispose() {
    m2ItemController.dispose();
    precioItemController.dispose();
    descripcionItemController.dispose();
    super.dispose();
  }

  void _mostrarDialogoCrearTipoTrabajo() {
    final nuevoTipoController = TextEditingController();
    final formKeyTipo = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (subContext) => AlertDialog(
        title: const Text('Nuevo tipo de trabajo'),
        content: Form(
          key: formKeyTipo,
          child: TextFormField(
            controller: nuevoTipoController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, ingrese un nombre';
              }
              if (value.trim().length < 3) {
                return 'El nombre debe tener al menos 3 caracteres';
              }
              if (value.trim().length > 100) {
                return 'El nombre no puede exceder los 100 caracteres';
              }
              return null;
            },
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-ZñÑáéíóúÉÁÍÚÓ ]'),
              ),
            ],
            decoration: const InputDecoration(
              labelText: 'Nombre del tipo de trabajo',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(subContext).pop();
              nuevoTipoController.dispose();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.verdeApp,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKeyTipo.currentState!.validate()) {
                final nuevoTipo = nuevoTipoController.text.trim();
                widget.onNuevoTipoCreado(nuevoTipo);
                setState(() {
                  tipoSeleccionado = nuevoTipo;
                });
                Navigator.of(subContext).pop();
                nuevoTipoController.dispose();
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.add_task, color: widget.verdeApp),
          const SizedBox(width: 10),
          const Text(
            'Añadir Trabajo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: widget.tiposDisponibles.contains(tipoSeleccionado)
                  ? tipoSeleccionado
                  : widget.tiposDisponibles.first,
              decoration: const InputDecoration(
                labelText: 'Tipo de Rubro',
                border: OutlineInputBorder(),
              ),
              items: widget.tiposDisponibles
                  .map(
                    (tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => tipoSeleccionado = value);
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _mostrarDialogoCrearTipoTrabajo,
                icon: const Icon(Icons.add),
                label: const Text('Crear nuevo tipo'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: m2ItemController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                LengthLimitingTextInputFormatter(3),
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Cantidad Metros Cuadrados (m²)',
                prefixIcon: const Icon(Icons.square_foot),
                border: const OutlineInputBorder(),
                errorText: errorM2,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: precioItemController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              inputFormatters: [ClpInputFormatter(maxDigits: 9)],
              decoration: InputDecoration(
                labelText: 'Precio por m² (CLP)',
                prefixIcon: const Icon(Icons.sell_outlined),
                border: const OutlineInputBorder(),
                errorText: errorPrecio,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descripcionItemController,
              maxLength: 200,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción breve (Opcional)',
                hintText: 'Ej: Aplicación de dos manos de pintura látex...',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            final m2Texto = m2ItemController.text.trim();
            final precioTexto = precioItemController.text.trim();
            final descripcionTexto = descripcionItemController.text.trim();

            final m2 = double.tryParse(m2Texto);
            final precio = ClpInputFormatter.toDouble(precioTexto);

            setState(() {
              errorM2 = null;
              errorPrecio = null;

              if (m2Texto.isEmpty) {
                errorM2 = 'Debe ingresar la cantidad de metros cuadrados';
              } else if (m2 == null || m2 <= 0) {
                errorM2 = 'Ingrese un número positivo válido';
              }

              if (precioTexto.isEmpty) {
                errorPrecio = 'Debe ingresar el precio por m²';
              } else if (precio <= 0) {
                errorPrecio = 'Ingrese un precio positivo válido';
              }
            });

            if (errorM2 != null || errorPrecio != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Formulario incompleto, debe rellenar los campos para continuar',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            widget.onGuardar(tipoSeleccionado, m2!, precio, descripcionTexto);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.verdeApp,
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar Ítem'),
        ),
      ],
    );
  }
}

