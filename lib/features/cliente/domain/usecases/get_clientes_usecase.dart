import '../../domain/entities/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';

class GetClientesUseCase {

  final ClienteRepository repository;

  GetClientesUseCase(this.repository);

Future<List<Cliente>> call() {
  return repository.listarClientes();
}}