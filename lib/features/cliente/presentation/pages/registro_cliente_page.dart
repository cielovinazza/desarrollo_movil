import 'package:flutter/material.dart';
import '../../domain/entities/cliente.dart';
import '../../data/datasources/clientes_local_datasource.dart';
import '../../data/repositories/cliente_repository_impl.dart';
import '../../domain/usecases/registrar_cliente.dart';

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
    registrarClienteUseCase = RegistrarCliente(
    ClienteRepositoryImpl(ClientesLocalDataSource()),
    );
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

  bool validarFormatoRut(String rut) {
    final regex = RegExp(r'^\d{1,2}\.\d{3}\.\d{3}-[0-9kK]$');
    return regex.hasMatch(rut);
  }

  bool validarRut(String rut) {
    if (!validarFormatoRut(rut)) return false;

    rut = rut.replaceAll('.', '').replaceAll('-', '').toUpperCase();

    String cuerpo = rut.substring(0, rut.length - 1);
    String dv = rut.substring(rut.length - 1);

    int suma = 0;
    int multiplo = 2;

    for (int i = cuerpo.length - 1; i >= 0; i--) {
      suma += int.parse(cuerpo[i]) * multiplo;
      multiplo = multiplo < 7 ? multiplo + 1 : 2;
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
    if (!_formKey.currentState!.validate()) return;

    final cliente = Cliente(
      nombre: _nombreController.text.trim(),
      rut: _rutController.text.trim(),
      correo: _correoController.text.trim(),
      telefono: _telefonoController.text.trim(),
      direccion: _direccionController.text.trim().isEmpty
          ? null
          : _direccionController.text.trim(),
    );

    await registrarClienteUseCase(cliente);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Cliente")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person),
                ),
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
              TextFormField(
                controller: _rutController,
                decoration: const InputDecoration(
                  labelText: 'RUT',
                  hintText: '12.345.678-9',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El RUT es obligatorio';
                  }
                  if (!validarFormatoRut(value)) {
                    return 'Formato: 12.345.678-9';
                  }
                  if (!validarRut(value)) {
                    return 'RUT inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.email),
                ),
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
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El teléfono es obligatorio';
                  }
                  String numeros = value.replaceAll(RegExp(r'\D'), '');
                  if (numeros.length != 9) {
                    return 'Debe tener 9 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección (opcional)',
                  prefixIcon: Icon(Icons.home),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.save),
                label: const Text("Guardar Cliente"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}