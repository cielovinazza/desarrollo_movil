class MaterialEntity {
  final String nombre;
  final String unidadMedida;
  final double costoUnitario;

  MaterialEntity({
    required this.nombre,
    required this.unidadMedida,
    required this.costoUnitario,
  });

  MaterialEntity copyWith({
    String? nombre,
    String? unidadMedida,
    double? costoUnitario,
  }) {
    return MaterialEntity(
      nombre: nombre ?? this.nombre,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      costoUnitario: costoUnitario ?? this.costoUnitario,
    );
  }
}
