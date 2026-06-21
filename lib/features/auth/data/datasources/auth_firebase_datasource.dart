import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/exceptions/auth_exception.dart';

class AuthFirebaseDataSource {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw const AuthException('El correo o contraseña no son correctos.');
      }

      return {"email": user.email, "uid": user.uid};
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mensajeError(e.code));
    }
  }
  String _mensajeError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return 'El correo o contraseña no son correctos.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada. Contacta al administrador.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta nuevamente más tarde.';
      case 'network-request-failed':
        return 'No hay conexión a internet. Verifica tu red e intenta nuevamente.';
      default:
        return 'Ocurrió un error al iniciar sesión. Intenta nuevamente.';
    }
  }

  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}