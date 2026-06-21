import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/datasources/clientes_remote_datasource.dart';
import '../../data/repositories/cliente_repository_impl.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/usecases/registrar_cliente.dart';
import '../widgets/cliente_text_field.dart';
import '../formatters/mascara_rut_formatters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/strings_extensions.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../shared/widgets/boton_bloqueo_visual.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class RegistroClientePage extends StatefulWidget {
  final String? rutInicial;
  final String? nombreInicial;

  const RegistroClientePage({super.key, this.rutInicial, this.nombreInicial});

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
  final _localStorage = LocalStorage();

  late final RegistrarCliente registrarClienteUseCase;

  
  final Color greenPrimary = const Color(0xFF0F5A3C);

  @override
  void initState() {
    super.initState();
    registrarClienteUseCase = RegistrarCliente(repository);
    _recuperarBorradorCliente();
    _nombreController.addListener(_autoguardarCliente);
    _rutController.addListener(_autoguardarCliente);
    _correoController.addListener(_autoguardarCliente);
    _telefonoController.addListener(_autoguardarCliente);
    _direccionController.addListener(_autoguardarCliente);
    
    if (widget.rutInicial != null || widget.nombreInicial != null) {
    // Si viene dato inyectado, ignorar borrador
      if (widget.rutInicial != null) {
        _rutController.text = RutInputFormatter.formatear(widget.rutInicial!);
      }
      if (widget.nombreInicial != null) {
        _nombreController.text = widget.nombreInicial!;
      }
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
    _nombreController.removeListener(_autoguardarCliente);
    _rutController.removeListener(_autoguardarCliente);
    _correoController.removeListener(_autoguardarCliente);
    _telefonoController.removeListener(_autoguardarCliente);
    _direccionController.removeListener(_autoguardarCliente);
    super.dispose();
  }

  bool validaRut(String rut) {
    rut = rut.replaceAll('.', '').replaceAll('-', '').toUpperCase();
    if (rut.length < 8) return false;

    String cuerpo = rut.substring(0, rut.length - 1);
    String dv = rut.substring(rut.length - 1);

    int suma = 0;
    int multiplo = 2;

    for (int i = cuerpo.length - 1; i >= 0; i--) {
      final char = cuerpo[i];
      if (!RegExp(r'\d').hasMatch(char)) return false;
      suma += int.parse(char) * multiplo;
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

 void _submitForm() async {
  bool isValid = _formKey.currentState!.validate();

  if (!isValid) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hay errores en el formulario')),
    );
    return;
  }

  final String rutLimpio = _rutController.text.trim();
  final String nombreFormateado = _nombreController.text.toTitleCase();
  final String correoLimpio = _correoController.text.trim();
  final String telefonoLimpio = _telefonoController.text.trim();
  final String? direccionLimpia = _direccionController.text.trim().isEmpty
      ? null
      : _direccionController.text.trim();
  final connectivityResult = await Connectivity().checkConnectivity();
  final bool hayInternet = connectivityResult.any((r) => r != ConnectivityResult.none);

  if (!hayInternet) {
    final clienteMap = {
      'id': rutLimpio, 
      'nombre': nombreFormateado,
      'rut': rutLimpio,
      'correo': correoLimpio,
      'telefono': telefonoLimpio,
      'direccion': direccionLimpia ?? '',
    };

    await _localStorage.guardarClientePendiente(clienteMap);
    await _localStorage.limpiarBorradorCliente();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sin conexión. Cliente guardado localmente.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
      ),
    );
    final clienteTemporal = Cliente(
      id: rutLimpio,
      nombre: nombreFormateado,
      rut: rutLimpio,
      correo: correoLimpio,
      telefono: telefonoLimpio,
      direccion: direccionLimpia,
    );

    Navigator.pop(context, clienteTemporal);
    return;
  }
  Cliente cliente = Cliente(
    id: rutLimpio,
    nombre: nombreFormateado,
    rut: rutLimpio,
    correo: correoLimpio,
    telefono: telefonoLimpio,
    direccion: direccionLimpia,
  );

  try {
    await registrarClienteUseCase(cliente);
    await _localStorage.limpiarBorradorCliente();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cliente registrado correctamente'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, cliente);

  } catch (e, stack) {
    debugPrint('ERROR: $e');
    if (!mounted) return;

    final errorStr = e.toString();
    if (errorStr.contains('ya se encuentra registrado') || 
        (e is FirebaseException && e.code == 'permission-denied')) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Ya existe un cliente registrado con el RUT $rutLimpio.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return; 
    }
    await _localStorage.guardarClientePendiente({
      'id': rutLimpio,
      'nombre': nombreFormateado,
      'rut': rutLimpio,
      'correo': correoLimpio,
      'telefono': telefonoLimpio,
      'direccion': direccionLimpia ?? '',
    });
    await _localStorage.limpiarBorradorCliente();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error de comunicación. Guardado en pendientes locales.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context, cliente);
  }
}

   Future<void> _clearForm() async {
    _formKey.currentState?.reset();
    _nombreController.clear();
    _rutController.clear();
    _correoController.clear();
    _telefonoController.clear();
    _direccionController.clear();
    await _localStorage.limpiarBorradorCliente();
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formulario limpiado'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  Future<void> _autoguardarCliente() async {
    await _localStorage.guardarBorradorCliente({
      'nombre': _nombreController.text,
      'rut': _rutController.text,
      'correo': _correoController.text,
      'telefono': _telefonoController.text,
      'direccion': _direccionController.text,
    });
  }

  Future<void> _recuperarBorradorCliente() async {
    if (widget.rutInicial!= null || widget.nombreInicial!= null) return;
    final borrador = await _localStorage.obtenerBorradorCliente();
    if (borrador == null) return;

    setState(() {
      _nombreController.text = borrador['nombre'] ?? '';
      _rutController.text = borrador['rut'] ?? '';
      _correoController.text = borrador['correo'] ?? '';
      _telefonoController.text = borrador['telefono'] ?? '';
      _direccionController.text = borrador['direccion'] ?? '';
    });

    _validarFormulario();
  }
  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esOscuro = theme.brightness == Brightness.dark;
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Nuevo Cliente',
          style: TextStyle(
            
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
                  color: theme.cardColor,
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
                            color:  esOscuro ? const Color.fromARGB(255, 40, 43, 40): const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.person_add_alt_1_outlined,
                            color: theme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Datos de Registro',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: esOscuro ? Colors.white : Colors.black87 ,
                              ),
                            ),
                            Text(
                              'Complete los campos requeridos',
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
                      controller: _nombreController,
                      label: 'Nombre',
                      hint: 'Ingrese nombre completo',
                      icon: Icons.person_outline,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-ZñÑÁÉÍÓÚáéíóú ]'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'El nombre es obligatorio';
                        if (value.trim().length < 3) return 'Mínimo 3 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    ClienteTextField(
                      controller: _rutController,
                      label: 'RUT',
                      hint: 'Ingrese RUT del cliente',
                      icon: Icons.contact_page_outlined,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9kK]')),
                        RutInputFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'El RUT es obligatorio';
                        if (!validaRut(value)) return 'RUT inválido, intente nuevamente.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    ClienteTextField(
                      controller: _correoController,
                      label: 'Correo electrónico',
                      hint: 'usuario@correo.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'El correo es obligatorio';
                        final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        );
                        if (!emailRegex.hasMatch(value.trim()))return 'Formato inválido (usuario@correo.com)';
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
                        if (value == null || value.trim().isEmpty) return 'El teléfono es obligatorio';
                        
                        if (value.replaceAll(RegExp(r'\D'), '').length != 9)return 'Debe tener exactamente 9 dígitos';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    ClienteTextField(
                      controller: _direccionController,
                      label: 'Dirección particular',
                      hint: 'Opcional (Ej: Av. Las Condes 1230)',
                      icon: Icons.location_on_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _clearForm,
                      icon: Icon(
                        Icons.clear_rounded,
                        size: 18,
                        color: esOscuro ? Colors.white : Colors.black87,
                      ),
                      label: Text(
                        'Limpiar',
                        style: TextStyle(
                          color: esOscuro ? Colors.white: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BotonBloqueoVisual(
                      habilitado: _formValido,
                      onPressed: _submitForm,
                      texto: 'Guardar',
                      icon: Icons.send_rounded,
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
