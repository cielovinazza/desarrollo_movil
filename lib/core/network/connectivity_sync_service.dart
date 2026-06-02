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
  })  : _localStorage = localStorage ?? LocalStorage(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  void iniciar() {
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
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

    final batch = _firestore.batch();
    for (final cliente in pendientes) {
      final docRef = _firestore.collection('cliente').doc();
      batch.set(docRef, {...cliente, 'id': docRef.id});
    }
    await batch.commit();
    await _localStorage.limpiarClientesPendientes();
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