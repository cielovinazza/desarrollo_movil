import '../../domain/entities/cotizacion_model.dart';
import '../../domain/entities/mano_de_obra.dart';
import '../../../materiales/domain/entities/material.dart';
import '../../../cliente/domain/entities/cliente.dart';
import '../dtos/borrador_cotizacion_dto.dart';

class BorradorCotizacionMapper {
  static BorradorCotizacionDto toDto({
    required Cliente? cliente,
    required String clienteTexto,
    required String direccion,
    required String viatico,
    String viaticoDescripcion = '',
    required String utilidad,
    required String iva,
    required int currentStep,
    required List<ItemTrabajo> trabajos,
    required List<MaterialEntity> materiales,
    required List<ManoDeObra> manoObra,
  }) {
    return BorradorCotizacionDto(
      cliente: cliente == null
          ? null
          : {
              'id': cliente.id,
              'nombre': cliente.nombre,
              'rut': cliente.rut,
              'telefono': cliente.telefono,
              'correo': cliente.correo,
              'direccion': cliente.direccion,
            },
      clienteTexto: clienteTexto,
      direccion: direccion,
      viatico: viatico,
      viaticoDescripcion: viaticoDescripcion,
      utilidad: utilidad,
      iva: iva,
      currentStep: currentStep,
      trabajos: trabajos.map((t) {
        return {
          'tipo': t.tipo,
          'metrosCuadrados': t.metrosCuadrados,
          'precioPorMetro': t.precioPorMetro,
          'precioFijo': t.precioFijo,
          'esPrecioFijo': t.esPrecioFijo,
          'descripcionBreve': t.descripcionBreve,
        };
      }).toList(),
      materiales: materiales.map((m) {
        return {
          'nombre': m.nombre,
          'unidadMedida': m.unidadMedida,
          'cantidad': m.cantidad,
          'costoUnitario': m.costoUnitario,
        };
      }).toList(),
      manoObra: manoObra.map((m) {
        return {
          'cargo': m.cargo,
          'valorJornada': m.valorJornada,
          'dias': m.dias,
        };
      }).toList(),
    );
  }

  static List<ItemTrabajo> trabajosFromDto(BorradorCotizacionDto dto) {
    return dto.trabajos.map((t) {
      return ItemTrabajo(
        tipo: t['tipo'] ?? '',
        metrosCuadrados:
            (t['metrosCuadrados'] as num?)?.toDouble() ?? 0.0,
        precioPorMetro:
            (t['precioPorMetro'] as num?)?.toDouble() ?? 0.0,
        precioFijo: (t['precioFijo'] as num?)?.toDouble() ?? 0.0,
        esPrecioFijo: t['esPrecioFijo'] == true,
        descripcionBreve: t['descripcionBreve'] as String?,
      );
    }).toList();
  }

  static List<MaterialEntity> materialesFromDto(BorradorCotizacionDto dto) {
    return dto.materiales.map((m) {
      return MaterialEntity(
        nombre: m['nombre'] ?? '',
        unidadMedida: m['unidadMedida'] ?? '',
        cantidad: (m['cantidad'] as num?)?.toDouble() ?? 0.0,
        costoUnitario: (m['costoUnitario'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  static List<ManoDeObra> manoObraFromDto(BorradorCotizacionDto dto) {
    return dto.manoObra.map((m) {
      return ManoDeObra(
        cargo: m['cargo'] ?? '',
        valorJornada: (m['valorJornada'] as num?)?.toDouble() ?? 0.0,
        dias: (m['dias'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  static Cliente? clienteFromDto(BorradorCotizacionDto dto) {
    final data = dto.cliente;
    if (data == null) return null;

    return Cliente(
      id: data['id'],
      nombre: data['nombre'] ?? '',
      rut: data['rut'] ?? '',
      telefono: data['telefono'] ?? '',
      correo: data['correo'] ?? '',
      direccion: data['direccion'],
    );
  }
}