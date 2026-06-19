class MaterialEntity {
  final String nombre;
  final String unidadMedida;
  final double costoUnitario;
  final double cantidad;

  MaterialEntity({
    required this.nombre,
    required this.unidadMedida,
    required this.costoUnitario,
    required this.cantidad,
  });

  double get subtotal =>
    double.parse((cantidad * costoUnitario).toStringAsFixed(2));

  MaterialEntity copyWith({
    String? nombre,
    String? unidadMedida,
    double? costoUnitario,
    double? cantidad,
  }) {
    return MaterialEntity(
      nombre: nombre ?? this.nombre,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}