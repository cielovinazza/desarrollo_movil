import '../entities/cliente.dart';

abstract class ClienteRepository {
  Future<void> registrarCliente(Cliente cliente);
  Future<List<Cliente>> listarClientes();
}
