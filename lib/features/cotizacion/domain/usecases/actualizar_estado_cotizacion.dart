import '../repositories/cotizacion_repository.dart';

class ActualizarEstadoCotizacion {
  final CotizacionRepository repository;

  ActualizarEstadoCotizacion(this.repository);

  //call recibe los 3 parámetros para que se conecte sin chocar con el repositorio actualizado
  Future<void> call(String id, String estadoActual, String estadoNuevo) async {
    await repository.actualizarEstado(id, estadoActual, estadoNuevo);
  }
}