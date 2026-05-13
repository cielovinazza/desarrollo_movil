// lib/features/cliente/domain/repositories/cliente_repository.dart

import '../../domain/entities/cliente.dart';

abstract class ClienteRepository {
  Future<List<Cliente>> listarClientes();
  Future<void> registrarCliente(Cliente cliente);
  Future<void> editarCliente(Cliente cliente);
}