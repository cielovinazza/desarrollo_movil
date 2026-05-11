import '../../domain/entities/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';

class ClienteRepositoryImpl implements ClienteRepository {

  final List<Cliente> _clientes = [];

  @override
  Future<void> registrarCliente(
    Cliente cliente,
  ) async {

    _clientes.add(cliente);

    print('Cliente registrado');
    print(cliente.nombre);
  }
}