import '../../domain/entities/clientes_entity.dart';

abstract class ClientesRepository {
  Future<List<Cliente>> getClientes();
}