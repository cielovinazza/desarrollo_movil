class BorradorCotizacionDto {
  final Map<String, dynamic>? cliente;
  final String clienteTexto;
  final String direccion;
  final String viatico;
  final String viaticoDescripcion;
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
    this.viaticoDescripcion = '',
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
      'viaticoDescripcion': viaticoDescripcion,
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
      cliente: json['cliente'] as Map<String, dynamic>?,
      clienteTexto: json['clienteTexto'] ?? '',
      direccion: json['direccion'] ?? '',
      viatico: json['viatico'] ?? '',
      viaticoDescripcion: json['viaticoDescripcion'] ?? '',
      utilidad: json['utilidad'] ?? '',
      iva: json['iva'] ?? '',
      currentStep: (json['currentStep'] ?? 0) as int,
      trabajos: List<Map<String, dynamic>>.from(
        (json['trabajos'] ?? []).map(
          (e) => Map<String, dynamic>.from(e),
        ),
      ),
      materiales: List<Map<String, dynamic>>.from(
        (json['materiales'] ?? []).map(
          (e) => Map<String, dynamic>.from(e),
        ),
      ),
      manoObra: List<Map<String, dynamic>>.from(
        (json['manoObra'] ?? []).map(
          (e) => Map<String, dynamic>.from(e),
        ),
      ),
    );
  }
}