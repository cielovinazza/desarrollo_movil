import '../../data/dtos/cotizacion_dtos.dart';

abstract class CotizacionRepository {

  Future<void> guardarCotizacion(
    CotizacionDto dto,
  );
  Future<List<CotizacionDto>> obtenerCotizaciones();
}