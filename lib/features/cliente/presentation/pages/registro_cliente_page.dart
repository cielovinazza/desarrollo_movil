import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/datasources/clientes_remote_datasource.dart';
import '../../data/repositories/cliente_repository_impl.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/usecases/registrar_cliente.dart';
import '../widgets/cliente_text_field.dart';
import '../formatters/mascara_rut_formatters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/widgets/strings_extensions.dart';

class RegistroClientePage extends StatefulWidget {
  final String? rutInicial;

  const RegistroClientePage({super.key, this.rutInicial});

  @override
  State<RegistroClientePage> createState() => _RegistroClientePageState();
}

class _RegistroClientePageState extends State<RegistroClientePage> {
  final repository = ClienteRepositoryImpl(
    ClientesRemoteDataSource(FirebaseFirestore.instance),
  );

  final _formKey = GlobalKey<FormState>();
  bool _formValido = false;

  final _nombreController = TextEditingController();
  final _rutController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();

  late final RegistrarCliente registrarClienteUseCase;

  @override
  void initState() {
    super.initState();
    registrarClienteUseCase = RegistrarCliente(repository);
    
    if (widget.rutInicial != null) {
      _rutController.text = widget.rutInicial!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _validarFormulario());
    }
  }

  void _validarFormulario() {
    final valido = _formKey.currentState?.validate() ?? false;
    setState(() {
      _formValido = valido;
    });
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
      final char = cuerpo[i];
      if (!RegExp(r'\d').hasMatch(char)) return false;
      suma += int.parse(char) * multiplo;
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
      nombre: _nombreController.text.toTitleCase(),
      rut: _rutController.text.trim(),
      correo: _correoController.text.trim(),
      telefono: _telefonoController.text.trim(),
      direccion: _direccionController.text.trim().isEmpty
          ? null
          : _direccionController.text.trim(),
    );

    try {
      await registrarClienteUseCase(cliente);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente registrado correctamente'),
        ),
      );
      Navigator.pop(context);
    } catch (e, stack) {
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nombreController.clear();
    _rutController.clear();
    _correoController.clear();
    _telefonoController.clear();
    _direccionController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulario limpiado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro Clientes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _validarFormulario,
          child: Column(
            children: [
              ClienteTextField(
                controller: _nombreController,
                label: 'Nombre',
                hint: 'Ingrese su nombre',

                icon: Icons.person_outline,

                inputFormatters:[

                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZñÑÁÉÍÓÚáéíóú ]'),
                  ),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  if (value.trim().length < 3) {
                    return 'El nombre debe contener mínimo 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ClienteTextField(
                controller: 
                    _rutController, 
                label: 'Rut', 
              
                hint: 'Ingrese su rut.', 
              
                icon: Icons.contact_page_outlined,
                
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9kK]'),
                  ),
                  RutInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El rut es obligatorio';
                  }
                  if (!validaRut(value)) {
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

                icon: Icons.email_outlined,

                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El correo es obligatorio';
                  }
                  final emailRegex = RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                  );
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Correo inválido, debe ser de la forma usuario@correo.com';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ClienteTextField(
                controller: _telefonoController,
                label: 'Teléfono',
                hint: 'ej: 912345678',

                icon: Icons.phone_outlined,

                keyboardType: TextInputType.number,
                prefixText: '+56 ',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El teléfono es obligatorio';
                  }
                  String numeros = value.replaceAll(RegExp(r'\D'), '');
                  if (numeros.length < 9 || numeros.length > 9) {
                    return 'Número de teléfono invalido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ClienteTextField(
                controller: _direccionController,
                label: 'Dirección',
                hint: 'Opcional',

                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _formValido ? _submitForm : null,
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