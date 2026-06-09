import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/clientes_remote_datasource.dart';
import '../../data/repositories/cliente_repository_impl.dart';
import '../../domain/entities/cliente.dart';
import '../widgets/cliente_text_field.dart';
import '../formatters/mascara_rut_formatters.dart';
import '../../../../core/utils/strings_extensions.dart';
import '../../../../shared/widgets/boton_bloqueo_visual.dart';

class EditarClientePage extends StatefulWidget {
  final Cliente cliente;

  const EditarClientePage({super.key, required this.cliente});

  @override
  State<EditarClientePage> createState() => _EditarClientePageState();
}

class _EditarClientePageState extends State<EditarClientePage> {
  final _formKey = GlobalKey<FormState>();
  bool _formValido = true;

  final repository = ClienteRepositoryImpl(
    ClientesRemoteDataSource(FirebaseFirestore.instance),
  );

  late TextEditingController nombreController;
  late TextEditingController rutController;
  late TextEditingController correoController;
  late TextEditingController telefonoController;
  late TextEditingController direccionController;

  final Color greenPrimary = const Color(0xFF0F5A3C);

  @override
  void initState() {
    super.initState();

    nombreController = TextEditingController(text: widget.cliente.nombre);
    rutController = TextEditingController(text: widget.cliente.rut);
    correoController = TextEditingController(text: widget.cliente.correo);
    telefonoController = TextEditingController(text: widget.cliente.telefono);
    direccionController = TextEditingController(
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
    if (rut.length < 8) return false;

    String cuerpo = rut.substring(0, rut.length - 1);
    String dv = rut.substring(rut.length - 1);

    int suma = 0;
    int multiplo = 2;

    for (int i = cuerpo.length - 1; i >= 0; i--) {
      suma += int.parse(cuerpo[i]) * multiplo;
      multiplo++;
      if (multiplo > 7) multiplo = 2;
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
    if (!_formKey.currentState!.validate()) return;

    final clienteActualizado = Cliente(
      id: widget.cliente.id,
      nombre: nombreController.text.toTitleCase(),
      rut: rutController.text,
      correo: correoController.text,
      telefono: telefonoController.text,
      direccion: direccionController.text.trim().isEmpty
          ? null
          : direccionController.text.trim(),
    );

    try {
      await repository.editarCliente(clienteActualizado);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente actualizado correctamente'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: greenPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Editar cliente',
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _validarFormulario,
          child: Column(
            children: [
           
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.mode_edit_outline_outlined,
                            color: theme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Modificar Información',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Actualice los campos que correspondan',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(height: 1, thickness: 0.5),
                    ),

                    ClienteTextField(
                      controller: nombreController,
                      label: 'Nombre',
                      hint: 'Ingrese nombre del cliente',
                      icon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-ZñÑáéíóúÉÁÍÚÓ ]'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'El nombre es obligatorio';
                        if (value.trim().length < 3) return 'El nombre debe contener mínimo 3 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    ClienteTextField(
                      controller: rutController,
                      enabled: false,
                      label: 'RUT',
                      hint: 'Ingrese RUT del cliente',
                      icon: Icons.contact_page_outlined,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9kK]')),
                        RutInputFormatter(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ClienteTextField(
                      controller: correoController,
                      label: 'Correo',
                      hint: 'usuario@correo.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'El correo es obligatorio';
                        final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        );
                        if (!emailRegex.hasMatch(value.trim())) return 'Correo inválido (usuario@correo.com)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    ClienteTextField(
                      controller: telefonoController,
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
                        if (value == null || value.trim().isEmpty)return 'El teléfono es obligatorio';
                        String numeros = value.replaceAll(RegExp(r'\D'), '');
                        if (numeros.length != 9)return 'Debe tener exactamente 9 dígitos';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    ClienteTextField(
                      controller: direccionController,
                      label: 'Dirección',
                      textCapitalization: TextCapitalization.words,
                      hint: 'Ingrese la dirección del cliente',
                      icon: Icons.location_on_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: BotonBloqueoVisual(
                      habilitado: _formValido,
                      onPressed: guardarCambios,
                      texto: 'Guardar',
                      icon: Icons.save_as_outlined,
                      colorActivo: theme.primaryColor,
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
