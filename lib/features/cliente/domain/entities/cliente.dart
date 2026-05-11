class Cliente{
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

}

