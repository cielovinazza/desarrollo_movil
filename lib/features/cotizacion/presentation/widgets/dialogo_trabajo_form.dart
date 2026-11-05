
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/clp_input_formatter.dart';
import '../../domain/entities/cotizacion_model.dart';

class DialogoTrabajoForm extends StatefulWidget {
  final List<String> tiposDisponibles;
  final Color verdeApp;
  final void Function(ItemTrabajo trabajo) onGuardar;
  final void Function(String nuevoTipo) onNuevoTipoCreado;
  final ItemTrabajo? trabajoEditando;

  const DialogoTrabajoForm({
    super.key,
    required this.tiposDisponibles,
    required this.verdeApp,
    required this.onGuardar,
    required this.onNuevoTipoCreado,
    this.trabajoEditando,
  });

  @override
  State<DialogoTrabajoForm> createState() => _DialogoTrabajoFormState();
}

class _DialogoTrabajoFormState extends State<DialogoTrabajoForm> {
  final m2ItemController = TextEditingController();
  final precioItemController = TextEditingController();
  final descripcionItemController = TextEditingController();

  bool esPrecioFijo = false;
  String? tipoTrabajoSeleccionado;

  String? errorNombre;
  String? errorM2;
  String? errorPrecio;

  bool get estaEditando => widget.trabajoEditando != null;

  @override
  void initState() {
    super.initState();

    final trabajo = widget.trabajoEditando;

    if (trabajo != null) {
      tipoTrabajoSeleccionado = trabajo.tipo;
      esPrecioFijo = trabajo.esPrecioFijo;

      m2ItemController.text = trabajo.metrosCuadrados == 0
          ? ''
          : _formatearNumero(trabajo.metrosCuadrados);

      precioItemController.text = esPrecioFijo
          ? trabajo.precioFijo.toStringAsFixed(0)
          : trabajo.precioPorMetro.toStringAsFixed(0);

      descripcionItemController.text =
          trabajo.descripcionBreve ?? '';
    } else if (widget.tiposDisponibles.isNotEmpty) {
      tipoTrabajoSeleccionado = widget.tiposDisponibles.first;
    }
  }

  String _formatearNumero(double valor) {
    return valor.toString().replaceAll('.', ',');
  }

  double? _parsearDecimal(String valor) {
    return double.tryParse(
      valor.trim().replaceAll(',', '.'),
    );
  }

  @override
  void dispose() {
    m2ItemController.dispose();
    precioItemController.dispose();
    descripcionItemController.dispose();
    super.dispose();
  }


Future<void> _mostrarDialogoCrearTipoTrabajo() async {
  final nuevoTipoController = TextEditingController();
  final formKeyTipo = GlobalKey<FormState>();

  final nuevoTipo = await showDialog<String>(
    context: context,
    builder: (subContext) {
      return AlertDialog(
        title: const Text('Nuevo tipo de trabajo'),
        content: Form(
          key: formKeyTipo,
          child: TextFormField(
            controller: nuevoTipoController,
            autofocus: true,
            maxLength: 100,
            validator: (value) {
              final nombre = value?.trim() ?? '';

              if (nombre.isEmpty) {
                return 'Por favor, ingrese un nombre';
              }

              if (nombre.length < 3) {
                return 'El nombre debe tener al menos 3 caracteres';
              }

              final existe = widget.tiposDisponibles.any(
                (tipo) =>
                    tipo.trim().toLowerCase() ==
                    nombre.toLowerCase(),
              );

              if (existe) {
                return 'Este tipo de trabajo ya existe';
              }

              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Nombre del tipo de trabajo',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(subContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.verdeApp,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKeyTipo.currentState!.validate()) {
                Navigator.pop(
                  subContext,
                  nuevoTipoController.text.trim(),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      );
    },
  );

  // Esperar a que termine de cerrarse el diálogo antes de liberar
  // el controlador.
  await Future<void>.delayed(Duration.zero);

  nuevoTipoController.dispose();

  if (!mounted || nuevoTipo == null) return;

  setState(() {
    tipoTrabajoSeleccionado = nuevoTipo;
    errorNombre = null;
  });

  // Notificar a la pantalla principal después de actualizar
  // el estado del formulario.
  widget.onNuevoTipoCreado(nuevoTipo);
}

  void _guardarTrabajo() {
    final nombre = tipoTrabajoSeleccionado?.trim() ?? '';
    final m2Texto = m2ItemController.text.trim();
    final precioTexto = precioItemController.text.trim();
    final descripcion = descripcionItemController.text.trim();

    final m2 = _parsearDecimal(m2Texto);
    final precio = ClpInputFormatter.toDouble(precioTexto);

    String? nuevoErrorNombre;
    String? nuevoErrorM2;
    String? nuevoErrorPrecio;

    if (nombre.isEmpty) {
      nuevoErrorNombre = 'Debe seleccionar un tipo de trabajo';
    }

    if (!esPrecioFijo) {
      if (m2Texto.isEmpty) {
        nuevoErrorM2 = 'Debe ingresar los metros cuadrados';
      } else if (m2 == null || !m2.isFinite || m2 <= 0) {
        nuevoErrorM2 = 'Ingrese una cantidad válida';
      }
    }

    if (precioTexto.isEmpty) {
      nuevoErrorPrecio = esPrecioFijo
          ? 'Debe ingresar el precio total'
          : 'Debe ingresar el precio por m²';
    } else if (precio <= 0) {
      nuevoErrorPrecio = 'Ingrese un precio positivo válido';
    }

    setState(() {
      errorNombre = nuevoErrorNombre;
      errorM2 = nuevoErrorM2;
      errorPrecio = nuevoErrorPrecio;
    });

    if (nuevoErrorNombre != null ||
        nuevoErrorM2 != null ||
        nuevoErrorPrecio != null) {
      return;
    }

    final trabajo = ItemTrabajo(
      tipo: nombre,
      metrosCuadrados: esPrecioFijo ? 0 : m2!,
      precioPorMetro: esPrecioFijo ? 0 : precio,
      precioFijo: esPrecioFijo ? precio : 0,
      esPrecioFijo: esPrecioFijo,
      descripcionBreve: descripcion.isEmpty ? null : descripcion,
    );

    widget.onGuardar(trabajo);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Evita duplicados sin distinguir mayúsculas y minúsculas.
    final tipos = <String>[];

    for (final tipo in widget.tiposDisponibles) {
      if (!tipos.any(
        (existente) =>
            existente.toLowerCase() == tipo.toLowerCase(),
      )) {
        tipos.add(tipo);
      }
    }

    // Permite mostrar el tipo seleccionado aunque no esté en la lista.
    if (tipoTrabajoSeleccionado != null &&
        !tipos.any(
          (tipo) =>
              tipo.toLowerCase() ==
              tipoTrabajoSeleccionado!.toLowerCase(),
        )) {
      tipos.add(tipoTrabajoSeleccionado!);
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            estaEditando ? Icons.edit : Icons.add_task,
            color: widget.verdeApp,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              estaEditando ? 'Editar trabajo' : 'Añadir trabajo',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Por m²'),
                  icon: Icon(Icons.square_foot),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Precio fijo'),
                  icon: Icon(Icons.price_check),
                ),
              ],
              selected: {esPrecioFijo},
              onSelectionChanged: (seleccion) {
                setState(() {
                  esPrecioFijo = seleccion.first;
                  errorM2 = null;
                  errorPrecio = null;
                  precioItemController.clear();
                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: tipos.contains(tipoTrabajoSeleccionado)
                  ? tipoTrabajoSeleccionado
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Tipo de trabajo',
                prefixIcon: const Icon(Icons.work_outline),
                border: const OutlineInputBorder(),
                errorText: errorNombre,
              ),
              hint: const Text('Seleccione un trabajo'),
              items: tipos.map((tipo) {
                return DropdownMenuItem<String>(
                  value: tipo,
                  child: Text(
                    tipo,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: (nuevoTipo) {
                setState(() {
                  tipoTrabajoSeleccionado = nuevoTipo;
                  errorNombre = null;
                });
              },
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _mostrarDialogoCrearTipoTrabajo,
                icon: const Icon(Icons.add),
                label: const Text('Crear nuevo tipo'),
              ),
            ),

            if (!esPrecioFijo) ...[
              const SizedBox(height: 8),
              TextField(
                controller: m2ItemController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9,.]'),
                  ),
                ],
                decoration: InputDecoration(
                  labelText: 'Cantidad de metros cuadrados (m²)',
                  hintText: 'Ej: 10,75',
                  prefixIcon: const Icon(Icons.square_foot),
                  border: const OutlineInputBorder(),
                  errorText: errorM2,
                ),
                onChanged: (_) {
                  if (errorM2 != null) {
                    setState(() => errorM2 = null);
                  }
                },
              ),
            ],

            const SizedBox(height: 16),

            TextField(
              controller: precioItemController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                ClpInputFormatter(maxDigits: 9),
              ],
              decoration: InputDecoration(
                labelText: esPrecioFijo
                    ? 'Precio total (CLP)'
                    : 'Precio por m² (CLP)',
                prefixIcon: const Icon(Icons.sell_outlined),
                border: const OutlineInputBorder(),
                errorText: errorPrecio,
              ),
              onChanged: (_) {
                if (errorPrecio != null) {
                  setState(() => errorPrecio = null);
                }
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: descripcionItemController,
              maxLength: 200,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción breve (Opcional)',
                hintText: 'Ej: Aplicación de dos manos de pintura...',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _guardarTrabajo,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.verdeApp,
            foregroundColor: Colors.white,
          ),
          child: Text(
            estaEditando ? 'Guardar cambios' : 'Guardar ítem',
          ),
        ),
      ],
    );
  }
}
