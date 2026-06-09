import '../entities/cliente.dart';
import '../repositories/cliente_repository.dart';

class RegistrarCliente {

  final ClienteRepository repository;

  RegistrarCliente(this.repository);

  Future<void> call(Cliente cliente) async {

    await repository.registrarCliente(
      cliente,
    );
  }
}