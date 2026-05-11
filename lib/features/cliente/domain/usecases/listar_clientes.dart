import '../entities/cliente.dart';
import '../repositories/cliente_repository.dart';

class ListarClientes {
  final ClienteRepository repository;

  ListarClientes(this.repository);

  Future<List<Cliente>> call() async {
    return await repository.listarClientes();
  }
}
