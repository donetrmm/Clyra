import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/storage/encryption_service.dart';
import '../../../../core/storage/session_timer_service.dart';
import '../../../../core/injection/injection_container.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../passwords/data/datasources/local/password_local_datasource.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final EncryptionService _encryptionService;
  SessionTimerService? _sessionTimerService;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _sessionExpired = false;

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
      _currentUser != null &&
      _encryptionService.isInitialized &&
      !_sessionExpired;

  
  bool get hasSessionExpired => _sessionExpired;

  
  SessionTimerService? get sessionTimerService => _sessionTimerService;

  
  bool get isSessionActive => _sessionTimerService?.isSessionActive ?? false;

  
  int get sessionRemainingSeconds =>
      _sessionTimerService?.remainingTimeSeconds ?? 0;

  
  int get sessionTimeoutMinutes => _sessionTimerService?.timeoutMinutes ?? 5;

  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await _authRepository.getCurrentUser();

      // Si hay un usuario logueado, inicializar el timer service
      if (_currentUser != null && _encryptionService.isInitialized) {
        await _initializeSessionTimer();
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  
  Future<void> _initializeSessionTimer() async {
    try {
      if (_sessionTimerService == null) {
        _sessionTimerService = await sl.getAsync<SessionTimerService>();
      }

      // Intentar restaurar sesión existente o iniciar nueva
      debugPrint('AuthViewModel: Registrando callback de expiración de sesión');
      final restored = await _sessionTimerService!.restoreSession(
        onSessionExpired: _handleSessionExpiry,
        onSessionUpdate: _handleSessionUpdate,
      );

      if (!restored) {
        debugPrint('AuthViewModel: Iniciando nueva sesión con callback');
        await _sessionTimerService!.startSession(
          onSessionExpired: _handleSessionExpiry,
          onSessionUpdate: _handleSessionUpdate,
        );
      } else {
        debugPrint('AuthViewModel: Sesión restaurada con callback');
      }

      debugPrint('AuthViewModel: SessionTimerService inicializado');
    } catch (e) {
      debugPrint('AuthViewModel: Error inicializando SessionTimerService: $e');
    }
  }

  
  void _handleSessionExpiry() {
    debugPrint('AuthViewModel: ¡CALLBACK DE EXPIRACIÓN EJECUTADO!');
    debugPrint('AuthViewModel: Sesión expirada por inactividad');

    // Marcar como sesión expirada
    _sessionExpired = true;

    // Ejecutar logout automático
    logout().then((_) {
      // Notificar cambios inmediatamente
      notifyListeners();

      // Mensaje para mostrar en la UI
      _setError('Sesión cerrada por inactividad');

      // Usar Timer.run para asegurar que la navegación se ejecute en el próximo frame
      Timer.run(() {
        debugPrint('AuthViewModel: Forzando navegación al login...');
        AppRouter.navigateToLogin();
      });
    });
  }

  
  void _handleSessionUpdate() {
    // Notificar cambios para actualizar la UI en tiempo real
    notifyListeners();
  }

  
  void _clearSessionExpired() {
    _sessionExpired = false;
    _clearError();
  }

  
  Future<void> updateActivity() async {
    if (_sessionTimerService != null && _sessionTimerService!.isSessionActive) {
      await _sessionTimerService!.updateActivity();
    }
  }

  
  Future<bool> setSessionTimeout(int minutes) async {
    try {
      if (_sessionTimerService != null) {
        await _sessionTimerService!.setTimeoutMinutes(minutes);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Error configurando timeout: $e');
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    _setLoading(true);
    _clearSessionExpired();

    try {
      final user = await _authRepository.register(email, password);
      _currentUser = user;

      _encryptionService.initialize(password);

      // Inicializar timer de sesión después del registro
      await _initializeSessionTimer();

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
    _clearSessionExpired();

    try {
      final user = await _authRepository.login(email, password);
      _currentUser = user;

      _encryptionService.initialize(password);

      await _migrateOldDataIfNeeded(password);

      // Inicializar timer de sesión después del login
      await _initializeSessionTimer();

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
      // Terminar sesión del timer service
      if (_sessionTimerService != null) {
        await _sessionTimerService!.endSession();
      }

      await _authRepository.logout();
      _currentUser = null;

      _encryptionService.dispose();
      _sessionTimerService = null;

      _setLoading(false);

      debugPrint('AuthViewModel: Logout completado, notificando cambios');
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<bool> verifyMasterPassword(String password) async {
    _clearError();

    try {
      final result = await _authRepository.verifyMasterPassword(password);

      if (result) {
        await updateActivity();
      }

      return result;
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

      if (_sessionTimerService != null) {
        await _sessionTimerService!.endSession();
        await _initializeSessionTimer();
      }

      await updateActivity();

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
        } else {
          if (_sessionTimerService != null) {
            final isSessionValid = await _sessionTimerService!.isSessionValid();
            if (!isSessionValid) {
              await logout();
              return;
            }
          }
        }
      } else {
        _currentUser = null;
        if (_sessionTimerService != null) {
          await _sessionTimerService!.endSession();
          _sessionTimerService = null;
        }
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
  Map<String, dynamic> getSessionStats() {
    if (_sessionTimerService == null) {
      return {
        'isActive': false,
        'timeoutMinutes': 5,
        'remainingSeconds': 0,
        'hasEncryptedStorage': false,
        'sessionTokenPreview': null,
      };
    }

    return {
      'isActive': _sessionTimerService!.isSessionActive,
      'timeoutMinutes': _sessionTimerService!.timeoutMinutes,
      'remainingSeconds': _sessionTimerService!.remainingTimeSeconds,
      'hasEncryptedStorage': _encryptionService.isInitialized,
      'sessionTokenPreview': _getSessionTokenPreview(),
    };
  }

  String? _getSessionTokenPreview() {
    if (_sessionTimerService == null ||
        !_sessionTimerService!.isSessionActive) {
      return null;
    }

    final sessionToken = _sessionTimerService!.getCurrentSessionToken();
    if (sessionToken == null || sessionToken.length < 8) {
      return null;
    }

    final start = sessionToken.substring(0, 4);
    final end = sessionToken.substring(sessionToken.length - 4);
    return '$start****$end';
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

  @override
  void dispose() {
    _sessionTimerService?.dispose();
    super.dispose();
  }
}
