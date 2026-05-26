import 'package:cloud_firestore/cloud_firestore.dart';

class CotizacionDto {
  final String id;
  final String clienteId;
  final String clienteNombre;
  final String clienteEmail;
  final String clienteRut;
  final String clienteDireccion; 
  final String clienteTelefono;
  final String? pdfUrl;
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
  final int version;

  CotizacionDto({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteEmail,
    required this.clienteRut,
    required this.clienteTelefono,
    this.pdfUrl,
    required this.clienteDireccion,
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
    required this.version,
  });

  Map<String, dynamic> toMap() {
    return {
      'clienteId': clienteId,
      'clienteNombre': clienteNombre,
      'clienteEmail': clienteEmail,
      'clienteRut': clienteRut,
      'clienteTelefono': clienteTelefono,
      'pdfUrl': pdfUrl,
      'clienteDireccion': clienteDireccion,
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
      'fechaCreacion': fechaCreacion ?? FieldValue.serverTimestamp(),
      'version': version,
    };
  }

  factory CotizacionDto.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return CotizacionDto(
      id: id,
      clienteId: map['clienteId'] ?? '',
      clienteNombre: map['clienteNombre'] ?? '',
      clienteEmail: map['clienteEmail'] ?? '',
      clienteRut: map['clienteRut'] ?? '',
      clienteTelefono: map['clienteTelefono'] ?? '',
      clienteDireccion: map['clienteDireccion'] ?? '',
      pdfUrl: map['pdfUrl'],
      codigo: map['codigo'] ?? '',
      direccion: map['direccion'] ?? '',
      trabajos: map['trabajos'] ?? [],
      manoObra: map['manoObra'] ?? [],
      materiales: map['materiales'] ?? [],
      subtotalObra: (map['subtotalObra'] as num?)?.toDouble() ?? 0.0,
      subtotalMateriales: (map['subtotalMateriales'] as num?)?.toDouble() ?? 0.0,
      subtotalManoObra: (map['subtotalManoObra'] as num?)?.toDouble() ?? 0.0,
      viatico: (map['viatico'] as num?)?.toDouble() ?? 0.0,
      porcentajeUtilidad: (map['porcentajeUtilidad'] as num?)?.toDouble() ?? 0.0,
      porcentajeIva: (map['porcentajeIva'] as num?)?.toDouble() ?? 0.0,
      totalFinal: (map['totalFinal'] as num?)?.toDouble() ?? 0.0,
      estado: map['estado'] ?? '',
      usuarioId: map['usuarioId'] ?? '',
      fechaCreacion: map['fechaCreacion'] as Timestamp?,
      version: (map['version'] as int?) ?? 1,
    );
  }

  // metodo ampliado necesario para modificar campos en un futuro,
  CotizacionDto copyWith({
    String? id,
    String? clienteId,
    String? clienteNombre,
    String? clienteEmail,
    String? clienteRut,
    String? clienteDireccion,
    String? clienteTelefono,
    String? pdfUrl,
    String? direccion,
    String? codigo,
    List<dynamic>? trabajos,
    List<dynamic>? manoObra,
    List<dynamic>? materiales,
    double? subtotalObra,
    double? subtotalMateriales,
    double? subtotalManoObra,
    double? viatico,
    double? porcentajeUtilidad,
    double? porcentajeIva,
    double? totalFinal,
    String? estado,
    String? usuarioId,
    Timestamp? fechaCreacion,
    int? version,
  }) {
    return CotizacionDto(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteEmail: clienteEmail ?? this.clienteEmail,
      clienteRut: clienteRut ?? this.clienteRut,
      clienteDireccion: clienteDireccion ?? this.clienteDireccion,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      direccion: direccion ?? this.direccion,
      codigo: codigo ?? this.codigo,
      trabajos: trabajos ?? this.trabajos,
      manoObra: manoObra ?? this.manoObra,
      materiales: materiales ?? this.materiales,
      subtotalObra: subtotalObra ?? this.subtotalObra,
      subtotalMateriales: subtotalMateriales ?? this.subtotalMateriales,
      subtotalManoObra: subtotalManoObra ?? this.subtotalManoObra,
      viatico: viatico ?? this.viatico,
      porcentajeUtilidad: porcentajeUtilidad ?? this.porcentajeUtilidad,
      porcentajeIva: porcentajeIva ?? this.porcentajeIva,
      totalFinal: totalFinal ?? this.totalFinal,
      estado: estado ?? this.estado,
      usuarioId: usuarioId ?? this.usuarioId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      version: version ?? this.version,
    );
  }
}