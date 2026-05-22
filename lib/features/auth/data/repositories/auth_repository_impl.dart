import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/auth_firebase_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {

  final AuthFirebaseDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<User?> login(String email, String password) async {

    final result = await dataSource.login(email, password);

    if (result == null) return null;

    return User(email: result['email']);
  }
}
