import 'package:flutter/material.dart';
import '../../domain/entities/mano_de_obra.dart';

class ManoObraDialog extends StatefulWidget {

  final Color verdeApp;

  const ManoObraDialog({
    super.key,
    required this.verdeApp,
  });

  @override
  State<ManoObraDialog> createState() =>
      _ManoObraDialogState();

}

class _ManoObraDialogState
    extends State<ManoObraDialog> {

  final List<String> cargosDisponibles=[
    'Pintor',
    'Yesero',
    'Supervisor',
  ];

  late String cargoSeleccionado;

  final _formKey =
      GlobalKey<FormState>();

  final valorJornadaController =
      TextEditingController();

  final diasController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    cargoSeleccionado = cargosDisponibles.first;
}

  double subtotal = 0;

  @override
  void dispose() {

    valorJornadaController.dispose();

    diasController.dispose();

    super.dispose();
  }

  void calcularSubtotal() {

    final valor =
        double.tryParse(
              valorJornadaController.text,
            ) ??
            0;

    final dias =
        double.tryParse(
              diasController.text,
            ) ??
            0;

    setState(() {
      subtotal = valor * dias;
    });
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),

      title: Row(
        children: [

          Icon(
            Icons.engineering,
            color: widget.verdeApp,
          ),

          const SizedBox(width: 10),

          const Text(
            'Agregar Mano de Obra',
          ),
        ],
      ),

      content: Form(

        key: _formKey,

        child: SingleChildScrollView(

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [

              DropdownButtonFormField<String>(

                initialValue: cargoSeleccionado,

                decoration: const InputDecoration(
                  labelText: 'Cargo',
                  border: OutlineInputBorder(),
                ),

                items: cargosDisponibles.map(
                  (cargo) {

                  return DropdownMenuItem(
                    value: cargo,
                    child: Text(cargo),
                  );
                },
              ).toList(),

              onChanged: (value) {
                setState(() {
                  cargoSeleccionado = value!;
                });
              },
            ),
              const SizedBox(height: 16),

              TextFormField(

                controller:
                    valorJornadaController,

                keyboardType:
                    TextInputType.number,

                onChanged: (_) =>
                    calcularSubtotal(),

                decoration:
                    const InputDecoration(
                  labelText:
                      'Valor jornada (CLP)',

                  border:
                      OutlineInputBorder(),
                ),

                validator: (value) {

                  if (value == null ||
                      value.isEmpty) {

                    return 'Ingrese un valor';
                  }

                  final numero =
                      double.tryParse(value);

                  if (numero == null ||
                      numero <= 0) {

                    return 'Ingrese un número válido';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(

                controller:
                    diasController,

                keyboardType:
                    TextInputType.number,

                onChanged: (_) =>
                    calcularSubtotal(),

                decoration:
                    const InputDecoration(
                  labelText:
                      'Cantidad de días',

                  border:
                      OutlineInputBorder(),
                ),

                validator: (value) {

                  if (value == null ||
                      value.isEmpty) {

                    return 'Ingrese cantidad de días';
                  }

                  final numero =
                      double.tryParse(value);

                  if (numero == null ||
                      numero <= 0) {

                    return 'Ingrese un número válido';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              Container(

                width: double.infinity,

                padding:
                    const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: widget.verdeApp
                      .withValues(alpha: 0.08),

                  borderRadius:
                      BorderRadius.circular(10),
                ),

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'Subtotal Mano de Obra',

                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '\$${subtotal.toStringAsFixed(0)} CLP',

                      style: TextStyle(
                        color:
                            widget.verdeApp,

                        fontWeight:
                            FontWeight.bold,

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
          onPressed: () =>
              Navigator.pop(context),

          child:
              const Text('Cancelar'),
        ),

        ElevatedButton(

          onPressed: () {

            if (!_formKey.currentState!
                .validate()) {

              return;
            }

            final item =
                ManoDeObra(
              cargo: cargoSeleccionado,

              valorJornada:
                  double.parse(
                valorJornadaController
                    .text,
              ),

              dias:
                  double.parse(
                diasController.text,
              ),
            );

            Navigator.pop(
              context,
              item,
            );
          },

          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                widget.verdeApp,

            foregroundColor:
                Colors.white,
          ),

          child:
              const Text('Guardar'),
        ),
      ],
    );
  }
}