import '../../domain/entities/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';

class ClienteRepositoryImpl implements ClienteRepository {
  static final List<Cliente> _clientes = [];

  @override
  Future<void> registrarCliente(Cliente cliente) async {
    final nuevoCliente = Cliente(
      id: _clientes.length + 1,
      nombre: cliente.nombre,
      rut: cliente.rut,
      telefono: cliente.telefono,
      correo: cliente.correo,
      direccion: cliente.direccion,
    );

    _clientes.add(nuevoCliente);
  }

  @override
  Future<List<Cliente>> listarClientes() async {
    return _clientes;
  }
}
