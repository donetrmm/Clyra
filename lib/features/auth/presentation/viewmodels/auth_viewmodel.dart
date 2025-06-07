import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/storage/encryption_service.dart';
import '../../../../core/injection/injection_container.dart';
import '../../../passwords/data/datasources/local/password_local_datasource.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final EncryptionService _encryptionService;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthViewModel({
    required AuthRepository authRepository,
    required EncryptionService encryptionService,
  }) : _authRepository = authRepository,
       _encryptionService = encryptionService {
    _loadCurrentUser();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn =>
      _currentUser != null && _encryptionService.isInitialized;

  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await _authRepository.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.register(email, password);
      _currentUser = user;

      _encryptionService.initialize(password);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.login(email, password);
      _currentUser = user;

      _encryptionService.initialize(password);

      await _migrateOldDataIfNeeded(password);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.logout();
      _currentUser = null;

      _encryptionService.dispose();

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<bool> verifyMasterPassword(String password) async {
    _clearError();

    try {
      return await _authRepository.verifyMasterPassword(password);
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> changeMasterPassword(
    String currentPassword,
    String newPassword,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final isCurrentPasswordValid = await _authRepository.verifyMasterPassword(
        currentPassword,
      );
      if (!isCurrentPasswordValid) {
        throw Exception('La contraseña actual es incorrecta');
      }

      final passwordDataSource = sl<PasswordLocalDataSource>();
      await passwordDataSource.reencryptAllWithNewPassword(
        currentPassword,
        newPassword,
      );

      await _authRepository.changeMasterPassword(currentPassword, newPassword);

      _encryptionService.dispose();
      _encryptionService.initialize(newPassword);

      /*print(
        'Contraseña maestra cambiada exitosamente. Todos los datos han sido re-encriptados.',
      );*/

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        _currentUser = await _authRepository.getCurrentUser();

        if (!_encryptionService.isInitialized) {
          await _authRepository.logout();
          _currentUser = null;
        }
      } else {
        _currentUser = null;
      }
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _migrateOldDataIfNeeded(String masterPassword) async {
    try {
      /*print('Verificando si hay datos que necesitan migración...');*/
    } catch (e) {
      /*print('Error durante la migración: $e');*/
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
