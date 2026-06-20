import '../../data/dtos/cotizacion_dtos.dart';
import '../repositories/cotizacion_repository.dart';

class GuardarCotizacion {
  final CotizacionRepository repository;
  GuardarCotizacion(this.repository);

  Future<CotizacionDto> call(CotizacionDto dto) {
    return repository.guardarCotizacion(dto);
  }
}
