import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({required AuthLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  @override
  Future<User?> getCurrentUser() async {
    final userModel = await _localDataSource.getCurrentUser();
    return userModel?.toEntity();
  }

  @override
  Future<User> register(String email, String password) async {
    final userModel = await _localDataSource.createUser(email, password);
    return userModel.toEntity();
  }

  @override
  Future<User> login(String email, String password) async {
    final userModel = await _localDataSource.loginUser(email, password);
    return userModel.toEntity();
  }

  @override
  Future<void> logout() async {
    await _localDataSource.logout();
  }

  @override
  Future<bool> isLoggedIn() async {
    return await _localDataSource.isLoggedIn();
  }

  @override
  Future<bool> verifyMasterPassword(String password) async {
    return await _localDataSource.verifyPassword(password);
  }

  @override
  Future<void> changeMasterPassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _localDataSource.changePassword(currentPassword, newPassword);
  }

  @override
  Future<void> updateBiometricSetting(bool enabled) async {
    throw UnimplementedError('Funcionalidad biométrica pendiente');
  }

  @override
  Future<bool> authenticateWithBiometrics() async {
    throw UnimplementedError('Funcionalidad biométrica pendiente');
  }
}
