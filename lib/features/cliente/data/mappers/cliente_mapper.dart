import '../../domain/entities/cliente.dart';
import '../dtos/cliente_dtos.dart';

class ClienteMapper {

  static ClienteDto toDto(Cliente cliente,) {
    return ClienteDto(
      id: cliente.id.toString(),
      nombre: cliente.nombre,
      rut:cliente.rut,
      correo: cliente.correo,
      telefono: cliente.telefono,
      direccion: cliente.direccion,
    );
  }

  static Cliente toEntity(ClienteDto dto,) {
    return Cliente(
      id: dto.id,
      nombre: dto.nombre,
      rut: dto.rut,
      correo: dto.correo,
      telefono: dto.telefono,
      direccion: dto.direccion,
    );
  }
}