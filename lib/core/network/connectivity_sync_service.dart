import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../storage/local_storage.dart';
import '../../features/cliente/presentation/formatters/mascara_rut_formatters.dart';

class ConnectivitySyncService {
  final LocalStorage _localStorage;
  final FirebaseFirestore _firestore;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivitySyncService({
    LocalStorage? localStorage,
    FirebaseFirestore? firestore,
  }) : _localStorage = localStorage ?? LocalStorage(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> iniciar() async {
    _subscription = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged,);
    final resultadoInicial = await Connectivity().checkConnectivity();
    final hayConexionInicial = resultadoInicial.any((r) => r != ConnectivityResult.none,);
    if (hayConexionInicial) {
      await sincronizarPendientes();
    }
  }

  void detener() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final hayConexion = results.any((r) => r != ConnectivityResult.none);
    if (hayConexion) {
      await sincronizarPendientes();
    }
  }

  
  String _normalizarRut(String rut) {
    return rut.replaceAll('.', '').replaceAll('-', '').trim().toUpperCase();
  }

  String _extraerRutDeCotizacion(Map<String, dynamic> cotizacion) {
    final rut = cotizacion['clienteRut']?.toString() ?? '';
    return _normalizarRut(rut);
  }

  bool _isSyncing = false;
  Future<void> sincronizarPendientes() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await _sincronizarClientes();
      await _sincronizarCotizaciones();
    } finally {
      _isSyncing = false;
    }
  }

Future<void> _sincronizarClientes() async {
  final pendientes = await _localStorage.obtenerClientesPendientes();
  if (pendientes.isEmpty) return;

  final List<Map<String, dynamic>> noSincronizados = [];

  for (final cliente in pendientes) {
    final rut = cliente['rut']?.toString() ?? '';
    if (rut.isEmpty) continue;
    final rutFormateado = RutInputFormatter.formatear(rut);
    if (rutFormateado.isEmpty) continue;

    try {
      final docRef = _firestore.collection('cliente').doc(rutFormateado);
      final docSnapshot = await docRef.get(
        const GetOptions(source: Source.server),
      );

      if (docSnapshot.exists) {
        await _reasociarCotizaciones(
          rutDuplicado: _normalizarRut(rut),
          idClienteOriginal: rutFormateado,
        );
        continue;
      }

      await docRef.set({
        'id': rutFormateado,
        'nombre': cliente['nombre']?.toString() ?? 'Sin Nombre',
        'rut': rutFormateado,
        'correo': cliente['correo']?.toString() ?? '',
        'telefono': cliente['telefono']?.toString() ?? '',
        'direccion': cliente['direccion']?.toString() ?? '',
      });

      await _reasociarCotizaciones(
        rutDuplicado: _normalizarRut(rut),
        idClienteOriginal: rutFormateado,
      );
    } catch (e) {
      if (e is FirebaseException &&
          (e.code == 'permission-denied' || e.code == 'already-exists')) {
        await _reasociarCotizaciones(
          rutDuplicado: _normalizarRut(rut),
          idClienteOriginal: rutFormateado,
        );
      } else {
        noSincronizados.add(cliente);
      }
    }
  }

  await _localStorage.limpiarClientesPendientes();
  for (final cl in noSincronizados) {
    await _localStorage.guardarClientePendiente(cl);
  }
}

  Future<void> _reasociarCotizaciones({
  required String rutDuplicado,
    required String idClienteOriginal,
  }) async {
    final pendientes = await _localStorage.obtenerCotizacionesPendientes();
    if (pendientes.isEmpty) return;
    final rutDuplicadoNormalizado = _normalizarRut(rutDuplicado);

    final actualizadas = pendientes.map((cotizacion) {
      final rutCotizacion = _extraerRutDeCotizacion(cotizacion);
      if (rutCotizacion.isEmpty) return cotizacion;
      if (rutCotizacion == rutDuplicadoNormalizado) {
        return {...cotizacion, 'clienteId': idClienteOriginal};
      }
      return cotizacion;
    }).toList();

    await _localStorage.limpiarCotizacionesPendientes();
    for (final cotizacion in actualizadas) {
      await _localStorage.guardarCotizacionPendiente(cotizacion);
    }
  }
  
  Future<void> _sincronizarCotizaciones() async {
    final pendientes = await _localStorage.obtenerCotizacionesPendientes();
    if (pendientes.isEmpty) return;

    const clavesLocales = {'guardadoOffline', 'pdfPendiente', 'fechaCreacionLocal'};
    final List<Map<String, dynamic>> noSincronizadas = [];

    for (final cotizacion in pendientes) {
      try {
        final docRef = _firestore.collection('cotizaciones').doc();


        final datosLimpios = Map<String, dynamic>.from(cotizacion)
          ..removeWhere((key, _) => clavesLocales.contains(key));

        final codigoActual = datosLimpios['codigo']?.toString() ?? '';
        String codigoFinal = codigoActual;

        if (codigoActual.isEmpty || codigoActual.startsWith('LOCAL-')) {
          final contadorRef = _firestore
              .collection('contadores')
              .doc('cotizaciones');
          codigoFinal = await _firestore.runTransaction((transaction) async {
            final snapshot = await transaction.get(contadorRef);
            int siguienteNumero = 1;
            if (snapshot.exists) {
              final datos = snapshot.data();
              final ultimoNumero = datos?['ultimoNumero'] as int? ?? 0;
              siguienteNumero = ultimoNumero + 1;
            }
            transaction.set(contadorRef, {
              'ultimoNumero': siguienteNumero,
            }, SetOptions(merge: true));
            return 'CT-${siguienteNumero.toString().padLeft(3, '0')}';
          });
        }

        await docRef.set({
          ...datosLimpios,
          'id': docRef.id,
          'codigo': codigoFinal,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'fechaEdicion': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        noSincronizadas.add(cotizacion);
      }
    }
    
    await _localStorage.limpiarCotizacionesPendientes();
    if (noSincronizadas.isNotEmpty) {
      for (final cotizacion in noSincronizadas) {
        await _localStorage.guardarCotizacionPendiente(cotizacion);
      }
    }
  }
}