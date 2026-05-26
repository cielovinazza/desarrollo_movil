import 'package:flutter/material.dart';
import 'package:project/features/cliente/domain/entities/cliente.dart';
import '../../domain/entities/cotizacion_model.dart';
import '../widgets/manodeobra.dart';
import '../widgets/materiales.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/cotizacion_firebase_datasource.dart';
import '../../data/mappers/cotizacion_mapper.dart';
import '../../data/repositories/cotizacion_repository_impl.dart';
import '../../domain/usecases/guardar_cotizacion.dart';
import '../widgets/previsualizacion_pdf.dart';
import '../../data/dtos/cotizacion_dtos.dart';
import 'package:flutter/services.dart';

class CrearCotizacionPage extends StatefulWidget {
  const CrearCotizacionPage({super.key});

  @override
  State<CrearCotizacionPage> createState() => _CrearCotizacionPageState();
}

class _CrearCotizacionPageState extends State<CrearCotizacionPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  Cliente? _clienteSeleccionado;
  late final GuardarCotizacion guardarCotizacionUseCase;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _vistaPreviaCargada = false;
  bool _guardandoEnFirestore = false;
  String? _idCotizacionCreada;

  final List<ManoDeObra> _manoObraAgregada = [];
  final List<ItemTrabajo> _trabajosAgregados = [];
  final List<MaterialEntity> _materialesAgregados = [];
  final Color _verdeApp = const Color(0xFF2E7D32);
  final _clienteController = TextEditingController();
  final _direccionController = TextEditingController();
  final _viaticoController = TextEditingController();
  final _utilidadController = TextEditingController(text: '0');
  final _ivaController = TextEditingController(text: '19');
  
  final List<String> _tiposDisponibles = [
    'Pintura',
    'Yeso',
    'Estuco',
    'Pasta Muro',
    'Cerámica',
    'Electricidad',
    'Gasfitería',
    'Carpintería',
    'Albañilería',
    'Instalación de piso',
  ];

  late final CotizacionFirestoreDataSource datasource;

  @override
  void initState() {
    super.initState();

    datasource = CotizacionFirestoreDataSource(
      FirebaseFirestore.instance,
    );


    final repository = CotizacionRepositoryImpl(datasource);

    guardarCotizacionUseCase = GuardarCotizacion(repository);

          
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _direccionController.dispose();
    _viaticoController.dispose();
    _utilidadController.dispose();
    _ivaController.dispose();
    super.dispose();
  }

  CotizacionModel _obtenerEstadoActual() {
    final viaticoTexto = _viaticoController.text.trim();
    final double? viaticoValor = viaticoTexto.isEmpty
        ? null
        : double.tryParse(viaticoTexto); //esta linea de codigo es para que cliente no entre como null, acepten el cambio entrante
    final clienteSeguro = _clienteSeleccionado ?? Cliente(
    id: '',
    nombre: '',
    correo: '',
    rut: '',
    telefono: '',
    direccion: '',
  );

    return CotizacionModel(
      cliente: clienteSeguro,
      direccionObra: _direccionController.text.trim(),
      listaTrabajos: _trabajosAgregados,
      listaManoObra: _manoObraAgregada,
      viatico: viaticoValor,
      porcentajeUtilidad: double.tryParse(_utilidadController.text) ?? 0.0,
      porcentajeIva: double.tryParse(_ivaController.text) ?? 19.0,
      materiales: _materialesAgregados,
    );
  }

  Future<String> _guardarCotizacion() async {
    final cotizacion = _obtenerEstadoActual();
    final docRef = FirebaseFirestore.instance.collection('cotizaciones').doc();
    final String idReal = docRef.id;


    final dto = CotizacionMapper.toDto(
      cotizacion: cotizacion,
      materiales: _materialesAgregados,
      usuarioId: _auth.currentUser?.uid ?? '',
      estado: 'En Proceso',
    );

    
    final dtoConId = CotizacionDto(
      id: idReal,
      clienteId: dto.clienteId,
      clienteNombre: dto.clienteNombre,
      clienteEmail: dto.clienteEmail,
      clienteRut: dto.clienteRut,
      clienteTelefono: dto.clienteTelefono,
      clienteDireccion: dto.clienteDireccion,
      codigo: dto.codigo,
      direccion: dto.direccion,
      trabajos: dto.trabajos,
      manoObra: dto.manoObra,
      materiales: dto.materiales,
      subtotalObra: dto.subtotalObra,
      subtotalMateriales: dto.subtotalMateriales,
      subtotalManoObra: dto.subtotalManoObra,
      viatico: dto.viatico,
      porcentajeUtilidad: dto.porcentajeUtilidad,
      porcentajeIva: dto.porcentajeIva,
      totalFinal: dto.totalFinal,
      estado: 'En Proceso', 
      usuarioId: dto.usuarioId,
      fechaCreacion: dto.fechaCreacion,
      version: dto.version,
    );

    await guardarCotizacionUseCase(dtoConId);
    return idReal;
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _agregarMaterial() async {
    final resultado = await showDialog<MaterialEntity>(
      context: context,
      builder: (_) => MaterialDialog(verdeApp: _verdeApp),
    );
    if (resultado != null) setState(() => _materialesAgregados.add(resultado));
  }

  Future<void> _editarMaterial(int index) async {
    final resultado = await showDialog<MaterialEntity>(
      context: context,
      builder: (_) => MaterialDialog(
        verdeApp: _verdeApp,
        materialEditando: _materialesAgregados[index],
      ),
    );
    if (resultado != null) {
      setState(() => _materialesAgregados[index] = resultado);
    }
  }

  void _mostrarDialogoCrearTipoTrabajo(
    void Function(void Function()) setModalState,
    void Function(String) onTipoCreado,
  ) {
    final nuevoTipoController = TextEditingController();
    final _formkey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo tipo de trabajo'),
        content: Form(
          key: _formkey,
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
              nuevoTipoController.dispose(); 
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _verdeApp,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (_formkey.currentState!.validate()) {
                final nuevoTipo = nuevoTipoController.text.trim();
                Navigator.pop(context);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_tiposDisponibles.contains(nuevoTipo)) {
                    setState(() {
                      _tiposDisponibles.add(nuevoTipo);
                    });
                  }
                  onTipoCreado(nuevoTipo);
                  nuevoTipoController.dispose();
                });
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoAgregarTrabajo() {
    String tipoSeleccionado = _tiposDisponibles.first;
    final m2ItemController = TextEditingController();
    final precioItemController = TextEditingController();
    String? errorM2;
    String? errorPrecio;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.add_task, color: _verdeApp),
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
                  initialValue: tipoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Rubro',
                    border: OutlineInputBorder(),
                  ),
                  items: _tiposDisponibles
                      .map(
                        (tipo) =>
                            DropdownMenuItem(value: tipo, child: Text(tipo)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => tipoSeleccionado = value);
                  },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      _mostrarDialogoCrearTipoTrabajo(setModalState, (
                        nuevoTipo,
                      ) {
                        setModalState(() => tipoSeleccionado = nuevoTipo);
                      });
                    },
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
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
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
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Precio por m² (CLP)',
                    prefixIcon: const Icon(Icons.sell_outlined),
                    border: const OutlineInputBorder(),
                    errorText: errorPrecio,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final m2Texto = m2ItemController.text.trim();
                final precioTexto = precioItemController.text.trim();

                final m2 = double.tryParse(m2Texto);
                final precio = double.tryParse(precioTexto);

                setModalState(() {
                  errorM2 = null;
                  errorPrecio = null;

                  if (m2Texto.isEmpty) {
                    errorM2 = 'Debe ingresar la cantidad de metros cuadrados';
                  } else if (m2 == null || m2 <= 0) {
                    errorM2 = 'Ingrese un número positivo válido';
                  }

                  if (precioTexto.isEmpty) {
                    errorPrecio = 'Debe ingresar el precio por m²';
                  } else if (precio == null || precio <= 0) {
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

                setState(() {
                  _trabajosAgregados.add(
                    ItemTrabajo(
                      tipo: tipoSeleccionado,
                      metrosCuadrados: m2!,
                      precioPorMetro: precio!,
                    ),
                  );
                });

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _verdeApp,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar Ítem'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _agregarManoObra() async {
    final resultado = await showDialog<ManoDeObra>(
      context: context,
      builder: (_) => ManoObraDialog(verdeApp: _verdeApp),
    );
    if (resultado != null) setState(() => _manoObraAgregada.add(resultado));
  }

  String? _validarCampoNumerico(String? value, String nombreCampo) {
    if (value == null || value.trim().isEmpty) {
      if (nombreCampo == 'Viático') return null; 
      return 'El campo $nombreCampo es obligatorio';
    }
    
    final numero = double.tryParse(value.trim());
    if (numero == null) {
      return 'Ingrese solo caracteres numéricos válidos';
    }
    
    if (numero < 0) {
      return 'No se permiten importes o tasas negativas';
    }
    
    return null;
  }

  Future<bool> _mostrarAlertaRentabilidadBaja() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 10),
                Text('Alerta de Rentabilidad', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              '¡Atención contratista! El margen de utilidad ingresado es inferior al 10% mínimo recomendado. '
              '¿Está seguro de que desea continuar con esta tasa de ganancia para el proyecto?',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Modificar Margen', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sí, continuar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final datosEnVivo = _obtenerEstadoActual();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nueva Cotización',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _verdeApp,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: () => setState(() {}),
        child: Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: _verdeApp)),
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            controlsBuilder: (context, details) => Row(
              children: [
                if (!_guardandoEnFirestore)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _verdeApp,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_currentStep == 4 ? 'Guardar y Previsualizar' : 'Continuar'),
                  ),
                const SizedBox(width: 12),
                if (!_guardandoEnFirestore)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(_currentStep == 0 ? 'Salir' : 'Atrás'),
                  ),
                if (_guardandoEnFirestore)
                  const CircularProgressIndicator(),
              ],
            ),
            onStepContinue: () async {
              if (_currentStep == 0) {
                if (_clienteController.text.trim().isEmpty) {
                  _mostrarMensaje('Debes ingresar o seleccionar un cliente');
                  return;
                }
              }

              if (_currentStep == 1) {
                if (_direccionController.text.trim().isEmpty) {
                  _mostrarMensaje('Debes ingresar la dirección de la obra');
                  return;
                }
                if (_trabajosAgregados.isEmpty) {
                  _mostrarMensaje('Debes agregar al menos un trabajo de obra');
                  return;
                }
              }

              if (_currentStep < 4) {
                setState(() {
                  if (_currentStep == 3) {
                    _vistaPreviaCargada = false;
                  }
                  _currentStep += 1;
                });
              } else {
                if (!_formKey.currentState!.validate()) {
                  _mostrarMensaje('Formulario inválido. Corrija los campos en rojo antes de guardar.');
                  return;
                }

                final margenUtilidad = double.tryParse(_utilidadController.text) ?? 0.0;
                if (margenUtilidad < 10.0) {
                  final deseaContinuar = await _mostrarAlertaRentabilidadBaja();
                  if (!deseaContinuar) return; 
                }

                if (_guardandoEnFirestore) return;

                setState(() => _guardandoEnFirestore = true);

                try {
                  final realId = await _guardarCotizacion();
                  setState(() {
                    _idCotizacionCreada = realId;
                    _vistaPreviaCargada = true;
                  });
                  _mostrarMensaje('Cotización creada con exito.');
                } catch (e) {
                  setState(() => _guardandoEnFirestore = false);
                  _mostrarMensaje('Error de persistencia: $e');
                }
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              } else {
                Navigator.pop(context);
              }
            },
            steps: [
              Step(
                title: const Text(
                  'Identificación del Cliente',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                isActive: _currentStep >= 0,
                content: SelectorCliente(
                  controller: _clienteController,
                  onClienteSeleccionado: (Cliente cliente) {
                    setState(() => _clienteSeleccionado = cliente);
                  },
                ),
              ),
              Step(
                title: const Text(
                  'Detalle de Trabajos de la Obra',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                isActive: _currentStep >= 1,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección general del proyecto',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ítems de Construcción',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _mostrarDialogoAgregarTrabajo,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Añadir Ítem'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _verdeApp,
                            side: BorderSide(color: _verdeApp),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (_trabajosAgregados.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No has añadido ningún trabajo todavía.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ..._trabajosAgregados.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.build_circle_outlined,
                            color: _verdeApp,
                          ),
                          title: Text(item.tipo),
                          subtitle: Text(
                            '${item.metrosCuadrados} m² × \$${item.precioPorMetro.toStringAsFixed(0)} / m²',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => setState(
                              () => _trabajosAgregados.removeAt(index),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (_trabajosAgregados.isNotEmpty)
                      const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _verdeApp.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _verdeApp.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal Obra:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _verdeApp,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '\$${datosEnVivo.subtotalObraTotal.toStringAsFixed(0)} CLP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _verdeApp,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Step(
                title: const Text(
                  'Cargas de Mano de Obra',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                isActive: _currentStep >= 2,
                content: ManoObraLista(
                  items: _manoObraAgregada,
                  verdeApp: _verdeApp,
                  onAgregar: _agregarManoObra,
                  onEliminar: (index) =>
                      setState(() => _manoObraAgregada.removeAt(index)),
                ),
              ),
              Step(
                title: const Text(
                  'Catálogo de Materiales',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                isActive: _currentStep >= 3,
                content: MaterialLista(
                  items: _materialesAgregados,
                  verdeApp: _verdeApp,
                  onAgregar: _agregarMaterial,
                  onEliminar: (index) =>
                      setState(() => _materialesAgregados.removeAt(index)),
                  onEditar: _editarMaterial,
                  onImportarCSV: (materiales) =>
                      setState(() => _materialesAgregados.addAll(materiales)),
                ),
              ),
              Step(
                title: const Text(
                  'Configuración de Totales',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                isActive: _currentStep >= 4,
                content: Column(
                  children: [
                    TextFormField(
                      controller: _viaticoController,
                      keyboardType: TextInputType.number,
                      validator: (val) => _validarCampoNumerico(val, 'Viático'),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Viático adicional (Opcional - CLP)',
                        prefixIcon: Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _utilidadController,
                      keyboardType: TextInputType.number,
                      validator: (val) => _validarCampoNumerico(val, '% de utilidad'),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: '% Porcentaje de Utilidad',
                        prefixIcon: Icon(Icons.trending_up),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ivaController,
                      keyboardType: TextInputType.number,
                      validator: (val) => _validarCampoNumerico(val, '% IVA Legal'),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: '% IVA Legal',
                        prefixIcon: Icon(Icons.percent),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _verdeApp,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL GENERAL NETO + IMPUESTOS',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Monto Final: \$${datosEnVivo.calcularTotalFinal().toStringAsFixed(0)} CLP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                   if (_vistaPreviaCargada && _idCotizacionCreada != null) ...[
  PrevisualizacionPdfWidget(
    cotizacion: datosEnVivo,
    materiales: _materialesAgregados,
    idCotizacion: _idCotizacionCreada!,
    manoObra: _manoObraAgregada,
    codigoCotizacion: CotizacionMapper.toDto(
      cotizacion: datosEnVivo,
      materiales: _materialesAgregados,
      usuarioId: _auth.currentUser?.uid ?? '',
      estado: 'En Proceso',
    ).codigo,
    onListo: () async {
      if (!mounted) return;

      _mostrarMensaje('¡Cotización creada con éxito!');

      Navigator.of(context).pop();
    },
  ),
  const SizedBox(height: 16),
],
                                    ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}