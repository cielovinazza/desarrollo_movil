import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../storage/local_storage.dart';

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

  Future<void> sincronizarPendientes() async {
    await _sincronizarClientes();
    await _sincronizarCotizaciones();
  }

  Future<void> _sincronizarClientes() async {
    final pendientes = await _localStorage.obtenerClientesPendientes();
    if (pendientes.isEmpty) return;

    final List<Map<String, dynamic>> noSincronizados = [];

    for (final cliente in pendientes) {
      final rut = cliente['rut']?.toString() ?? '';
      if (rut.isEmpty) continue;
      final rutNormalizado = _normalizarRut(rut);
      if (rutNormalizado.isEmpty) continue;

      try {
        final querySnapshot = await _firestore
            .collection('cliente')
            .where('rut', isEqualTo: rutNormalizado)
            .limit(1)
            .get(const GetOptions(source: Source.server));

        if (querySnapshot.docs.isNotEmpty) {
          await _reasociarCotizaciones(
            rutDuplicado: rutNormalizado,
            idClienteOriginal: rutNormalizado,
          );
          continue;
        }
        await _firestore.collection('cliente').doc(rutNormalizado).set({
          'id': rutNormalizado,
          'nombre': cliente['nombre']?.toString() ?? 'Sin Nombre',
          'rut': rut,
          'correo': cliente['correo']?.toString() ?? '',
          'telefono': cliente['telefono']?.toString() ?? '',
          'direccion': cliente['direccion']?.toString() ?? '',
        });

        await _reasociarCotizaciones(
          rutDuplicado: rutNormalizado,
          idClienteOriginal: rutNormalizado,
        );
      } catch (e) {
        if (e is FirebaseException &&
            (e.code == 'permission-denied' || e.code == 'already-exists')) {
          await _reasociarCotizaciones(
            rutDuplicado: rutNormalizado,
            idClienteOriginal: rutNormalizado,
          );
        } else {
          noSincronizados.add(cliente);
        }
      }
    }
    await _localStorage.limpiarClientesPendientes();
    if (noSincronizados.isNotEmpty) {
      for (final cl in noSincronizados) {
        await _localStorage.guardarClientePendiente(cl);
      }
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

    final batch = _firestore.batch();
    for (final cotizacion in pendientes) {
      final docRef = _firestore.collection('cotizaciones').doc();

      batch.set(docRef, {
        ...cotizacion,
        'id': docRef.id,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaEdicion': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    await _localStorage.limpiarCotizacionesPendientes();
  }
}