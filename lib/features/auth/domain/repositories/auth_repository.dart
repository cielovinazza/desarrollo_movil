import '../entities/user.dart';

abstract class AuthRepository {
  get dataSource => null;

  Future<User?> login(String email, String password);
}