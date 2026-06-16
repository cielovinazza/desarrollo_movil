import '../repositories/cotizacion_repository.dart';

class ActualizarEstadoCotizacion {
  final CotizacionRepository repository;

  ActualizarEstadoCotizacion(this.repository);

  Future<void> call(
    String id,
    String estadoActual,
    String estadoNuevo, {
    String? observacion,
  }) async {
    await repository.actualizarEstado(
      id,
      estadoActual,
      estadoNuevo,
      observacion: observacion,
    );
  }
}
