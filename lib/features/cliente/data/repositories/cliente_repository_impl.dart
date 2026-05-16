import '../../domain/entities/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';
import '../datasources/clientes_local_datasource.dart';

class ClienteRepositoryImpl implements ClienteRepository {

  final ClientesLocalDataSource localDataSource;

  ClienteRepositoryImpl(this.localDataSource);

  @override
  Future<void> registrarCliente(Cliente cliente) async {

    final clientes = await localDataSource.getClientes();

    final rutExiste = clientes.any(
      (c) =>
          c.rut.replaceAll('.', '').toUpperCase() ==
          cliente.rut.replaceAll('.', '').toUpperCase(),
    );

    if (rutExiste) {
      throw Exception('Ya existe un cliente con ese RUT');
    }

    final nuevoCliente = Cliente(
      id: clientes.length + 1,
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
    return await localDataSource.getClientes();
  }

  @override
  Future<void> editarCliente(Cliente cliente) async {

    final clientes = await localDataSource.getClientes();

    final rutDuplicado = clientes.any(
      (c) =>
          c.id != cliente.id &&
          c.rut.replaceAll('.', '').toUpperCase() ==
              cliente.rut.replaceAll('.', '').toUpperCase(),
    );

    if (rutDuplicado) {
      throw Exception('Ya existe un cliente con ese RUT');
    }

    await localDataSource.editarCliente(cliente);
  }

  Future<List<Cliente>> getClientes() async {
    return await localDataSource.getClientes();
  }
}