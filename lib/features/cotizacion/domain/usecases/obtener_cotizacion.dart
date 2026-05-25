import '../../data/dtos/cotizacion_dtos.dart';

import '../repositories/cotizacion_repository.dart';

class ObtenerCotizacion {

  final CotizacionRepository repository;

  ObtenerCotizacion(
    this.repository,
  );

  Future<List<CotizacionDto>> call() async {

    return await repository
        .obtenerCotizaciones();
  }
}