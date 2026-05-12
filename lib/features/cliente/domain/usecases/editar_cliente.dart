import '../entities/cliente.dart';
import '../repositories/cliente_repository.dart';

class EditarCliente {
  final ClienteRepository repository;

  EditarCliente(this.repository);

  Future<void> call(Cliente cliente) {
    return repository.editarCliente(cliente);
  }
}