import '../../features/cliente/data/datasources/clientes_local_datasource.dart';
import '../../features/cliente/data/repositories/cliente_repository_impl.dart';
import '../../features/cliente/domain/usecases/get_clientes_usecase.dart';
import '../../features/cliente/domain/usecases/registrar_cliente.dart';

import '../../features/auth/data/datasources/auth_firebase_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';

// CLIENTES
final clienteRepository = ClienteRepositoryImpl(
  ClientesLocalDataSource(),
);

final getClientesUseCase = GetClientesUseCase(clienteRepository);
final registrarClienteUseCase = RegistrarCliente(clienteRepository);

// AUTH / LOGIN
final authRepository = AuthRepositoryImpl(
  AuthFirebaseDataSource(),
);

final loginUseCase = LoginUseCase(authRepository);