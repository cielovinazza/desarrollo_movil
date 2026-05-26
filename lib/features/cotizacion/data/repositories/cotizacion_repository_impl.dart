import 'dart:io';
import '../../domain/repositories/cotizacion_repository.dart';
import '../datasources/cotizacion_firebase_datasource.dart';
import '../dtos/cotizacion_dtos.dart';

// Mapeo local de la Máquina de Estados para no modificar drásticamente el flujo actual
class FlujoEstados {
  static const String enProceso = 'En Proceso';
  static const String listaParaEnvio = 'Lista para Envío';
  static const String enviada = 'Enviada';
  static const String aprobada = 'Aprobada por el Cliente';
  static const String rechazada = 'Rechazada por el Cliente';

  static bool validarTransicion(String actual, String nueva) {
    if (actual == 'Pendiente') return true; // Permite inicializar estados viejos de tu mapper
    
    switch (actual) {
      case enProceso:
        return nueva == listaParaEnvio;
      case listaParaEnvio:
        return nueva == enviada;
      case enviada:
        return nueva == aprobada || nueva == rechazada;
      case aprobada:
      case rechazada:
        return false; // Estados de cierre, bloqueados
      default:
        return false;
    }
  }
}

class CotizacionRepositoryImpl implements CotizacionRepository {
  final CotizacionFirestoreDataSource datasource;

  CotizacionRepositoryImpl(this.datasource);

  @override
  Future<void> guardarCotizacion(CotizacionDto dto) async {
    // Al crearse por primera vez, forzamos que inicie estrictamente "En Proceso"
    final dtoInicial = dto.copyWith(estado: FlujoEstados.enProceso);
    await datasource.guardarCotizacion(dtoInicial);
  }

  @override
  Future<List<CotizacionDto>> obtenerCotizaciones({
    String? idBusqueda,
    String? clienteNombre,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    return await datasource.obtenerCotizacion(
      idBusqueda: idBusqueda,
      clienteNombre: clienteNombre,
      estado: estado,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
  }

  @override
  Future<void> actualizarEstado(String id, String estadoActual, String estadoNuevo) async {
    // Validamos estrictamente el flujo de estados antes de mandar la petición de actualización
    if (!FlujoEstados.validarTransicion(estadoActual, estadoNuevo)) {
      throw Exception('Transición inválida: No se puede cambiar de "$estadoActual" a "$estadoNuevo"');
    }
    await datasource.actualizarEstado(id, estadoNuevo);
  }

  @override
  Future<String> gestionarYSubirPdf(String id, File archivo) async {
    final urlDescarga = await datasource.subirPdfCotizacion(id, archivo);
    await datasource.vincularPdfACotizacion(id, urlDescarga);
    return urlDescarga;
  }
  
  Future<void> crearNuevaVersion(String cotizacionId) async {
    await datasource.crearNuevaVersion(cotizacionId);
  }
}