import '../../domain/entities/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';
import '../datasources/clientes_local_datasource.dart';

class ClienteRepositoryImpl implements ClienteRepository {
  final ClientesLocalDataSource _localDataSource = ClientesLocalDataSource();
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
    await _init();
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
    await _init();
    return _clientes;
  }

  @override
  Future<void> editarCliente(Cliente cliente) async {
    await _init();
    final index = _clientes.indexWhere(
      (c) => c.id == cliente.id,
    );

    if (index != -1) {
      _clientes[index] = cliente;
    }
  }
}