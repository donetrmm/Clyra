import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/storage/database_service.dart';
import '../../../../../core/storage/encryption_service.dart';
import '../../../../../core/config/app_config.dart';
import '../../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> createUser(String email, String password);
  Future<UserModel> loginUser(String email, String password);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<bool> verifyPassword(String password);
  Future<void> changePassword(String currentPassword, String newPassword);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final DatabaseService _databaseService;
  final EncryptionService _encryptionService;
  final SharedPreferences _sharedPreferences;

  AuthLocalDataSourceImpl({
    required DatabaseService databaseService,
    required EncryptionService encryptionService,
    required SharedPreferences sharedPreferences,
  }) : _databaseService = databaseService,
       _encryptionService = encryptionService,
       _sharedPreferences = sharedPreferences;

  @override
  Future<UserModel?> getCurrentUser() async {
    final userJson = _sharedPreferences.getString(AppConfig.currentUserKey);
    if (userJson == null) return null;

    final userData = UserModel.fromJsonString(userJson);
    return userData;
  }

  @override
  Future<UserModel> createUser(String email, String password) async {
    final userExists = await _databaseService.userExists(email);
    if (userExists) {
      throw Exception('Ya existe una cuenta con este correo electrónico');
    }

    final hashedPassword = _encryptionService.hashPassword(password);

    final now = DateTime.now();
    final userData = {
      'id': _generateUserId(),
      'email': email,
      'master_password_hash': hashedPassword,
      'created_at': now.toIso8601String(),
      'last_login_at': now.toIso8601String(),
      'biometric_enabled': 0,
    };

    await _databaseService.insertUser(userData);

    final user = UserModel.fromJson(userData);

    await _setCurrentUser(user);

    return user;
  }

  @override
  Future<UserModel> loginUser(String email, String password) async {
    final userData = await _databaseService.getUser(email);
    if (userData == null) {
      throw Exception('Correo electrónico o contraseña incorrectos');
    }

    final isValidPassword = _encryptionService.verifyPassword(
      password,
      userData['master_password_hash'] as String,
    );

    if (!isValidPassword) {
      throw Exception('Correo electrónico o contraseña incorrectos');
    }

    final updatedUserData = Map<String, dynamic>.from(userData);
    updatedUserData['last_login_at'] = DateTime.now().toIso8601String();

    await _databaseService.updateUser(userData['id'] as String, {
      'last_login_at': updatedUserData['last_login_at'],
    });

    final user = UserModel.fromJson(updatedUserData);

    await _setCurrentUser(user);

    return user;
  }

  @override
  Future<bool> verifyPassword(String password) async {
    final user = await getCurrentUser();
    if (user == null) return false;

    return _encryptionService.verifyPassword(password, user.masterPasswordHash);
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    final isCurrentPasswordValid = _encryptionService.verifyPassword(
      currentPassword,
      user.masterPasswordHash,
    );

    if (!isCurrentPasswordValid) {
      throw Exception('La contraseña actual es incorrecta');
    }

    final newHashedPassword = _encryptionService.hashPassword(newPassword);

    await _databaseService.updateUser(user.id, {
      'master_password_hash': newHashedPassword,
    });

    final updatedUser = user.copyWith(masterPasswordHash: newHashedPassword);
    await _setCurrentUser(updatedUser);
  }

  @override
  Future<void> logout() async {
    await _sharedPreferences.remove(AppConfig.currentUserKey);
  }

  @override
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  Future<void> _setCurrentUser(UserModel user) async {
    await _sharedPreferences.setString(
      AppConfig.currentUserKey,
      user.toJsonString(),
    );
  }

  String _generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
