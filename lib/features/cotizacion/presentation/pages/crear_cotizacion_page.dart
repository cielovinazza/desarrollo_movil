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
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/clp_input_formatter.dart';
import '../../../../shared/widgets/app_dialogs.dart';
import '../../../../core/storage/local_storage.dart';
import '../../data/dtos/borrador_cotizacion_dto.dart';
import '../../data/mappers/borrador_cotizacion_mapper.dart';
import '../../../../shared/widgets/boton_bloqueo_visual.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class CrearCotizacionPage extends StatefulWidget {
  final Cliente? clienteInyectado;
  final CotizacionDto? cotizacionAEditar;

  const CrearCotizacionPage({
    super.key,
    this.clienteInyectado,
    this.cotizacionAEditar,
  });

  @override
  State<CrearCotizacionPage> createState() => _CrearCotizacionPageState();
}

class _CrearCotizacionPageState extends State<CrearCotizacionPage> {
  final _formKey = GlobalKey<FormState>();
  String? _codigoCotizacionCreada;
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
  final _localStorage = LocalStorage();

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

    datasource = CotizacionFirestoreDataSource(FirebaseFirestore.instance);
    final repository = CotizacionRepositoryImpl(datasource);
    guardarCotizacionUseCase = GuardarCotizacion(repository);
    _recuperarBorrador();
    _clienteController.addListener(_autoguardar);
    _direccionController.addListener(_autoguardar);
    _viaticoController.addListener(_autoguardar);
    _utilidadController.addListener(_autoguardar);
    _ivaController.addListener(_autoguardar);

    if (widget.clienteInyectado != null) {
      _clienteSeleccionado = widget.clienteInyectado;
      _clienteController.text = widget.clienteInyectado!.nombre;
    }

    if (widget.cotizacionAEditar != null) {
      final edicion = widget.cotizacionAEditar!;
      _idCotizacionCreada = edicion.id;
      _codigoCotizacionCreada = edicion.codigo;

      _clienteSeleccionado = Cliente(
        id: edicion.clienteId,
        nombre: edicion.clienteNombre,
        correo: edicion.clienteEmail,
        rut: edicion.clienteRut,
        telefono: edicion.clienteTelefono,
        direccion: edicion.clienteDireccion,
      );
      _clienteController.text = edicion.clienteNombre;
      _direccionController.text = edicion.direccion;
      _viaticoController.text = edicion.viatico?.toString() ?? '';
      _utilidadController.text = edicion.porcentajeUtilidad.toString();
      _ivaController.text = edicion.porcentajeIva.toString();

      // 1. Mapeo Seguro de Trabajos
      if (edicion.trabajos.isNotEmpty) {
        _trabajosAgregados.addAll(
          edicion.trabajos.map((item) {
            if (item is ItemTrabajo) return item;
            final map = item as Map<String, dynamic>;
            return ItemTrabajo(
              tipo: map['tipo'] ?? '',
              metrosCuadrados: (map['metrosCuadrados'] ?? 0).toDouble(),
              precioPorMetro: (map['precioPorMetro'] ?? 0).toDouble(),
              descripcionBreve: map['descripcionBreve'],
            );
          }),
        );
      }

      // 2. Mapeo Seguro de Mano de Obra (Campos reales: cargo, dias, valorJornada)
      if (edicion.manoObra.isNotEmpty) {
        _manoObraAgregada.addAll(
          edicion.manoObra.map((item) {
            if (item is ManoDeObra) return item;
            final map = item as Map<String, dynamic>;
            return ManoDeObra(
              cargo: map['cargo'] ?? map['detalle'] ?? '',
              dias: (map['dias'] ?? 0).toInt(),
              valorJornada: (map['valorJornada'] ?? map['costo'] ?? 0)
                  .toDouble(),
            );
          }),
        );
      }

      // 3. Mapeo Seguro de Materiales (Campos reales: nombre, cantidad, costoUnitario, unidadMedida)
      if (edicion.materiales.isNotEmpty) {
        _materialesAgregados.addAll(
          edicion.materiales.map((item) {
            if (item is MaterialEntity) return item;
            final map = item as Map<String, dynamic>;
            return MaterialEntity(
              nombre: map['nombre'] ?? '',
              cantidad: (map['cantidad'] ?? 0).toDouble(),
              costoUnitario:
                  (map['costoUnitario'] ?? map['precioUnitario'] ?? 0)
                      .toDouble(),
              unidadMedida: map['unidadMedida'] ?? '',
            );
          }),
        );
      }
    }
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _direccionController.dispose();
    _viaticoController.dispose();
    _utilidadController.dispose();
    _ivaController.dispose();
    _clienteController.removeListener(_autoguardar);
    _direccionController.removeListener(_autoguardar);
    _viaticoController.removeListener(_autoguardar);
    _utilidadController.removeListener(_autoguardar);
    _ivaController.removeListener(_autoguardar);
    super.dispose();
  }

  CotizacionModel _obtenerEstadoActual() {
    final viaticoTexto = _viaticoController.text.trim();
    final double? viaticoValor = viaticoTexto.isEmpty
        ? null
        : ClpInputFormatter.toDouble(viaticoTexto);
    final clienteSeguro =
        _clienteSeleccionado ??
        Cliente(
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

    final String idReal =
        widget.cotizacionAEditar?.id ??
        FirebaseFirestore.instance.collection('cotizaciones').doc().id;

    final int versionNueva = widget.cotizacionAEditar != null
        ? (widget.cotizacionAEditar!.version + 1)
        : 1;

    final String codigoEstablecido = widget.cotizacionAEditar?.codigo ?? '';

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
      codigo: codigoEstablecido.isNotEmpty ? codigoEstablecido : dto.codigo,
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
      version: versionNueva,
    );

    await guardarCotizacionUseCase(dtoConId);
    final docSnapshot = await FirebaseFirestore.instance
        .collection('cotizaciones')
        .doc(idReal)
        .get();

    if (docSnapshot.exists) {
      final datosGuardados = docSnapshot.data();
      final codigoAsignado = datosGuardados?['codigo'] as String?;
      setState(() {
        _codigoCotizacionCreada = codigoAsignado;
      });
    }

    return idReal;
  }

  Future<void> _guardarCotizacionOffline() async {
    final cotizacion = _obtenerEstadoActual();

    final dto = CotizacionMapper.toDto(
      cotizacion: cotizacion,
      materiales: _materialesAgregados,
      usuarioId: _auth.currentUser?.uid ?? '',
      estado: 'Pendiente de sincronización',
    );

    final idLocal = 'local-${DateTime.now().millisecondsSinceEpoch}';
    final codigoLocal = 'LOCAL-${DateTime.now().millisecondsSinceEpoch}';

    final datosOffline = {
      'id': idLocal,
      'clienteId': dto.clienteId,
      'clienteNombre': dto.clienteNombre,
      'clienteEmail': dto.clienteEmail,
      'clienteRut': dto.clienteRut,
      'clienteTelefono': dto.clienteTelefono,
      'clienteDireccion': dto.clienteDireccion,
      'codigo': codigoLocal,
      'direccion': dto.direccion,
      'trabajos': dto.trabajos,
      'manoObra': dto.manoObra,
      'materiales': dto.materiales,
      'subtotalObra': dto.subtotalObra,
      'subtotalMateriales': dto.subtotalMateriales,
      'subtotalManoObra': dto.subtotalManoObra,
      'viatico': dto.viatico,
      'porcentajeUtilidad': dto.porcentajeUtilidad,
      'porcentajeIva': dto.porcentajeIva,
      'totalFinal': dto.totalFinal,
      'estado': 'Pendiente de sincronización',
      'usuarioId': dto.usuarioId,
      'version': 1,
      'pdfUrl': null,
      'pdfPendiente': true,
      'guardadoOffline': true,
      'fechaCreacionLocal': DateTime.now().toIso8601String(),
    };

    await _localStorage.guardarCotizacionPendiente(datosOffline);
    await _localStorage.limpiarBorradorCotizacion();
  }

  Future<void> _agregarMaterial() async {
    final resultado = await showDialog<MaterialEntity>(
      context: context,
      builder: (_) => MaterialDialog(verdeApp: _verdeApp),
    );
    if (resultado != null) {
      setState(() => _materialesAgregados.add(resultado));
      _autoguardar();
    }
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

  void _mostrarDialogoAgregarTrabajo() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DialogoTrabajoForm(
        tiposDisponibles: _tiposDisponibles,
        verdeApp: _verdeApp,
        onGuardar: (tipo, m2, precio, descripcion) {
          setState(() {
            _trabajosAgregados.add(
              ItemTrabajo(
                tipo: tipo,
                metrosCuadrados: m2,
                precioPorMetro: precio,
                descripcionBreve: descripcion.isEmpty ? null : descripcion,
              ),
            );
          });

          _autoguardar();
        },
        onNuevoTipoCreado: (nuevoTipo) {
          setState(() {
            if (!_tiposDisponibles.contains(nuevoTipo)) {
              _tiposDisponibles.add(nuevoTipo);
            }
          });
        },
      ),
    );
  }

  Future<void> _agregarManoObra() async {
    final resultado = await showDialog<ManoDeObra>(
      context: context,
      builder: (_) => ManoObraDialog(verdeApp: _verdeApp),
    );
    if (resultado != null) {
      setState(() => _manoObraAgregada.add(resultado));
      _autoguardar();
    }
  }

  String? _validarCampoNumerico(String? value, String nombreCampo) {
    if (value == null || value.trim().isEmpty) {
      if (nombreCampo == 'Viático') return null;
      return 'El campo $nombreCampo es obligatorio';
    }

    final numero = double.tryParse(value.trim());

    if (numero == null || numero < 0) {
      return 'Ingrese solo caracteres numéricos válidos';
    }

    if (nombreCampo == '% IVA Legal' && numero > 35) {
      return 'El IVA no puede superar el 35%';
    }
    if (nombreCampo == '% de utilidad' && numero > 500) {
      return 'La utilidad no puede superar el 500%';
    }
    return null;
  }

  bool _pasoActualValido() {
    switch (_currentStep) {
      case 0:
        return _clienteController.text.trim().isNotEmpty;

      case 1:
        return _direccionController.text.trim().isNotEmpty &&
            _trabajosAgregados.isNotEmpty;

      case 2:
        return _manoObraAgregada.isNotEmpty;

      case 3:
        return _materialesAgregados.isNotEmpty;

      case 4:
        return _validarCampoNumerico(_viaticoController.text, 'Viático') ==
                null &&
            _validarCampoNumerico(_utilidadController.text, '% de utilidad') ==
                null &&
            _validarCampoNumerico(_ivaController.text, '% IVA Legal') == null;

      default:
        return false;
    }
  }

  String _mensajeBloqueoPaso() {
    switch (_currentStep) {
      case 0:
        return 'Selecciona o ingresa un cliente para continuar.';

      case 1:
        if (_direccionController.text.trim().isEmpty) {
          return 'Ingresa la dirección general del proyecto.';
        }
        return 'Añade al menos un ítem de construcción.';

      case 2:
        return 'Añade al menos una carga de mano de obra.';

      case 3:
        return 'Añade al menos un material al catálogo.';

      case 4:
        return 'Corrige los campos numéricos antes de guardar.';

      default:
        return 'Completa la información requerida.';
    }
  }

  Future<bool> _hayConexionInternet() async {
    final resultados = await Connectivity().checkConnectivity();

    return resultados.any((resultado) => resultado != ConnectivityResult.none);
  }

  Future<bool> _mostrarAlertaRentabilidadBaja() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Alerta de Rentabilidad',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            content: const Text(
              '¡Atención contratista! El margen de utilidad ingresado es inferior al 10% mínimo recomendado. '
              '¿Está seguro de que desea continuar con esta tasa de ganancia para el proyecto?',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Modificar Margen',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Sí, continuar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _cerrarFlujoOffline() async {
    if (!context.mounted) return;

    AppDialogs.mostrarSnackBar(
      context,
      'Datos guardados localmente. El PDF se podrá generar desde el historial cuando recuperes conexión.',
    );

    Navigator.of(context).pop();
  }

  Future<void> _autoguardar() async {
    print('AUTOGUARDANDO');
    final dto = BorradorCotizacionMapper.toDto(
      cliente: _clienteSeleccionado,
      clienteTexto: _clienteController.text,
      direccion: _direccionController.text,
      viatico: _viaticoController.text,
      utilidad: _utilidadController.text,
      iva: _ivaController.text,
      currentStep: _currentStep,
      trabajos: _trabajosAgregados,
      materiales: _materialesAgregados,
      manoObra: _manoObraAgregada,
    );
    await _localStorage.guardarBorradorCotizacion(dto.toJson());
  }

  Future<void> _recuperarBorrador() async {
    final raw = await _localStorage.obtenerBorradorCotizacion();
    if (raw == null) return;

    final dto = BorradorCotizacionDto.fromJson(raw);

    setState(() {
      _clienteSeleccionado = BorradorCotizacionMapper.clienteFromDto(dto);
      _clienteController.text = dto.clienteTexto;
      _direccionController.text = dto.direccion;
      _viaticoController.text = dto.viatico;
      _utilidadController.text = dto.utilidad;
      _ivaController.text = dto.iva;
      _currentStep = dto.currentStep;
      _trabajosAgregados
        ..clear()
        ..addAll(BorradorCotizacionMapper.trabajosFromDto(dto));
      _materialesAgregados
        ..clear()
        ..addAll(BorradorCotizacionMapper.materialesFromDto(dto));
      _manoObraAgregada
        ..clear()
        ..addAll(BorradorCotizacionMapper.manoObraFromDto(dto));
    });
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
            controlsBuilder: (context, details) {
              final pasoValido = _pasoActualValido();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BotonBloqueoVisual(
                        habilitado: pasoValido,
                        cargando: _guardandoEnFirestore,
                        onPressed: details.onStepContinue,
                        texto: _currentStep == 4
                            ? 'Guardar y Previsualizar'
                            : 'Continuar',
                        icon: _currentStep == 4
                            ? Icons.save_alt_outlined
                            : Icons.arrow_forward_rounded,
                        colorActivo: _verdeApp,
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _guardandoEnFirestore
                            ? null
                            : details.onStepCancel,
                        child: Text(_currentStep == 0 ? 'Salir' : 'Atrás'),
                      ),
                    ],
                  ),

                  if (!pasoValido) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _mensajeBloqueoPaso(),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
            onStepContinue: () async {
              if (_currentStep == 0) {
                if (_clienteController.text.trim().isEmpty) {
                  AppDialogs.mostrarSnackBar(
                    context,
                    'Debes ingresar o seleccionar un cliente',
                  );
                  return;
                }
              }

              if (_currentStep == 1) {
                if (_direccionController.text.trim().isEmpty) {
                  AppDialogs.mostrarSnackBar(
                    context,
                    'Debes ingresar la dirección de la obra',
                  );
                  return;
                }
                if (_trabajosAgregados.isEmpty) {
                  AppDialogs.mostrarSnackBar(
                    context,
                    'Debes ingresar la dirección de la obra',
                  );
                  return;
                }
              }
              if (_currentStep == 2 && _manoObraAgregada.isEmpty) {
                AppDialogs.mostrarSnackBar(
                  context,
                  'Debes añadir al menos una carga de mano de obra',
                );
                return;
              }

              if (_currentStep == 3 && _materialesAgregados.isEmpty) {
                AppDialogs.mostrarSnackBar(
                  context,
                  'Debes añadir al menos un material',
                );
                return;
              }
              if (_currentStep < 4) {
                setState(() {
                  if (_currentStep == 3) {
                    _vistaPreviaCargada = false;
                  }
                  _currentStep += 1;
                });
                _autoguardar();
              } else {
                if (!_formKey.currentState!.validate()) {
                  AppDialogs.mostrarSnackBar(
                    context,
                    'Formulario inválido. Corrija los campos en rojo antes de guardar.',
                  );
                  return;
                }

                final margenUtilidad =
                    double.tryParse(_utilidadController.text) ?? 0.0;
                if (margenUtilidad < 10.0) {
                  final deseaContinuar = await _mostrarAlertaRentabilidadBaja();
                  if (!deseaContinuar) return;
                }

                if (_guardandoEnFirestore) return;

                setState(() => _guardandoEnFirestore = true);

                try {
                  final hayConexion = await _hayConexionInternet();

                  if (!hayConexion) {
                    await _guardarCotizacionOffline();

                    if (!context.mounted) return;

                    setState(() => _guardandoEnFirestore = false);

                    await _cerrarFlujoOffline();
                    return;
                  }

                  final realId = await _guardarCotizacion().timeout(
                    const Duration(seconds: 5),
                  );

                  setState(() {
                    _idCotizacionCreada = realId;
                    _vistaPreviaCargada = true;
                    _guardandoEnFirestore = false;
                  });

                  await _localStorage.limpiarBorradorCotizacion();

                  if (!context.mounted) return;

                  AppDialogs.mostrarSnackBar(
                    context,
                    'Cotización creada con éxito.',
                  );
                } on TimeoutException {
                  await _guardarCotizacionOffline();

                  if (!context.mounted) return;

                  setState(() => _guardandoEnFirestore = false);

                  await _cerrarFlujoOffline();
                } catch (e) {
                  if (!context.mounted) return;

                  setState(() => _guardandoEnFirestore = false);

                  AppDialogs.mostrarSnackBar(
                    context,
                    'Error de persistencia: $e',
                  );
                }
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
                _autoguardar();
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
                content: IgnorePointer(
                  ignoring:
                      widget.clienteInyectado != null ||
                      widget.cotizacionAEditar != null,
                  child: Opacity(
                    opacity:
                        widget.clienteInyectado != null ||
                            widget.cotizacionAEditar != null
                        ? 0.6
                        : 1.0,
                    child: SelectorCliente(
                      controller: _clienteController,
                      onClienteSeleccionado: (Cliente cliente) {
                        setState(() => _clienteSeleccionado = cliente);
                      },
                    ),
                  ),
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
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
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
                          label: const Text('Añadir'),
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
                            '${item.metrosCuadrados} m² × ${CurrencyFormatter.format(item.precioPorMetro)} / m²',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              setState(
                                () => _trabajosAgregados.removeAt(index),
                              );
                              _autoguardar();
                            },
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
                            '${CurrencyFormatter.format(datosEnVivo.subtotalObraTotal)} CLP',
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
                  onEliminar: (index) {
                    setState(() => _manoObraAgregada.removeAt(index));
                    _autoguardar();
                  },
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
                  onEliminar: (index) {
                    setState(() => _materialesAgregados.removeAt(index));
                    _autoguardar();
                  },
                  onEditar: _editarMaterial,
                  onImportarCSV: (materiales) {
                    setState(() => _materialesAgregados.addAll(materiales));
                    _autoguardar();
                  },
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
                      inputFormatters: [ClpInputFormatter(maxDigits: 9)],
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
                      validator: (val) =>
                          _validarCampoNumerico(val, '% de utilidad'),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,3}\.?\d{0,2}'),
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
                      validator: (val) =>
                          _validarCampoNumerico(val, '% IVA Legal'),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(3),
                        FilteringTextInputFormatter.digitsOnly,
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
                            'Monto Final: ${CurrencyFormatter.format(datosEnVivo.calcularTotalFinal())} CLP',
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
                        codigoCotizacion: _codigoCotizacionCreada ?? 'CT-000',

                        onListo: () async {
                          await _localStorage.limpiarBorradorCotizacion();
                          if (!context.mounted) return;

                          AppDialogs.mostrarSnackBar(
                            context,
                            '¡Cotización creada con éxito!',
                          );

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

class DialogoTrabajoForm extends StatefulWidget {
  final List<String> tiposDisponibles;
  final Color verdeApp;
  final void Function(String tipo, double m2, double precio, String descripcion)
  onGuardar;
  final void Function(String nuevoTipo) onNuevoTipoCreado;

  const DialogoTrabajoForm({
    super.key,
    required this.tiposDisponibles,
    required this.verdeApp,
    required this.onGuardar,
    required this.onNuevoTipoCreado,
  });

  @override
  State<DialogoTrabajoForm> createState() => _DialogoTrabajoFormState();
}

class _DialogoTrabajoFormState extends State<DialogoTrabajoForm> {
  late String tipoSeleccionado;
  final m2ItemController = TextEditingController();
  final precioItemController = TextEditingController();
  final descripcionItemController = TextEditingController();
  String? errorM2;
  String? errorPrecio;

  @override
  void initState() {
    super.initState();
    tipoSeleccionado = widget.tiposDisponibles.first;
  }

  @override
  void dispose() {
    m2ItemController.dispose();
    precioItemController.dispose();
    descripcionItemController.dispose();
    super.dispose();
  }

  void _mostrarDialogoCrearTipoTrabajo() {
    final nuevoTipoController = TextEditingController();
    final formKeyTipo = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (subContext) => AlertDialog(
        title: const Text('Nuevo tipo de trabajo'),
        content: Form(
          key: formKeyTipo,
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
              Navigator.of(subContext).pop();
              nuevoTipoController.dispose();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.verdeApp,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKeyTipo.currentState!.validate()) {
                final nuevoTipo = nuevoTipoController.text.trim();
                widget.onNuevoTipoCreado(nuevoTipo);
                setState(() {
                  tipoSeleccionado = nuevoTipo;
                });
                Navigator.of(subContext).pop();
                nuevoTipoController.dispose();
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.add_task, color: widget.verdeApp),
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
              initialValue: widget.tiposDisponibles.contains(tipoSeleccionado)
                  ? tipoSeleccionado
                  : widget.tiposDisponibles.first,
              decoration: const InputDecoration(
                labelText: 'Tipo de Rubro',
                border: OutlineInputBorder(),
              ),
              items: widget.tiposDisponibles
                  .map(
                    (tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => tipoSeleccionado = value);
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _mostrarDialogoCrearTipoTrabajo,
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
                LengthLimitingTextInputFormatter(3),
                FilteringTextInputFormatter.digitsOnly,
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
                decimal: false,
              ),
              inputFormatters: [ClpInputFormatter(maxDigits: 9)],
              decoration: InputDecoration(
                labelText: 'Precio por m² (CLP)',
                prefixIcon: const Icon(Icons.sell_outlined),
                border: const OutlineInputBorder(),
                errorText: errorPrecio,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descripcionItemController,
              maxLength: 200,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción breve (Opcional)',
                hintText: 'Ej: Aplicación de dos manos de pintura látex...',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            final m2Texto = m2ItemController.text.trim();
            final precioTexto = precioItemController.text.trim();
            final descripcionTexto = descripcionItemController.text.trim();

            final m2 = double.tryParse(m2Texto);
            final precio = ClpInputFormatter.toDouble(precioTexto);

            setState(() {
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

            widget.onGuardar(tipoSeleccionado, m2!, precio!, descripcionTexto);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.verdeApp,
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar Ítem'),
        ),
      ],
    );
  }
}
