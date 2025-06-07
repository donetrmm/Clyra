import '../entities/user.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> register(String email, String password);
  Future<User> login(String email, String password);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<bool> verifyMasterPassword(String password);
  Future<void> changeMasterPassword(String currentPassword, String newPassword);

  Future<void> updateBiometricSetting(bool enabled);
  Future<bool> authenticateWithBiometrics();
}
