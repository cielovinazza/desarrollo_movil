class ClienteDto {

  final String id;
  final String nombre;
  final String rut;
  final String correo;
  final String telefono;
  final String? direccion;

  ClienteDto({
    required this.id,
    required this.nombre,
    required this.rut,
    required this.correo,
    required this.telefono,
    this.direccion,
  });

  Map<String, dynamic> toMap() {

    return {
      'id': id,
      'nombre': nombre,
      'rut':rut,
      'correo': correo,
      'telefono': telefono,
      'direccion': direccion,
    };
  }

  factory ClienteDto.fromFirestore(
    String id,
    Map<String, dynamic> map,
  ) {

    return ClienteDto(
      id: id,
      nombre: map['nombre'] ?? '' ,
      rut: map['rut'] ?? '',
      correo: map['correo'] ?? '',
      telefono: map['telefono'] ?? '',
      direccion: map['direccion'] ?? 'Sin Dirección',
    );
  }
}