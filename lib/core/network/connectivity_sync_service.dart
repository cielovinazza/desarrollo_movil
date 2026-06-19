import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../storage/local_storage.dart';
import '../../features/cotizacion/data/dtos/cotizacion_dtos.dart';
import '../../features/cotizacion/data/datasources/cotizacion_firebase_datasource.dart';

class ConnectivitySyncService {
  final LocalStorage _localStorage;
  final FirebaseFirestore _firestore;
  late final CotizacionFirestoreDataSource datasource;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivitySyncService({
    LocalStorage? localStorage,
    FirebaseFirestore? firestore,
  })  : _localStorage = localStorage ?? LocalStorage(),
        _firestore = firestore ?? FirebaseFirestore.instance {
    datasource = CotizacionFirestoreDataSource(_firestore);
  }

  void iniciar() {
    _subscription =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
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
            .collection('clientes') // corregido: plural
            .where('rut', isEqualTo: rut)
            .limit(1)
            .get(const GetOptions(source: Source.server));

        if (querySnapshot.docs.isNotEmpty) {
          await _reasociarCotizaciones(
              rutDuplicado: rut, idClienteOriginal: rut);
          continue;
        }
        await _firestore.collection('clientes').doc(rut).set({
          'id': rut,
          'nombre': cliente['nombre']?.toString() ?? 'Sin Nombre',
          'rut': rut,
          'correo': cliente['correo']?.toString() ?? '',
          'telefono': cliente['telefono']?.toString() ?? '',
          'direccion': cliente['direccion']?.toString() ?? '',
        });

        await _reasociarCotizaciones(
            rutDuplicado: rut, idClienteOriginal: rut);
      } catch (e) {
        if (e is FirebaseException &&
            (e.code == 'permission-denied' || e.code == 'already-exists')) {
          await _reasociarCotizaciones(
              rutDuplicado: rut, idClienteOriginal: rut);
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

    for (final raw in pendientes) {
      try {
        final dto = CotizacionDto.fromMap(raw['id'] ?? '', raw);

        // Forzar id vacío para que datasource genere uno nuevo
        final dtoNuevo = dto.copyWith(id: '');

        final resultado = await datasource.guardarCotizacion(dtoNuevo);

        // Manejo de PDF pendiente
        if (raw['pdfPendiente'] == true && raw['pdfLocalPath'] != null) {
          final archivoPdf = File(raw['pdfLocalPath']);
          final pdfUrl = await datasource.subirPdfCotizacion(
              resultado['codigo']!, archivoPdf);
          await datasource.vincularPdfACotizacion(resultado['id']!, pdfUrl);
        }
      } catch (e) {
        // Si falla, volver a guardar en local
        await _localStorage.guardarCotizacionPendiente(raw);
      }
    }

    await _localStorage.limpiarCotizacionesPendientes();
  }
}
