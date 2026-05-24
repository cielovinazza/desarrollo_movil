import '../../domain/entities/cotizacion_model.dart';
import '../../presentation/widgets/materiales.dart';
import '../dtos/cotizacion_dtos.dart';

class CotizacionMapper {
  static CotizacionDto toDto({
    required CotizacionModel cotizacion,
    required List<MaterialEntity> materiales,
    required String clienteId,
    required String usuarioId,
  }) {
    return CotizacionDto(
      id: '',
      clienteId: clienteId,
      clienteNombre: cotizacion.cliente,
      codigo: '',
      direccion: cotizacion.direccionObra,
      trabajos: cotizacion.listaTrabajos.map((trabajo) {
        return {
          'tipo': trabajo.tipo,
          'metrosCuadrados': trabajo.metrosCuadrados.toDouble(),
          'precioPorMetro': trabajo.precioPorMetro.toDouble(),
          'subtotal': trabajo.subtotal.toDouble(),
        };
      }).toList(),
      manoObra: cotizacion.listaManoObra.map((mano) {
        return {
          'cargo': mano.cargo,
          'valorJornada': mano.valorJornada.toDouble(),
          'dias': mano.dias.toDouble(),
          'subtotal': mano.subtotal.toDouble(),
        };
      }).toList(),
      materiales: materiales.map((material) {
        return {
          'nombre': material.nombre,
          'unidadMedida': material.unidadMedida,
          'cantidad': material.cantidad.toDouble(),
          'costoUnitario': material.costoUnitario.toDouble(),
          'subtotal': material.subtotal.toDouble(),
        };
      }).toList(),
      subtotalObra: cotizacion.subtotalObraTotal.toDouble(),
      subtotalMateriales: cotizacion.subtotalMateriales.toDouble(),
      subtotalManoObra: cotizacion.subtotalManoObraTotal.toDouble(),
      viatico: (cotizacion.viatico ?? 0).toDouble(),
      porcentajeUtilidad: cotizacion.porcentajeUtilidad.toDouble(),
      porcentajeIva: cotizacion.porcentajeIva.toDouble(),
      totalFinal: cotizacion.calcularTotalFinal().toDouble(),
      estado: 'En Proceso',
      usuarioId: usuarioId,
    );
  }
}