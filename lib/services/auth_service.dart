class AuthService {

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return true;
  }

  Future<bool> register({
    required String nama,
    required String email,
    required String phone,
    required String password,
  }) async {
    return true;
  }

  Future<void> logout() async {}

  Future<void> forgotPassword(String email) async {}

  Future<void> sendOtp(String phone) async {}

  Future<bool> verifyOtp(String code) async {
    return true;
  }

}
