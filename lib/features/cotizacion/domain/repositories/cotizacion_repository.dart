import 'dart:io';
import '../../data/dtos/cotizacion_dtos.dart';

abstract class CotizacionRepository {
  Future<CotizacionDto> guardarCotizacion(CotizacionDto dto);

  Future<List<CotizacionDto>> obtenerCotizaciones({
    String? idBusqueda,
    String? clienteNombre,
    String? clienteId,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  });

  Future<void> actualizarEstado(
    String id,
    String estadoActual,
    String estadoNuevo, {
    String? observacion,
  });

  Future<String> gestionarYSubirPdf({
    required String id,
    required String codigo,
    required File archivo,
  });

  Future<void> enviarCotizacionPorCorreo(
    CotizacionDto cotizacion, {
    String? observacion,
  });
}