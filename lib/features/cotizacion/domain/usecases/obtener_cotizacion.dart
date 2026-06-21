import '../../data/dtos/cotizacion_dtos.dart';
import '../repositories/cotizacion_repository.dart';

class ObtenerCotizacion {
  final CotizacionRepository repository;

  ObtenerCotizacion(this.repository);

  Future<List<CotizacionDto>> call({
    String? idBusqueda,
    String? clienteNombre,
    String? clienteId,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    return await repository.obtenerCotizaciones(
      idBusqueda: idBusqueda,
      clienteNombre: clienteNombre,
      clienteId: clienteId,
      estado: estado,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
  }
}