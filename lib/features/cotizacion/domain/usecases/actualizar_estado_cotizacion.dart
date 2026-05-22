import '../../data/repositories/cotizacion_repository_impl.dart';

class ActualizarEstadoCotizacion {

  final CotizacionRepositoryImpl repository;

  ActualizarEstadoCotizacion(
    this.repository,
  );

  Future<void> call(
    String id,
    String estado,
  ) async {

    await repository.actualizarEstado(
      id,
      estado,
    );
  }
}