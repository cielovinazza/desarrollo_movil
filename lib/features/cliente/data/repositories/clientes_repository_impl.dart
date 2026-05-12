import '../../domain/entities/clientes_entity.dart';
import '../repositories/clientes_repository.dart';
import '../datasources/clientes_local_datasource.dart';

class ClientesRepositoryImpl implements ClientesRepository {

  final ClientesLocalDataSource localDataSource;

  ClientesRepositoryImpl(this.localDataSource);

  @override
  Future<List<Cliente>> getClientes() async {
    final data = await localDataSource.getClientes();

    return data.map<Cliente>((json) {
      return Cliente(
        id: json['id'],
        nombre: json['nombre'],
      );
    }).toList();
  }
}
