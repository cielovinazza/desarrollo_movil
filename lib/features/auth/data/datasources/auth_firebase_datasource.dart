import 'package:firebase_auth/firebase_auth.dart';

class AuthFirebaseDataSource {

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {

    try {

      final credential = await _firebaseAuth
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        return {
          "email": user.email,
          "uid": user.uid,
        };
      }

      return null;

    } on FirebaseAuthException {

      return null;
    }
  }

  Future<void> resetPassword(String email) async {

  await _firebaseAuth.sendPasswordResetEmail(
    email: email,
  );
}
}