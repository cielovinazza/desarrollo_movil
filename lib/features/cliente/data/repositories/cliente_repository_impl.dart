import '../../domain/repositories/cliente_repository.dart';
import '../../domain/entities/cliente.dart';
import '../datasources/clientes_local_datasource.dart';

class ClienteRepositoryImpl implements ClienteRepository {

  final ClientesLocalDataSource localDataSource;

  ClienteRepositoryImpl(this.localDataSource);

  @override
  Future<void> registrarCliente(Cliente cliente) async {

    final nuevoCliente = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'nombre': cliente.nombre,
      'rut': cliente.rut,
      'correo': cliente.correo,
      'telefono': cliente.telefono,
      'direccion': cliente.direccion,
    };

    await localDataSource.agregarCliente(nuevoCliente);
  }

  @override
  Future<List<Cliente>> listarClientes() async {

    final List<Map<String, dynamic>> data =
        await localDataSource.getClientes();

    return data.map<Cliente>((json) {
      final map = json;

      return Cliente(
        id: map['id'] ?? 0,
        nombre: map['nombre'] ?? '',
        rut: map['rut'] ?? '',
        correo: map['correo'] ?? '',
        telefono: map['telefono'] ?? '',
        direccion: map['direccion'],
      );
    }).toList();
  }

  @override
  Future<void> editarCliente(Cliente cliente) async {}
}