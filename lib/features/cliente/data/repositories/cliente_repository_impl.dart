import '../../domain/entities/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';
import '../datasources/clientes_remote_datasource.dart';
import '../mappers/cliente_mapper.dart';

class ClienteRepositoryImpl implements ClienteRepository {

  final ClientesRemoteDataSource remoteDataSource;

  ClienteRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> registrarCliente(Cliente cliente) async {

    final clientesDto = await remoteDataSource.getClientes();
    final clientes = clientesDto
        .map((dto) => ClienteMapper.toEntity(dto))
        .toList();

    final rutNuevo = cliente.rut.replaceAll('.', '').toUpperCase();

    final rutExiste = clientes.any((c) =>
        c.rut.replaceAll('.', '').toUpperCase() == rutNuevo
    );

    if (rutExiste) {
      throw Exception('Ya existe un cliente con ese RUT');
    }

    final dto = ClienteMapper.toDto(cliente);

    await remoteDataSource.agregarCliente(dto);
  }

  @override
  Future<List<Cliente>> listarClientes() async {

    final dtos = await remoteDataSource.getClientes();

    return dtos
        .map((dto) => ClienteMapper.toEntity(dto))
        .toList();
  }

  @override
  Future<void> editarCliente(Cliente cliente) async {

    final clientesDto = await remoteDataSource.getClientes();
    final clientes = clientesDto
        .map((dto) => ClienteMapper.toEntity(dto))
        .toList();

    final rutNuevo = cliente.rut.replaceAll('.', '').toUpperCase();

    final rutDuplicado = clientes.any((c) =>
        c.id != cliente.id &&
        c.rut.replaceAll('.', '').toUpperCase() == rutNuevo
    );

    if (rutDuplicado) {
      throw Exception('Ya existe un cliente con ese RUT');
    }
    final dto = ClienteMapper.toDto(cliente);
    await remoteDataSource.editarCliente(dto.id, dto);
  }

  Future<List<Cliente>> getClientes() async {
    final dtos = await remoteDataSource.getClientes();
    return dtos.map((dto) => ClienteMapper.toEntity(dto)).toList();
  }
}