import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/clientes_remote_datasource.dart';
import '../../data/repositories/cliente_repository_impl.dart';
import '../../domain/entities/cliente.dart';
import '../widgets/cliente_text_field.dart';
import '../formatters/mascara_rut_formatters.dart';
import '../../../../shared/widgets/strings_extensions.dart';

class EditarClientePage extends StatefulWidget {
  final Cliente cliente;

  const EditarClientePage({
    super.key,
    required this.cliente,
  });

  @override
  State<EditarClientePage> createState() =>
      _EditarClientePageState();
}

class _EditarClientePageState
    extends State<EditarClientePage> {
  final _formKey = GlobalKey<FormState>();
  bool _formValido = true;

  final repository= ClienteRepositoryImpl(ClientesRemoteDataSource(FirebaseFirestore.instance));

  late TextEditingController nombreController;
  late TextEditingController rutController;
  late TextEditingController correoController;
  late TextEditingController telefonoController;
  late TextEditingController direccionController;

  @override
  void initState() {
    super.initState();

    nombreController =
        TextEditingController(text: widget.cliente.nombre);

    rutController =
        TextEditingController(text: widget.cliente.rut);

    correoController =
        TextEditingController(text: widget.cliente.correo);

    telefonoController =
        TextEditingController(text: widget.cliente.telefono);

    direccionController =
        TextEditingController(
          text: widget.cliente.direccion ?? '',
        );
  }

  void _validarFormulario() {
    final valido = _formKey.currentState?.validate() ?? false;

    setState(() {
      _formValido = valido;
    });
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

  Future<void> guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final clienteActualizado = Cliente(
      id: widget.cliente.id,
      nombre: nombreController.text.toTitleCase(),
      rut: rutController.text,
      correo: correoController.text,
      telefono: telefonoController.text,
      direccion: direccionController.text.trim().isEmpty
       ? null : direccionController.text.trim(),
    );

    try{
      await repository.editarCliente(
        clienteActualizado,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cliente actualizado correctamente',
          ),
        ),
      );

      Navigator.pop(context);
    }catch(e){

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', '',),
          ),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar cliente'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _validarFormulario,

          child: Column(
            children: [
              ClienteTextField(
                controller: nombreController,

                label: 'Nombre',
                hint: 'Ingrese nombre del cliente',
                icon: Icons.person,
                textCapitalization: TextCapitalization.words,
                inputFormatters:[

                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZñÑáéíóúÉÁÍÚÓ ]'),
                  ),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es obligatorio';
                  }

                  if (value.trim().length<3){
                    return 'El nombre debe contener mínimo 3 caracteres';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              ClienteTextField(
                controller: rutController,
                label: 'Rut',
                hint: 'Ingrese rut del cliente',
                icon: Icons.contact_page,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9kK]'),
                  ),

                  RutInputFormatter(),

                ],
                validator: (value){
                  if (value==null||value.trim().isEmpty){
                    return 'El rut es obligatorio';
                  }
                  if (!validaRut(value)){
                    return 'Rut invalido, intente nuevamente';
                  }
                  return null;

                } ,
                
              ),

              const SizedBox(height: 16),

              ClienteTextField(
                controller: correoController,
                label: 'Correo',
                hint: 'usuario@correo.com',
                icon: Icons.email,

                keyboardType: TextInputType.emailAddress,
                validator: (value){
                  if (value==null||value.trim().isEmpty){
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
                controller: telefonoController,
                label: 'Teléfono',
                hint: 'ej: 912345678',
                icon: Icons.phone,
                keyboardType: TextInputType.number,
                prefixText: '+56',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],

                validator: (value){
                  if (value==null||value.trim().isEmpty){
                    return 'El teléfono es obligatorio';
                  }
                  String numeros = value.replaceAll(RegExp(r'\D'), '');

                  if (numeros.length <9||numeros.length>9) {
                    return'Número de teléfono invalido';
                  }

                  return null;

                },

              ),

              const SizedBox(height: 16),

              ClienteTextField(
                controller: direccionController,
                label: 'Dirección',
                textCapitalization: TextCapitalization.words,
                hint: 'Ingrese la nueva dirección del cliente',
                icon: Icons.home,
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _formValido ? guardarCambios : null,

                child: const Text(
                  'Guardar cambios',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}