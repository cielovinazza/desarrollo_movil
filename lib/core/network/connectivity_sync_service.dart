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

  void iniciar() {
    _subscription = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
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

      try {
        final querySnapshot = await _firestore
            .collection('cliente')
            .where('rut', isEqualTo: rut)
            .limit(1)
            .get(const GetOptions(source: Source.server));

        if (querySnapshot.docs.isNotEmpty) {
          await _reasociarCotizaciones(rutDuplicado: rut, idClienteOriginal: rut);
          continue;
        }
        await _firestore.collection('cliente').doc(rut).set({
          'id': rut,
          'nombre': cliente['nombre']?.toString() ?? 'Sin Nombre',
          'rut': rut,
          'correo': cliente['correo']?.toString() ?? '',
          'telefono': cliente['telefono']?.toString() ?? '',
          'direccion': cliente['direccion']?.toString() ?? '',
        });

        await _reasociarCotizaciones(rutDuplicado: rut, idClienteOriginal: rut);

      } catch (e) {
        if (e is FirebaseException && (e.code == 'permission-denied' || e.code == 'already-exists')) {
          await _reasociarCotizaciones(rutDuplicado: rut, idClienteOriginal: rut);
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

    final actualizadas = pendientes.map((cotizacion) {
      if (cotizacion['clienteRut'] == rutDuplicado) {
        return {
          ...cotizacion,
          'clienteId': idClienteOriginal,
        };
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
      batch.set(docRef, {...cotizacion, 'id': docRef.id});
    }
    await batch.commit();
    await _localStorage.limpiarCotizacionesPendientes();
  }
}