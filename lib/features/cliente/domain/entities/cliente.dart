class Cliente {
  final int? id;
  final String nombre;
  final String rut;
  final String telefono;
  final String correo;
  final String? direccion;

  Cliente({
    this.id,
    required this.nombre,
    required this.rut,
    required this.telefono,
    required this.correo,
    this.direccion,
  });

  Cliente copyWith({
    int? id,
    String? nombre,
    String? rut,
    String? telefono,
    String? correo,
    String? direccion,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      rut: rut ?? this.rut,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      direccion: direccion ?? this.direccion,
    );
  }
  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      nombre: json['nombre'],
      rut: json['rut'],
      telefono: json['telefono'],
      correo: json['correo'],
      direccion: json['direccion'],
    );
  }
}
