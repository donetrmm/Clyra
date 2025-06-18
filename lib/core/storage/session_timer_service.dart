import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import 'encryption_service.dart';

class SessionTimerService {
  static SessionTimerService? _instance;

  Timer? _inactivityTimer;
  Timer? _periodicChecker;
  String? _currentSessionToken;
  DateTime? _lastActivityTime;
  bool _isSessionActive = false;
  int _timeoutMinutes = AppConfig.defaultInactivityTimeoutMinutes;

  final SharedPreferences _prefs;
  final EncryptionService _encryptionService;

  VoidCallback? _onSessionExpired;
  VoidCallback? _onSessionUpdate;

  SessionTimerService._({
    required SharedPreferences prefs,
    required EncryptionService encryptionService,
  }) : _prefs = prefs,
       _encryptionService = encryptionService;

  static Future<SessionTimerService> create({
    required SharedPreferences prefs,
    required EncryptionService encryptionService,
  }) async {
    final service = SessionTimerService._(
      prefs: prefs,
      encryptionService: encryptionService,
    );
    await service._loadConfiguration();
    _instance = service;
    return service;
  }

  static SessionTimerService get instance {
    if (_instance == null) {
      throw Exception(
        'SessionTimerService no ha sido inicializado. Llama a create() primero.',
      );
    }
    return _instance!;
  }

  bool get isSessionActive => _isSessionActive;

  int get timeoutMinutes => _timeoutMinutes;

  int get remainingTimeSeconds {
    if (!_isSessionActive || _lastActivityTime == null) return 0;

    final elapsed = DateTime.now().difference(_lastActivityTime!);
    final timeoutDuration = Duration(minutes: _timeoutMinutes);
    final remaining = timeoutDuration - elapsed;

    return remaining.inSeconds > 0 ? remaining.inSeconds : 0;
  }

  String? getCurrentSessionToken() {
    return _currentSessionToken;
  }

  Future<void> startSession({
    VoidCallback? onSessionExpired,
    VoidCallback? onSessionUpdate,
  }) async {
    if (!_encryptionService.isInitialized) {
      throw Exception(
        'EncryptionService debe estar inicializado antes de iniciar sesión',
      );
    }

    _onSessionExpired = onSessionExpired;
    _onSessionUpdate = onSessionUpdate;
    _currentSessionToken = const Uuid().v4();
    _lastActivityTime = DateTime.now();
    _isSessionActive = true;

    await _saveSessionData();
    _startInactivityTimer();
    _startPeriodicChecker();

    debugPrint(
      'SessionTimerService: Sesión iniciada con timeout de $_timeoutMinutes minutos',
    );
  }

  Future<void> updateActivity() async {
    if (!_isSessionActive) return;

    _lastActivityTime = DateTime.now();
    await _saveLastActivityTime();
    _restartInactivityTimer();
  }

  Future<void> setTimeoutMinutes(int minutes) async {
    if (minutes < AppConfig.minInactivityTimeoutMinutes ||
        minutes > AppConfig.maxInactivityTimeoutMinutes) {
      throw ArgumentError(
        'El timeout debe estar entre ${AppConfig.minInactivityTimeoutMinutes} y ${AppConfig.maxInactivityTimeoutMinutes} minutos',
      );
    }

    _timeoutMinutes = minutes;
    await _saveTimeoutConfiguration();

    if (_isSessionActive) {
      _restartInactivityTimer();
    }

    debugPrint(
      'SessionTimerService: Timeout configurado a $_timeoutMinutes minutos',
    );
  }

  Future<void> endSession() async {
    _stopTimers();
    _isSessionActive = false;
    _currentSessionToken = null;
    _lastActivityTime = null;
    _onSessionExpired = null;
    _onSessionUpdate = null;

    await _clearSessionData();
    debugPrint('SessionTimerService: Sesión terminada');
  }

  Future<bool> isSessionValid() async {
    if (!_isSessionActive || _lastActivityTime == null) return false;

    final elapsed = DateTime.now().difference(_lastActivityTime!);
    final isValid = elapsed.inMinutes < _timeoutMinutes;

    if (!isValid) {
      debugPrint('SessionTimerService: Sesión expirada por inactividad');
      await _handleSessionExpiry();
    }

    return isValid;
  }

  Future<bool> restoreSession({
    VoidCallback? onSessionExpired,
    VoidCallback? onSessionUpdate,
  }) async {
    if (!_encryptionService.isInitialized) return false;

    try {
      final sessionData = await _loadSessionData();
      if (sessionData == null) return false;

      _currentSessionToken = sessionData['token'];
      final lastActivityStr = sessionData['lastActivity'];
      if (lastActivityStr != null) {
        _lastActivityTime = DateTime.parse(lastActivityStr);
      }
      _onSessionExpired = onSessionExpired;
      _onSessionUpdate = onSessionUpdate;

      final isValid = await isSessionValid();
      if (isValid) {
        _isSessionActive = true;
        _startInactivityTimer();
        _startPeriodicChecker();
        debugPrint('SessionTimerService: Sesión restaurada exitosamente');
        return true;
      }
    } catch (e) {
      debugPrint('SessionTimerService: Error al restaurar sesión: $e');
    }

    return false;
  }

  void _startInactivityTimer() {
    _stopTimers();

    _inactivityTimer = Timer(Duration(minutes: _timeoutMinutes), () {
      _handleSessionExpiry();
    });
  }

  void _restartInactivityTimer() {
    _startInactivityTimer();
  }

  void _startPeriodicChecker() {
    _periodicChecker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isSessionActive) {
        isSessionValid();
        _onSessionUpdate?.call();
      }
    });
  }

  void _stopTimers() {
    _inactivityTimer?.cancel();
    _periodicChecker?.cancel();
    _inactivityTimer = null;
    _periodicChecker = null;
  }

  Future<void> _handleSessionExpiry() async {
    debugPrint('SessionTimerService: Sesión expirada - ejecutando callback');

    final sessionExpiredCallback = _onSessionExpired;

    if (sessionExpiredCallback != null) {
      debugPrint('SessionTimerService: Ejecutando callback de expiración');
      try {
        sessionExpiredCallback.call();
        debugPrint('SessionTimerService: Callback ejecutado exitosamente');
      } catch (e) {
        debugPrint('SessionTimerService: Error ejecutando callback: $e');
      }
    } else {
      debugPrint(
        'SessionTimerService: No hay callback de expiración configurado',
      );
    }

    await endSession();
  }

  Future<void> _loadConfiguration() async {
    try {
      final timeoutStr = _prefs.getString(AppConfig.inactivityTimeoutKey);
      if (timeoutStr != null && _encryptionService.isInitialized) {
        final decryptedTimeout = _encryptionService.decrypt(timeoutStr);
        _timeoutMinutes =
            int.tryParse(decryptedTimeout) ??
            AppConfig.defaultInactivityTimeoutMinutes;
      }
    } catch (e) {
      debugPrint('SessionTimerService: Error cargando configuración: $e');
      _timeoutMinutes = AppConfig.defaultInactivityTimeoutMinutes;
    }
  }

  Future<void> _saveTimeoutConfiguration() async {
    if (!_encryptionService.isInitialized) return;

    try {
      final encryptedTimeout = _encryptionService.encrypt(
        _timeoutMinutes.toString(),
      );
      await _prefs.setString(AppConfig.inactivityTimeoutKey, encryptedTimeout);
    } catch (e) {
      debugPrint('SessionTimerService: Error guardando configuración: $e');
    }
  }

  Future<void> _saveSessionData() async {
    if (!_encryptionService.isInitialized ||
        _currentSessionToken == null ||
        _lastActivityTime == null) {
      return;
    }

    try {
      final encryptedToken = _encryptionService.encrypt(_currentSessionToken!);
      await _prefs.setString(AppConfig.sessionTokenKey, encryptedToken);

      await _saveLastActivityTime();
    } catch (e) {
      debugPrint('SessionTimerService: Error guardando datos de sesión: $e');
    }
  }

  Future<void> _saveLastActivityTime() async {
    if (!_encryptionService.isInitialized || _lastActivityTime == null) return;

    try {
      final encryptedTime = _encryptionService.encrypt(
        _lastActivityTime!.toIso8601String(),
      );
      await _prefs.setString(AppConfig.lastActivityTimeKey, encryptedTime);
    } catch (e) {
      debugPrint(
        'SessionTimerService: Error guardando tiempo de actividad: $e',
      );
    }
  }

  Future<Map<String, String>?> _loadSessionData() async {
    if (!_encryptionService.isInitialized) return null;

    try {
      final encryptedToken = _prefs.getString(AppConfig.sessionTokenKey);
      final encryptedTime = _prefs.getString(AppConfig.lastActivityTimeKey);

      if (encryptedToken == null || encryptedTime == null) return null;

      final token = _encryptionService.decrypt(encryptedToken);
      final lastActivity = _encryptionService.decrypt(encryptedTime);

      return {'token': token, 'lastActivity': lastActivity};
    } catch (e) {
      debugPrint('SessionTimerService: Error cargando datos de sesión: $e');
      return null;
    }
  }

  Future<void> _clearSessionData() async {
    await _prefs.remove(AppConfig.sessionTokenKey);
    await _prefs.remove(AppConfig.lastActivityTimeKey);
  }

  Future<void> clearAllData() async {
    await endSession();
    await _prefs.remove(AppConfig.inactivityTimeoutKey);
    _timeoutMinutes = AppConfig.defaultInactivityTimeoutMinutes;
  }

  void dispose() {
    _stopTimers();
    _isSessionActive = false;
    _currentSessionToken = null;
    _lastActivityTime = null;
    _onSessionExpired = null;
    _onSessionUpdate = null;
  }
}
