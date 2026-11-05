
import '../../domain/entities/cotizacion_model.dart';
import '../../presentation/widgets/materiales.dart';
import '../dtos/cotizacion_dtos.dart';
import '../../../cliente/domain/entities/cliente.dart';
import '../../domain/entities/mano_de_obra.dart';

class CotizacionMapper {
  static CotizacionDto toDto({
    required CotizacionModel cotizacion,
    required List<MaterialEntity> materiales,
    required String usuarioId,
    required String estado,
  }) {
    final cliente = cotizacion.cliente;
    final isoNow = DateTime.now().toUtc().toIso8601String();

    return CotizacionDto(
      id: '',
      clienteId: cliente.id ?? '',
      clienteNombre: cliente.nombre,
      clienteRut: cliente.rut,
      clienteTelefono: cliente.telefono,
      clienteEmail: cliente.correo,
      clienteDireccion: cliente.direccion ?? '',
      usuarioId: usuarioId,
      codigo: '',
      direccion: cotizacion.direccionObra,
      trabajos: cotizacion.listaTrabajos.map((trabajo) {
        return {
          'tipo': trabajo.tipo,
          'metrosCuadrados': trabajo.metrosCuadrados,
          'precioPorMetro': trabajo.precioPorMetro,
          'precioFijo': trabajo.precioFijo,
          'esPrecioFijo': trabajo.esPrecioFijo,
          'subtotal': trabajo.subtotal,
          'descripcionBreve': trabajo.descripcionBreve,
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
      version: 1,
      materiales: materiales.map((material) {
        return {
          'nombre': material.nombre,
          'unidadMedida': material.unidadMedida,
          'cantidad': material.cantidad.toDouble(),
          'costoUnitario': material.costoUnitario.toDouble(),
          'subtotal': material.subtotal.toDouble(),
        };
      }).toList(),
      subtotalObra: cotizacion.subtotalObraTotal,
      subtotalMateriales: cotizacion.subtotalMateriales,
      subtotalManoObra: cotizacion.subtotalManoObraTotal,
      viatico: (cotizacion.viatico ?? 0).toDouble(),
      viaticoDescripcion: cotizacion.viaticoDescripcion,
      porcentajeUtilidad: cotizacion.porcentajeUtilidad,
      porcentajeIva: cotizacion.porcentajeIva,
      totalFinal: cotizacion.calcularTotalFinal(),
      estado: estado,
      fechaCreacion: isoNow,
      fechaEdicion: isoNow,
    );
  }

  static CotizacionModel fromDto(CotizacionDto dto) {
    final trabajos = dto.trabajos.map<ItemTrabajo>((e) {
      return ItemTrabajo(
        tipo: e['tipo'] ?? '',
        metrosCuadrados:
            (e['metrosCuadrados'] as num?)?.toDouble() ?? 0.0,
        precioPorMetro:
            (e['precioPorMetro'] as num?)?.toDouble() ?? 0.0,
        precioFijo: (e['precioFijo'] as num?)?.toDouble() ?? 0.0,
        esPrecioFijo: e['esPrecioFijo'] == true,
        descripcionBreve: e['descripcionBreve'] as String?,
      );
    }).toList();

    final materiales = dto.materiales.map<MaterialEntity>((e) {
      return MaterialEntity(
        nombre: e['nombre'] ?? '',
        unidadMedida: e['unidadMedida'] ?? '',
        cantidad: (e['cantidad'] as num).toDouble(),
        costoUnitario: (e['costoUnitario'] as num).toDouble(),
      );
    }).toList();

    final manoObra = dto.manoObra.map<ManoDeObra>((e) {
      return ManoDeObra(
        cargo: e['cargo'] ?? '',
        valorJornada: (e['valorJornada'] as num).toDouble(),
        dias: (e['dias'] as num).toInt(),
      );
    }).toList();

    return CotizacionModel(
      cliente: Cliente(
        id: dto.clienteId,
        nombre: dto.clienteNombre,
        rut: dto.clienteRut,
        correo: dto.clienteEmail,
        telefono: dto.clienteTelefono,
        direccion: dto.clienteDireccion,
      ),
      direccionObra: dto.direccion,
      listaTrabajos: trabajos,
      materiales: materiales,
      listaManoObra: manoObra,
      viatico: dto.viatico,
      viaticoDescripcion: dto.viaticoDescripcion,
      porcentajeUtilidad: dto.porcentajeUtilidad,
      porcentajeIva: dto.porcentajeIva,
      fechaCreacion: dto.fechaCreacion != null
          ? DateTime.parse(dto.fechaCreacion!)
          : null,
      fechaEdicion: dto.fechaEdicion != null
          ? DateTime.parse(dto.fechaEdicion!)
          : null,
    );
  }

  static List<ItemTrabajo> trabajosDesdeDto(List<dynamic> trabajos) {
    return trabajos.map((item) {
      if (item is ItemTrabajo) return item;

      final map = item as Map<String, dynamic>;

      return ItemTrabajo(
        tipo: map['tipo'] ?? '',
        metrosCuadrados:
            (map['metrosCuadrados'] as num?)?.toDouble() ?? 0.0,
        precioPorMetro:
            (map['precioPorMetro'] as num?)?.toDouble() ?? 0.0,
        precioFijo: (map['precioFijo'] as num?)?.toDouble() ?? 0.0,
        esPrecioFijo: map['esPrecioFijo'] == true,
        descripcionBreve: map['descripcionBreve'] as String?,
      );
    }).toList();
  }

  static List<ManoDeObra> manoObraDesdeDto(List<dynamic> manoObra) {
    return manoObra.map((item) {
      if (item is ManoDeObra) return item;

      final map = item as Map<String, dynamic>;

      return ManoDeObra(
        cargo: map['cargo'] ?? map['detalle'] ?? '',
        dias: (map['dias'] ?? 0).toInt(),
        valorJornada:
            (map['valorJornada'] ?? map['costo'] ?? 0).toDouble(),
      );
    }).toList();
  }

  static List<MaterialEntity> materialesDesdeDto(List<dynamic> materiales) {
    return materiales.map((item) {
      if (item is MaterialEntity) return item;

      final map = item as Map<String, dynamic>;

      return MaterialEntity(
        nombre: map['nombre'] ?? '',
        cantidad: (map['cantidad'] ?? 0).toDouble(),
        costoUnitario:
            (map['costoUnitario'] ?? map['precioUnitario'] ?? 0).toDouble(),
        unidadMedida: map['unidadMedida'] ?? '',
      );
    }).toList();
  }
}
