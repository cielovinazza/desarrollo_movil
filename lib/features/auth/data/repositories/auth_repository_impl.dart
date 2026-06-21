import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../datasources/auth_firebase_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthFirebaseDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<User?> login(String email, String password) async {
    final result = await dataSource.login(email, password);

    if (result == null) {
      throw const AuthException('El correo o contraseña no son correctos.');
    }

    return User(email: result['email']);
  }
}