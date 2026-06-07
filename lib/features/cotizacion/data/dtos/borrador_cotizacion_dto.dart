
class BorradorCotizacionDto {
  final Map<String, dynamic>? cliente;
  final String clienteTexto;
  final String direccion;
  final String viatico;
  final String utilidad;
  final String iva;
  final int currentStep;
  final List<Map<String, dynamic>> trabajos;
  final List<Map<String, dynamic>> materiales;
  final List<Map<String, dynamic>> manoObra;

  BorradorCotizacionDto({
    required this.cliente,
    required this.clienteTexto,
    required this.direccion,
    required this.viatico,
    required this.utilidad,
    required this.iva,
    required this.currentStep,
    required this.trabajos,
    required this.materiales,
    required this.manoObra,
  });

  Map<String, dynamic> toJson() {
    return {
      'cliente': cliente,
      'clienteTexto': clienteTexto,
      'direccion': direccion,
      'viatico': viatico,
      'utilidad': utilidad,
      'iva': iva,
      'currentStep': currentStep,
      'trabajos': trabajos,
      'materiales': materiales,
      'manoObra': manoObra,
    };
  }

  factory BorradorCotizacionDto.fromJson(Map<String, dynamic> json) {
    return BorradorCotizacionDto(
      cliente: json['cliente'] != null
          ? Map<String, dynamic>.from(json['cliente'])
          : null,
      clienteTexto: json['clienteTexto'] ?? '',
      direccion: json['direccion'] ?? '',
      viatico: json['viatico'] ?? '',
      utilidad: json['utilidad'] ?? '0',
      iva: json['iva'] ?? '19',
      currentStep: json['currentStep'] ?? 0,
      trabajos: (json['trabajos'] as List<dynamic>? ?? [])
          .map((t) => Map<String, dynamic>.from(t))
          .toList(),
      materiales: (json['materiales'] as List<dynamic>? ?? [])
          .map((m) => Map<String, dynamic>.from(m))
          .toList(),
      manoObra: (json['manoObra'] as List<dynamic>? ?? [])
          .map((mo) => Map<String, dynamic>.from(mo))
          .toList(),
    );
  }
}