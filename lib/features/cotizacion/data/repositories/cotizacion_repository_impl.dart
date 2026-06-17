import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/cotizacion_repository.dart';
import '../datasources/cotizacion_firebase_datasource.dart';
import '../dtos/cotizacion_dtos.dart';

class FlujoEstados {
  static const String enProceso = 'En Proceso';
  static const String listaParaEnvio = 'Lista para Envío';
  static const String enviada = 'Enviada';
  static const String aprobada = 'Aprobada por el Cliente';
  static const String rechazada = 'Rechazada por el Cliente';
  static bool validarTransicion(String actual, String nueva) {
    if (actual == 'Pendiente') return true;

    switch (actual) {
      case enProceso:
        return nueva == listaParaEnvio;
      case listaParaEnvio:
        return nueva == enviada;
      case enviada:
        return nueva == aprobada || nueva == rechazada;
      case aprobada:
      case rechazada:
        return false;
      default:
        return false;
    }
  }
}

class CotizacionRepositoryImpl implements CotizacionRepository {
  final CotizacionFirestoreDataSource datasource;

  CotizacionRepositoryImpl(this.datasource);

  @override
  Future<String> guardarCotizacion(CotizacionDto dto) async {
    final estadoFinal = dto.estado.trim().isEmpty
        ? FlujoEstados.enProceso
        : dto.estado;
    final dtoInicial = dto.copyWith(estado: estadoFinal);
    return await datasource.guardarCotizacion(dtoInicial);
  }

  @override
  Future<List<CotizacionDto>> obtenerCotizaciones({
    String? idBusqueda,
    String? clienteNombre,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    return await datasource.obtenerCotizacion(
      idBusqueda: idBusqueda,
      clienteNombre: clienteNombre,
      estado: estado,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
  }

  @override
  Future<void> actualizarEstado(
    String id,
    String estadoActual,
    String estadoNuevo, {
    String? observacion,
  }) async {
    if (!FlujoEstados.validarTransicion(estadoActual, estadoNuevo)) {
      throw Exception(
        'Transición inválida: No se puede cambiar de "$estadoActual" a "$estadoNuevo"',
      );
    }

    await datasource.actualizarEstado(
      id,
      estadoNuevo,
      observacion: observacion,
    );
  }

  @override
  Future<String> gestionarYSubirPdf({
    required String id,
    required String codigo,
    required File archivo,
  }) async {
    final carpetaDestino = codigo.trim().isEmpty ? id : codigo;
    final urlDescarga = await datasource.subirPdfCotizacion(
      carpetaDestino,
      archivo,
    );

    await datasource.vincularPdfACotizacion(id, urlDescarga);

    return urlDescarga;
  }

  Future<void> crearNuevaVersion(String cotizacionId) async {
    await datasource.crearNuevaVersion(cotizacionId);
  }

@override
Future<void> enviarCotizacionPorCorreo(CotizacionDto cotizacion) async {
  if (cotizacion.pdfUrl == null || cotizacion.pdfUrl!.isEmpty) {
    throw Exception(
      'No se puede enviar la cotización sin un documento PDF vinculado.',
    );
  }

  String emailActualizado = cotizacion.clienteEmail;
  String nombreActualizado = cotizacion.clienteNombre;

  if (cotizacion.clienteId.isNotEmpty) {
    final clienteDoc = await FirebaseFirestore.instance
        .collection('clientes')
        .doc(cotizacion.clienteId)
        .get();

    if (clienteDoc.exists) {
      final data = clienteDoc.data();
      emailActualizado = data?['correo'] ?? cotizacion.clienteEmail;
      nombreActualizado = data?['nombre'] ?? cotizacion.clienteNombre;
    }
  }

  if (emailActualizado.isEmpty) {
    throw Exception('El cliente no tiene un correo electrónico asignado.');
  }
  final String correoDocId = await datasource.enviarCorreoTriggerEmail(
    clienteEmail: emailActualizado,
    clienteNombre: nombreActualizado,
    direccion: cotizacion.direccion,
    asunto: 'Cotización N°${cotizacion.codigo}',
    pdfUrl: cotizacion.pdfUrl!,
    codigo: cotizacion.codigo,
  );
  await actualizarEstado(
    cotizacion.id,
    cotizacion.estado,
    FlujoEstados.enviada,
  );
  FirebaseFirestore.instance
      .collection('historial_correos')
      .doc(correoDocId)
      .snapshots()
      .listen((snapshot) async {
        if (snapshot.exists) {
          final data = snapshot.data();
          final delivery = data?['delivery'] as Map<String, dynamic>?;

          if (delivery != null) {
            final String estadoEnvio = delivery['state'] ?? '';
            if (estadoEnvio == 'ERROR') {
              print('¡El correo falló o rebotó! Revirtiendo estado de la cotización...');
              
              await actualizarEstado(
                cotizacion.id,
                FlujoEstados.enviada,
                FlujoEstados.listaParaEnvio, 
              );
            }
          }
        }
      });
}
}
