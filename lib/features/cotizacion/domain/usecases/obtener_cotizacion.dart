import '../../data/dtos/cotizacion_dtos.dart';
import '../repositories/cotizacion_repository.dart';

class ObtenerCotizacion {
  final CotizacionRepository repository;

  ObtenerCotizacion(this.repository);

  // Definimos los parámetros nombrados opcionales para que la UI pueda filtrar
  Future<List<CotizacionDto>> call({
    String? idBusqueda,
    String? nombreCliente,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    return await repository.obtenerCotizaciones(
      idBusqueda: idBusqueda,
      nombreCliente: nombreCliente,
      estado: estado,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
  }
}