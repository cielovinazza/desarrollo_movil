import '../../domain/repositories/cliente_repository.dart';

class ClienteRepositoryImpl implements ClienteRepository {
  static final List<Cliente> _clientes = [];

  static bool _initialized = false;
 
  Future<void> _init() async {
    if (_initialized) return;
    final data = await _localDataSource.getClientes();
    _clientes.addAll(data.map((e) => Cliente.fromJson(e)));
    _initialized = true;
  }
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

    await localDataSource.agregarCliente(nuevoCliente);
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