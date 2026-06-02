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
    final cliente=cotizacion.cliente;

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
      subtotalObra: cotizacion.subtotalObraTotal.toDouble(),
      subtotalMateriales: cotizacion.subtotalMateriales.toDouble(),
      subtotalManoObra: cotizacion.subtotalManoObraTotal.toDouble(),
      viatico: (cotizacion.viatico ?? 0).toDouble(),
      porcentajeUtilidad: cotizacion.porcentajeUtilidad.toDouble(),
      porcentajeIva: cotizacion.porcentajeIva.toDouble(),
      totalFinal: cotizacion.calcularTotalFinal().toDouble(),
      estado: estado,
    );
  }

  static CotizacionModel fromDto(CotizacionDto dto) {
  final trabajos = dto.trabajos.map<ItemTrabajo>((e) {
    return ItemTrabajo(
      tipo: e['tipo'] ?? '',
      metrosCuadrados: (e['metrosCuadrados'] as num).toDouble(),
      precioPorMetro: (e['precioPorMetro'] as num).toDouble(),
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
    porcentajeUtilidad: dto.porcentajeUtilidad,
    porcentajeIva: dto.porcentajeIva,
  );
}
}