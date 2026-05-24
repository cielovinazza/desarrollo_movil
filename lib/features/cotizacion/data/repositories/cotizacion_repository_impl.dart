import '../../domain/repositories/cotizacion_repository.dart';
import '../datasources/cotizacion_firebase_datasource.dart';
import '../dtos/cotizacion_dtos.dart';

class CotizacionRepositoryImpl
    implements CotizacionRepository {

  final CotizacionFirestoreDataSource datasource;

  CotizacionRepositoryImpl(
    this.datasource,
  );

  @override
  Future<void> guardarCotizacion(
    CotizacionDto dto,
  ) async {

    await datasource.guardarCotizacion(dto);
  }

  @override
  Future<List<CotizacionDto>>
  obtenerCotizaciones() async {

  return await datasource.obtenerCotizacion();
}

  Future<void> actualizarEstado(
  String id,
  String estado,
) async {

  await datasource.actualizarEstado(
    id,
    estado,
  );
}
Future<void> crearNuevaVersion(String cotizacionId) async {
  await datasource.crearNuevaVersion(cotizacionId);
}
}