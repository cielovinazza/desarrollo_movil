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
    _subscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
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

    for (final cliente in pendientes) {
      final rut = cliente['rut'] as String?;
      if (rut == null || rut.isEmpty) continue;

      final query = await _firestore
          .collection('cliente')
          .where('rut', isEqualTo: rut)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final clienteExistenteId = query.docs.first.id;
        await _reasociarCotizaciones(
          rutDuplicado: rut,
          idClienteOriginal: clienteExistenteId,
        );
        // No crear el cliente duplicado
        continue;
      }

      // No existe — crear normalmente
      final docRef = _firestore.collection('cliente').doc();
      await docRef.set({...cliente, 'id': docRef.id});
    }

    await _localStorage.limpiarClientesPendientes();
  }

  Future<void> _reasociarCotizaciones({
    required String rutDuplicado,
    required String idClienteOriginal,
  }) async {
    final pendientes = await _localStorage.obtenerCotizacionesPendientes();
    if (pendientes.isEmpty) return;

    final actualizadas = pendientes.map((cotizacion) {
      final clienteData = cotizacion['cliente'] as Map<String, dynamic>?;
      if (clienteData != null && clienteData['rut'] == rutDuplicado) {
        return {
          ...cotizacion,
          'cliente': {...clienteData, 'id': idClienteOriginal},
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
