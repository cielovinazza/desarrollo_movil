import 'dart:io';
import '../../data/dtos/cotizacion_dtos.dart';

abstract class CotizacionRepository {
  Future<void> guardarCotizacion(CotizacionDto dto);
  
  Future<List<CotizacionDto>> obtenerCotizaciones({
    String? idBusqueda,
    String? nombreCliente,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  });

  Future<void> actualizarEstado(String id, String estadoActual, String estadoNuevo);

  Future<String> gestionarYSubirPdf(String id, File archivo);
}