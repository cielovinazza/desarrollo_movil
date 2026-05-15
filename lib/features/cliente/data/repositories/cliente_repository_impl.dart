// lib/features/cliente/data/repositories/cliente_repository_impl.dart

import '../../domain/entities/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';
import '../datasources/clientes_local_datasource.dart';

class ClienteRepositoryImpl implements ClienteRepository {
  final ClientesLocalDataSource localDataSource;

  // El constructor DEBE recibir el DataSource
  ClienteRepositoryImpl(this.localDataSource);

  @override
  Future<List<Cliente>> getClientes() async {
    return await localDataSource.getClientes();
  }

  // Cumplimos con el contrato exacto que pide tu interfaz abstracta
  @override
  Future<List<Cliente>> listarClientes() async {
    return await localDataSource.getClientes();
  }

  @override
  Future<void> registrarCliente(Cliente cliente) async {
    await localDataSource.agregarCliente(cliente);
  }

  @override
  Future<void> editarCliente(Cliente cliente) async {
    await localDataSource.editarCliente(cliente);
  }
}