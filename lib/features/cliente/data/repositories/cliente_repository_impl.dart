import '../../domain/entities/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';

class ClienteRepositoryImpl implements ClienteRepository {
  static final List<Cliente> _clientes = [];

  @override
  Future<void> registrarCliente(Cliente cliente) async {

    final rutExiste = _clientes.any(
      (c) =>
          c.rut.replaceAll('.', '').toUpperCase() ==
          cliente.rut.replaceAll('.', '').toUpperCase(),
    );

    if (rutExiste) {
      throw Exception('Ya existe un cliente con ese RUT');
    }



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

  @override
  Future<void> editarCliente(Cliente cliente) async {
    final index = _clientes.indexWhere(
      (c) => c.id == cliente.id,
    );

    if (index != -1) {
      _clientes[index] = cliente;
    }
  }
}