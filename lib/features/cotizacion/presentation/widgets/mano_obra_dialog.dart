import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/mano_de_obra.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/clp_input_formatter.dart';

class ManoObraDialog extends StatefulWidget {
  final Color verdeApp;

  const ManoObraDialog({super.key, required this.verdeApp});

  @override
  State<ManoObraDialog> createState() => _ManoObraDialogState();
}

class _ManoObraDialogState extends State<ManoObraDialog> {
  final List<String> cargosDisponibles = [
    'Pintor',
    'Yesero',
    'Supervisor',
    'Maestro',
    'Ayudante',
    'Ceramista',
    'Electricista',
    'Gasfíter',
    'Carpintero',
    'Albañil',
  ];

  late String cargoSeleccionado;

  final _formKey = GlobalKey<FormState>();

  final valorJornadaController = TextEditingController();
  final diasController = TextEditingController();

  double subtotal = 0;

  @override
  void initState() {
    super.initState();
    cargoSeleccionado = cargosDisponibles.first;
  }

  @override
  void dispose() {
    valorJornadaController.dispose();
    diasController.dispose();
    super.dispose();
  }

  void calcularSubtotal() {
    final valor = ClpInputFormatter.toDouble(valorJornadaController.text);
    final dias = int.tryParse(diasController.text) ?? 0;

    setState(() {
      subtotal = (valor * dias).toDouble();
    });
  }

  void _mostrarDialogoCrearCargo() {
    final nuevoCargoController = TextEditingController();
    final formCargoKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo cargo'),
        content: Form(
          key: formCargoKey,
          child: TextFormField(
            controller: nuevoCargoController,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Nombre del cargo',
              hintText: 'Ej: Instalador, Soldador, Jornal',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final nuevoCargo = value?.trim() ?? '';

              if (nuevoCargo.isEmpty) {
                return 'Ingrese el nombre del cargo';
              }

              if (RegExp(r'\d').hasMatch(nuevoCargo)) {
                return 'El cargo no puede contener números';
              }

              if (nuevoCargo.length < 3) {
                return 'El cargo debe tener mínimo 3 caracteres';
              }

              if (nuevoCargo.length > 100) {
                return 'El cargo debe tener máximo 100 caracteres';
              }

              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.verdeApp,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (!formCargoKey.currentState!.validate()) return;

              final nuevoCargo = nuevoCargoController.text.trim();

              setState(() {
                if (!cargosDisponibles.contains(nuevoCargo)) {
                  cargosDisponibles.add(nuevoCargo);
                }

                cargoSeleccionado = nuevoCargo;
              });

              Navigator.pop(context);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  String? _validarEnteroPositivo(String? value, String mensajeVacio) {
    if (value == null || value.trim().isEmpty) {
      return mensajeVacio;
    }

    final numero = ClpInputFormatter.toDouble(value);

    if (numero <= 0) {
      return 'Ingrese solo números enteros positivos';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.engineering, color: widget.verdeApp),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Agregar Mano de Obra',
              style: TextStyle(fontWeight: FontWeight.bold),
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
              DropdownButtonFormField<String>(
                initialValue: cargoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Cargo',
                  border: OutlineInputBorder(),
                ),
                items: cargosDisponibles.map((cargo) {
                  return DropdownMenuItem(value: cargo, child: Text(cargo));
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    cargoSeleccionado = value;
                  });
                },
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _mostrarDialogoCrearCargo,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear nuevo cargo'),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: valorJornadaController,
                keyboardType: TextInputType.number,
                inputFormatters: [ClpInputFormatter(maxDigits: 9)],
                onChanged: (_) => calcularSubtotal(),
                decoration: const InputDecoration(
                  labelText: 'Valor jornada (CLP)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  return _validarEnteroPositivo(value, 'Ingrese un valor');
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: diasController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(3),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (_) => calcularSubtotal(),
                decoration: const InputDecoration(
                  labelText: 'Cantidad de días',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  return _validarEnteroPositivo(
                    value,
                    'Ingrese cantidad de días',
                  );
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
                    const Text(
                      'Subtotal Mano de Obra',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${CurrencyFormatter.format(subtotal)} CLP',
                      style: TextStyle(
                        color: widget.verdeApp,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
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
            if (!_formKey.currentState!.validate()) {
              return;
            }

            final item = ManoDeObra(
              cargo: cargoSeleccionado,
              valorJornada: ClpInputFormatter.toDouble(
                valorJornadaController.text,
              ),
              dias: int.parse(diasController.text),
            );

            Navigator.pop(context, item);
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
