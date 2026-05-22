import '../../data/dtos/cotizacion_dtos.dart';
import '../repositories/cotizacion_repository.dart';

class GuardarCotizacion {

  final CotizacionRepository repository;

  GuardarCotizacion(
    this.repository,
  );

  Future<void> call(
    CotizacionDto dto,
  ) async {

    await repository.guardarCotizacion(dto);
  }
}