import '../../features/cliente/data/datasources/clientes_local_datasource.dart';
import '../../features/cliente/data/repositories/cliente_repository_impl.dart';
import '../../features/cliente/domain/usecases/get_clientes_usecase.dart';
import '../../features/cliente/domain/usecases/registrar_cliente.dart';
final clienteRepository = ClienteRepositoryImpl(
  ClientesLocalDataSource(),
);

final getClientesUseCase = GetClientesUseCase(clienteRepository);
final registrarClienteUseCase = RegistrarCliente(clienteRepository);