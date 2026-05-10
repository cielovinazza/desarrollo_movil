class AuthMockDataSource {

  Future<Map<String, dynamic>?> login(String email, String password) async {

    await Future.delayed(const Duration(seconds: 1));

    if (email == "admin@test.com" && password == "1234") {
      return {
        "email": email
      };
    }

    return null;
  }
}