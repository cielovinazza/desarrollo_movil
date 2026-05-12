import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/repositories/cliente_repository_impl.dart';

import '../../domain/entities/cliente.dart';

import '../../domain/usecases/registrar_cliente.dart';

import '../widgets/cliente_text_field.dart';

class RegistroClientePage extends StatefulWidget {
  const RegistroClientePage({super.key});

  @override
  State<RegistroClientePage> createState() => _RegistroClientePageState();
}

class _RegistroClientePageState extends State<RegistroClientePage> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();

  final _rutController = TextEditingController();

  final _correoController = TextEditingController();

  final _telefonoController = TextEditingController();

  final _direccionController = TextEditingController();

  late final RegistrarCliente registrarClienteUseCase;

  @override
  void initState() {
    super.initState();

    registrarClienteUseCase = RegistrarCliente(ClienteRepositoryImpl());
  }

  @override
  void dispose() {
    _nombreController.dispose();

    _rutController.dispose();

    _correoController.dispose();

    _telefonoController.dispose();

    _direccionController.dispose();

    super.dispose();
  }

  bool validaRut(String rut) {
    rut = rut.replaceAll('.', '').replaceAll('-', '').toUpperCase();
    if (rut.length < 8) {
      return false;
    }

    String cuerpo = rut.substring(0, rut.length - 1);

    String dv = rut.substring(rut.length - 1);

    int suma = 0;
    int multiplo = 2;

    for (int i = cuerpo.length - 1; i >= 0; i--) {
      suma += int.parse(cuerpo[i]) * multiplo;

      multiplo++;

      if (multiplo > 7) {
        multiplo = 2;
      }
    }

    int resto = 11 - (suma % 11);

    String dvEsperado;

    if (resto == 11) {
      dvEsperado = '0';
    } else if (resto == 10) {
      dvEsperado = 'K';
    } else {
      dvEsperado = resto.toString();
    }

    return dv == dvEsperado;
  }

  void _submitForm() async {
    bool isValid = _formKey.currentState!.validate();

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hay errores en el formulario')),
      );

      return;
    }

    Cliente cliente = Cliente(
      nombre: _nombreController.text.trim(),

      rut: _rutController.text.trim(),

      correo: _correoController.text.trim(),

      telefono: _telefonoController.text.trim(),

      direccion: _direccionController.text.trim().isEmpty
          ? null
          : _direccionController.text.trim(),
    );

    await registrarClienteUseCase(cliente);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cliente registrado correctamente')),
    );
    Navigator.pop(context);
  }

  
  void _clearForm() {
    _formKey.currentState?.reset();

    _nombreController.clear();

    _rutController.clear();

    _correoController.clear();

    _telefonoController.clear();

    _direccionController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Formulario limpiado')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro Clientes')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              ClienteTextField(
                controller: _nombreController,

                label: 'Nombre',

                hint: 'Ingrese su nombre',

                icon: Icons.person,

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }

                  if (value.trim().length < 3) {
                    return 'Mínimo 3 caracteres';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              ClienteTextField(
                controller: 
                    _rutController, 
                label: 'Rut', 
              
                hint: 'Ingrese su rut con puntos y guión.', 
              
                icon: Icons.contact_page,
                
                keyboardType: TextInputType.text,
                
                textCapitalization:
                    TextCapitalization.characters,

                inputFormatters:[

                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9kK.-]'),
                  ),
                ],

                validator: (value){
                  if (value==null||value.trim().isEmpty){
                    return 'El rut es obligatorio';
                  }

                  if (!validaRut(value)){
                    return 'Rut invalido, intente nuevamente.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),


              ClienteTextField(
                controller: _correoController,

                label: 'Correo',

                hint: 'usuario@correo.com',

                icon: Icons.email,

                keyboardType: TextInputType.emailAddress,

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El correo es obligatorio';
                  }

                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Correo inválido';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              ClienteTextField(
                controller: _telefonoController,

                label: 'Teléfono',

                hint: 'ej: 912345678',

                icon: Icons.phone,

                keyboardType: TextInputType.number,

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El teléfono es obligatorio';
                  }

                  String numeros = value.replaceAll(RegExp(r'\D'), '');

                  if (numeros
                          .length <
                      9||numeros.length>9) {

                    return
                        'Número de teléfono invalido';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              ClienteTextField(
                controller: _direccionController,

                label: 'Dirección',

                hint: 'Opcional',

                icon: Icons.home,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,

                      icon: const Icon(Icons.send),

                      label: const Text('Enviar'),

                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clearForm,

                      icon: const Icon(Icons.clear),

                      label: const Text('Limpiar'),

                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
