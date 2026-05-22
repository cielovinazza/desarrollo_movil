import 'package:cloud_firestore/cloud_firestore.dart';

class CotizacionDto {

  final String id;

  final String clienteId;
  final String clienteNombre;
  final String direccion;
  final String codigo;
  final List<dynamic> trabajos;
  final List<dynamic> manoObra;
  final List<dynamic> materiales;

  final double subtotalObra;
  final double subtotalMateriales;
  final double subtotalManoObra;

  final double viatico;
  final double porcentajeUtilidad;
  final double porcentajeIva;
  final double totalFinal;

  final String estado;
  final String usuarioId;

  final Timestamp? fechaCreacion;

  CotizacionDto({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.codigo,
    required this.direccion,
    required this.trabajos,
    required this.manoObra,
    required this.materiales,
    required this.subtotalObra,
    required this.subtotalMateriales,
    required this.subtotalManoObra,
    required this.viatico,
    required this.porcentajeUtilidad,
    required this.porcentajeIva,
    required this.totalFinal,
    required this.estado,
    required this.usuarioId,
    this.fechaCreacion,
  });

  Map<String, dynamic> toMap() {

    return {

      'clienteId': clienteId,

      'clienteNombre': clienteNombre,

      'codigo': codigo,

      'direccion': direccion,

      'trabajos': trabajos,

      'manoObra': manoObra,

      'materiales': materiales,

      'subtotalObra': subtotalObra,

      'subtotalMateriales': subtotalMateriales,

      'subtotalManoObra': subtotalManoObra,

      'viatico': viatico,

      'porcentajeUtilidad': porcentajeUtilidad,

      'porcentajeIva': porcentajeIva,

      'totalFinal': totalFinal,

      'estado': estado,

      'usuarioId': usuarioId,

      'fechaCreacion':
          fechaCreacion ??
          FieldValue.serverTimestamp(),
    };
  }

  factory CotizacionDto.fromMap(
    String id,
    Map<String, dynamic> map,
    
  ) {

    return CotizacionDto(

      id: id,

      clienteId:
          map['clienteId'] ?? '',

      clienteNombre:
          map['clienteNombre'] ?? '',
      codigo:
          map['codigo'] ?? '',

      direccion:
          map['direccion'] ?? '',

      trabajos:
          map['trabajos'] ?? [],

      manoObra:
          map['manoObra'] ?? [],

      materiales:
          map['materiales'] ?? [],

      subtotalObra:
          (map['subtotalObra'] as num?)
              ?.toDouble() ?? 0.0,

      subtotalMateriales:
          (map['subtotalMateriales'] as num?)
              ?.toDouble() ?? 0.0,

      subtotalManoObra:
          (map['subtotalManoObra'] as num?)
              ?.toDouble() ?? 0.0,

      viatico:
          (map['viatico'] as num?)
              ?.toDouble() ?? 0.0,

      porcentajeUtilidad:
          (map['porcentajeUtilidad'] as num?)
              ?.toDouble() ?? 0.0,

      porcentajeIva:
          (map['porcentajeIva'] as num?)
              ?.toDouble() ?? 0.0,

      totalFinal:
          (map['totalFinal'] as num?)
              ?.toDouble() ?? 0.0,

      estado:
          map['estado'] ?? '',

      usuarioId:
          map['usuarioId'] ?? '',

      fechaCreacion:
          map['fechaCreacion'],
    );
  }

  CotizacionDto copyWith({
  String? codigo,
  String? estado,
}) {

  return CotizacionDto(
    id: id,
    clienteId: clienteId,
    clienteNombre: clienteNombre,
    codigo: codigo ?? this.codigo,
    direccion: direccion,
    trabajos: trabajos,
    manoObra: manoObra,
    materiales: materiales,
    subtotalObra: subtotalObra,
    subtotalMateriales: subtotalMateriales,
    subtotalManoObra: subtotalManoObra,
    viatico: viatico,
    porcentajeUtilidad: porcentajeUtilidad,
    porcentajeIva: porcentajeIva,
    totalFinal: totalFinal,
    usuarioId: usuarioId,
    estado: estado ?? this.estado,
    fechaCreacion: fechaCreacion,
  );
}
}