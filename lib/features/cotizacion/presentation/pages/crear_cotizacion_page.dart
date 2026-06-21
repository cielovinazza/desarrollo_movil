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
import '../widgets/dialogo_trabajo_form.dart';
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
  bool _cotizacionGuardada = false;
  bool _guardandoEnFirestore = false;
  String? _idCotizacionCreada;
  DateTime? fechaRecienCreada;

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
  final FocusNode _direccionFocus = FocusNode();
  
  String _formatearNumero(num valor){
    return valor % 1 == 0 ? valor.toInt().toString() 
    : valor.toString();
  }

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
      _viaticoController.text = _formatearNumero(edicion.viatico);
      _utilidadController.text = _formatearNumero(edicion.porcentajeUtilidad);
      _ivaController.text = _formatearNumero(edicion.porcentajeIva);

      _trabajosAgregados.addAll(
        CotizacionMapper.trabajosDesdeDto(edicion.trabajos),
      );
      _manoObraAgregada.addAll(
        CotizacionMapper.manoObraDesdeDto(edicion.manoObra),
      );
      _materialesAgregados.addAll(
        CotizacionMapper.materialesDesdeDto(edicion.materiales),
      );
    }
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _direccionController.dispose();
    _viaticoController.dispose();
    _utilidadController.dispose();
    _ivaController.dispose();
    _direccionFocus.dispose();
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
      fechaCreacion: widget.cotizacionAEditar?.fechaCreacion != null
        ? DateTime.parse(widget.cotizacionAEditar!.fechaCreacion!)
        : fechaRecienCreada,
      fechaEdicion: widget.cotizacionAEditar?.fechaEdicion != null
        ? DateTime.parse(widget.cotizacionAEditar!.fechaEdicion!)
        : null,
    );
  }

  Future<String> _guardarCotizacion() async {
  final cotizacion = _obtenerEstadoActual();
  final bool esEdicion = widget.cotizacionAEditar != null;
  if (!esEdicion){
    fechaRecienCreada = DateTime.now();
  }

  final int versionNueva = esEdicion
      ? (widget.cotizacionAEditar!.version + 1)
      : 1;

  final String codigoBase = widget.cotizacionAEditar?.codigo ?? '';
  final bool esRechazada= widget.cotizacionAEditar?.estado == 'Rechazada por el Cliente';
  final String codigoNuevo = (esEdicion && esRechazada)
        ? _generarCodigoVersionado(codigoBase, versionNueva)
        : codigoBase;
  

  final dto = CotizacionMapper.toDto(
    cotizacion: cotizacion,
    materiales: _materialesAgregados,
    usuarioId: _auth.currentUser?.uid ?? '',
    estado: 'En Proceso',
  );
  final String idParaDto = (esEdicion && !esRechazada)
    ? widget.cotizacionAEditar!.id
    : '';

  final dtoConId = dto.copyWith(
    id: idParaDto,
    version: versionNueva,
    codigo: codigoNuevo,
    estado: 'En Proceso',
  );

  final dtoGuardado = await guardarCotizacionUseCase(dtoConId);

  setState(() {
    _codigoCotizacionCreada = dtoGuardado.codigo;
    _idCotizacionCreada = dtoGuardado.id;
  });

  return dtoGuardado.id;
}

String _generarCodigoVersionado(String codigoBase, int versionNueva) {
  final regExp = RegExp(r'^(CT-\d+)(-V\d+)?$');
  final match = regExp.firstMatch(codigoBase);
  if (match != null) {
    final base = match.group(1) ?? codigoBase;
    return '$base-V$versionNueva';
  }
  return '$codigoBase-V$versionNueva';
}

  Future<void> _ejecutarGuardadoFinal() async {
    final theme = Theme.of(context);
    final bool? confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.help_outline, color: theme.primaryColor),
              const SizedBox(width: 10),
              const Text('Confirmación'),
            ],
          ),
          content: Text(
            widget.cotizacionAEditar != null
                ? '¿Está seguro de que desea realizar los cambios en la cotización?'
                : '¿Está seguro de guardar esta cotización?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _verdeApp,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;
    if (!mounted) return;

    setState(() {
      _guardandoEnFirestore = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Row(
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Guardando cotización y generando PDF...',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final realId = await _guardarCotizacion();

      setState(() {
        _idCotizacionCreada = realId;
        _cotizacionGuardada = true;
      });

      await _localStorage.limpiarBorradorCotizacion();

      if (!context.mounted) return;

      final repositoryPdf = CotizacionRepositoryImpl(datasource);
      final modeloActualizado = _obtenerEstadoActual();

      await PrevisualizacionPdfWidget.generarYsubirPdfEstatico(
        cotizacion: modeloActualizado,
        materiales: _materialesAgregados,
        codigoCotizacion:
            _codigoCotizacionCreada ??
            widget.cotizacionAEditar?.codigo ??
            'CT-000',
        manoObra: _manoObraAgregada,
        idCotizacion: realId,
        repository: repositoryPdf,
      );
      if (!mounted) return;
      Navigator.pop(context);

      AppDialogs.mostrarSnackBar(
        context,
        widget.cotizacionAEditar != null
            ? '¡Cotización y Pdf actualizados con éxito!'
            : '¡Cotización creada con éxito!',
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _guardandoEnFirestore = false;
      });

      if (!context.mounted) return;
      AppDialogs.mostrarSnackBar(context, 'Error al guardar la cotización: $e');
    }
  }

  Future<void> _guardarCotizacionOffline() async {
    final cotizacion = _obtenerEstadoActual();

    final dto = CotizacionMapper.toDto(
      cotizacion: cotizacion,
      materiales: _materialesAgregados,
      usuarioId: _auth.currentUser?.uid ?? '',
      estado: FlujoEstados.enProceso,
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
      'estado': FlujoEstados.enProceso,  
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
    // Cierra el teclado para que no reaparezca al volver del diálogo
    _direccionFocus.unfocus();
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

  Widget _trabajoCard(
    BuildContext context,
    ItemTrabajo item,
    int index,
    bool esOscuro,
  ) {
    return Card(
      color: esOscuro ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: esOscuro ? Colors.white24 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        leading: Icon(Icons.build_circle_outlined, color: _verdeApp),
        title: Text(
          item.tipo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: esOscuro ? Colors.white : Colors.black87),
        ),
        subtitle: Text(
          '${item.metrosCuadrados.toInt()} m² × ${CurrencyFormatter.format(item.precioPorMetro)} / m²' '\n${item.descripcionBreve ?? ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: esOscuro ? Colors.white70 : Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () {
            setState(() => _trabajosAgregados.removeAt(index));
            _autoguardar();
          },
        ),
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

    final numero = value.trim().isEmpty
        ? 0.0
        : ClpInputFormatter.toDouble(value.trim());

    if (numero < 0) {
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
        return true;

      case 4:
        return _validarCampoNumerico(_viaticoController.text, 'Viático') ==
                null &&
            _validarCampoNumerico(_utilidadController.text, '% de utilidad') ==
                null &&
            _validarCampoNumerico(_ivaController.text, '% IVA Legal') == null;

      case 5:
        return !_cotizacionGuardada;

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
        return '';

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
              '¡Atención! El margen de utilidad ingresado es inferior al 10% mínimo recomendado. '
              '¿Está seguro de que desea continuar con esta tasa de ganancia para el proyecto?',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Modificar Margen',
                  style: TextStyle(
                    color: Theme.of(ctx).hintColor,
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
    if (widget.cotizacionAEditar != null) return;

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
    if (widget.cotizacionAEditar != null) {
      final edicion = widget.cotizacionAEditar!;
      setState(() {
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
        _viaticoController.text = _formatearNumero(edicion.viatico);
        _utilidadController.text = _formatearNumero(edicion.porcentajeUtilidad);
        _ivaController.text = _formatearNumero(edicion.porcentajeIva);
        _trabajosAgregados.addAll(
          edicion.trabajos.map(
            (item) => ItemTrabajo(
              tipo: item.tipo,
              metrosCuadrados: item.metrosCuadrados,
              precioPorMetro: item.precioPorMetro,
              descripcionBreve: item.descripcionBreve,
            ),
          ),
        );
        _manoObraAgregada.addAll(
          edicion.manoObra.map(
            (item) => ManoDeObra(
              cargo: item.cargo,
              dias: item.dias,
              valorJornada: item.valorJornada,
            ),
          ),
        );
        _materialesAgregados.addAll(
          edicion.materiales.map(
            (item) => MaterialEntity(
              nombre: item.nombre,
              cantidad: item.cantidad,
              costoUnitario: item.costoUnitario,
              unidadMedida: item.unidadMedida,
            ),
          ),
        );
      });
      return;
    }

    final raw = await _localStorage.obtenerBorradorCotizacion();
    if (widget.clienteInyectado != null) {
      if (!mounted) return;
      setState(() {
        _clienteSeleccionado = widget.clienteInyectado;
        _clienteController.text = widget.clienteInyectado!.nombre;
      });
      return;
    }
    if (raw == null) {
      return;
    }

    if (!mounted) return;
    final continuar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Borrador encontrado',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tienes un formulario sin terminar. ¿Deseas continuar donde lo dejaste?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Descartar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (continuar != true) {
      await _localStorage.limpiarBorradorCotizacion();
      return;
    }

    final dto = BorradorCotizacionDto.fromJson(raw);

    setState(() {
      _clienteSeleccionado = BorradorCotizacionMapper.clienteFromDto(dto);
      if (dto.clienteTexto.trim().isEmpty) {
        _clienteSeleccionado = null;
      }
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

    await _autoguardar();
  }

  @override
  Widget build(BuildContext context) {
    final datosEnVivo = _obtenerEstadoActual();
    final theme = Theme.of(context);
    final esOscuro = theme.brightness == Brightness.dark;

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
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: _verdeApp, secondary: _verdeApp),
          ),
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
                        texto: _currentStep == 5
                            ? (_cotizacionGuardada
                                  ? 'Cotización guardada'
                                  : (widget.cotizacionAEditar != null
                                        ? 'Guardar Cambios'
                                        : 'Guardar Cotización'))
                            : 'Continuar',
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
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _mensajeBloqueoPaso(),
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
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
                if (_clienteSeleccionado == null) {
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
                    'Debes añadir al menos un trabajo',
                  );
                  return;
                }
              }

              if (_currentStep == 2) {
                if (_manoObraAgregada.isEmpty) {
                  AppDialogs.mostrarSnackBar(
                    context,
                    'Debes añadir al menos una carga de mano de obra',
                  );
                  return;
                }
              }

              await _autoguardar();

              if (_currentStep == 4) {
                final margenUtilidad =
                    double.tryParse(_utilidadController.text) ?? 0.0;
                if (margenUtilidad < 10.0) {
                  final deseaContinuar = await _mostrarAlertaRentabilidadBaja();
                  if (!deseaContinuar) return;
                }
              }

              if (_currentStep < 5) {
                setState(() {
                  _currentStep += 1;
                });
                await _autoguardar();
              } else {
                if (_cotizacionGuardada) return;

                if (!_formKey.currentState!.validate()) {
                  if (!context.mounted) return;
                  AppDialogs.mostrarSnackBar(
                    context,
                    'Formulario inválido. Corrija los campos en rojo antes de continuar.',
                  );
                  return;
                }

                if (_guardandoEnFirestore) return;

                try {
                  final hayConexion = await _hayConexionInternet();

                  if (!hayConexion) {
                    await _guardarCotizacionOffline();
                    await _localStorage.limpiarBorradorCliente();
                    setState(() => _guardandoEnFirestore = false);
                    await _cerrarFlujoOffline();
                    return;
                  }
                  await _ejecutarGuardadoFinal();

                } on TimeoutException {
                  await _guardarCotizacionOffline();
                  await _localStorage.limpiarBorradorCotizacion();
                  if (!mounted) return;
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
                      clienteInicial: _clienteSeleccionado,
                      onClienteSeleccionado: (Cliente? cliente) {
                        setState(() => _clienteSeleccionado = cliente);
                        if (cliente == null) {
                          _clienteController.clear();
                        } else {
                          _clienteController.text = cliente.nombre;
                        }
                        _autoguardar();
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
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextFormField(
                        controller: _direccionController,
                        focusNode: _direccionFocus,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Dirección general del proyecto',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(),
                        ),
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
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No has añadido ningún trabajo todavía.',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      ),
                    if (_trabajosAgregados.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 360),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: _trabajosAgregados.length,
                            itemBuilder: (context, index) {
                              final item = _trabajosAgregados[index];

                              return _trabajoCard(
                                context,
                                item,
                                index,
                                esOscuro,
                              );
                            },
                          ),
                        ),
                      ),
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
                          Flexible(
                            child: Text(
                              'Subtotal Obra:',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _verdeApp,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${CurrencyFormatter.format(datosEnVivo.subtotalObraTotal)} CLP',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _verdeApp,
                                fontSize: 16,
                              ),
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
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextFormField(
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
                        LengthLimitingTextInputFormatter(5),
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
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
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              Step(
                title: const Text(
                  'Previsualización y Confirmación',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                isActive: _currentStep >= 5,
                content: PrevisualizacionPdfWidget(
                  cotizacion: datosEnVivo,
                  materiales: _materialesAgregados,
                  idCotizacion: _idCotizacionCreada ?? '',
                  manoObra: _manoObraAgregada,
                  codigoCotizacion: _codigoCotizacionCreada ?? 'CT-000',
                  habilitado: true,
                  onListo: () async {
                    if (_cotizacionGuardada) return;

                    if (!_formKey.currentState!.validate()) {
                      if (!context.mounted) return;
                      AppDialogs.mostrarSnackBar(
                        context,
                        'Formulario inválido, corrija los campos en rojo.',
                      );
                      return;
                    }

                    AppDialogs.mostrarSnackBar(
                      context,
                      'Cotización subida con éxito.',
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}