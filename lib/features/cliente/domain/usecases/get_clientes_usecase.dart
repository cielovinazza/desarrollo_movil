import '../entities/clientes_entity.dart';
import '../../data/repositories/clientes_repository.dart';

class GetClientesUseCase {

  final ClientesRepository repository;

  GetClientesUseCase(this.repository);

  Future<List<Cliente>> call() {
    return repository.getClientes();
  }
}