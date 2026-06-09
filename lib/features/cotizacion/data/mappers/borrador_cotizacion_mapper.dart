import '../../../cliente/domain/entities/cliente.dart';
import '../../../materiales/domain/entities/material.dart';
import '../../domain/entities/cotizacion_model.dart';
import '../../domain/entities/mano_de_obra.dart';
import '../dtos/borrador_cotizacion_dto.dart';

class BorradorCotizacionMapper {
  static BorradorCotizacionDto toDto({
    required Cliente? cliente,
    required String clienteTexto,
    required String direccion,
    required String viatico,
    required String utilidad,
    required String iva,
    required int currentStep,
    required List<ItemTrabajo> trabajos,
    required List<MaterialEntity> materiales,
    required List<ManoDeObra> manoObra,
  }) {
    return BorradorCotizacionDto(
      cliente: cliente?.toJson(),
      clienteTexto: clienteTexto,
      direccion: direccion,
      viatico: viatico,
      utilidad: utilidad,
      iva: iva,
      currentStep: currentStep,
      trabajos: trabajos.map((t) => {
        'tipo': t.tipo,
        'metrosCuadrados': t.metrosCuadrados,
        'precioPorMetro': t.precioPorMetro,
        'descripcionBreve': t.descripcionBreve,
      }).toList(),
      materiales: materiales.map((m) => {
        'nombre': m.nombre,
        'unidadMedida': m.unidadMedida,
        'costoUnitario': m.costoUnitario,
        'cantidad': m.cantidad,
      }).toList(),
      manoObra: manoObra.map((mo) => {
        'cargo': mo.cargo,
        'valorJornada': mo.valorJornada,
        'dias': mo.dias,
      }).toList(),
    );
  }

  static Cliente? clienteFromDto(BorradorCotizacionDto dto) {
    if (dto.cliente == null) return null;
    return Cliente.fromJson(dto.cliente!);
  }

  static List<ItemTrabajo> trabajosFromDto(BorradorCotizacionDto dto) {
    return dto.trabajos.map((t) => ItemTrabajo(
      tipo: t['tipo'],
      metrosCuadrados: (t['metrosCuadrados'] as num).toDouble(),
      precioPorMetro: (t['precioPorMetro'] as num).toDouble(),
      descripcionBreve: t['descripcionBreve'],
    )).toList();
  }

  static List<MaterialEntity> materialesFromDto(BorradorCotizacionDto dto) {
    return dto.materiales.map((m) => MaterialEntity(
      nombre: m['nombre'],
      unidadMedida: m['unidadMedida'],
      costoUnitario: (m['costoUnitario'] as num).toDouble(),
      cantidad: (m['cantidad'] as num).toDouble(),
    )).toList();
  }

  static List<ManoDeObra> manoObraFromDto(BorradorCotizacionDto dto) {
    return dto.manoObra.map((mo) => ManoDeObra(
      cargo: mo['cargo'],
      valorJornada: (mo['valorJornada'] as num).toDouble(),
      dias: mo['dias'],
    )).toList();
  }
}