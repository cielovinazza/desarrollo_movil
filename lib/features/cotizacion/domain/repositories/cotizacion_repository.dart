import 'dart:io';
import '../../data/dtos/cotizacion_dtos.dart';

abstract class CotizacionRepository {
  Future<void> guardarCotizacion(CotizacionDto dto);
  
  Future<List<CotizacionDto>> obtenerCotizaciones({
    String? idBusqueda,
    String? clienteNombre,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  });

  Future<void> actualizarEstado(String id, String estadoActual, String estadoNuevo);

  Future<String> gestionarYSubirPdf({
    required String id,
    required String codigo,
    required File archivo,
  });

  Future<void> enviarCotizacionPorCorreo(CotizacionDto cotizacion);


}