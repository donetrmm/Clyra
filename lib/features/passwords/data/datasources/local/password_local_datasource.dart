import '../../../../../core/storage/database_service.dart';
import '../../../../../core/storage/encryption_service.dart';
import '../../models/password_entry_model.dart';

abstract class PasswordLocalDataSource {
  Future<List<PasswordEntryModel>> getAllPasswords();
  Future<List<PasswordEntryModel>> getFavoritePasswords();
  Future<List<PasswordEntryModel>> searchPasswords(String query);
  Future<PasswordEntryModel?> getPasswordById(String id);
  Future<void> insertPassword(PasswordEntryModel password);
  Future<void> updatePassword(PasswordEntryModel password);
  Future<void> deletePassword(String id);
  Future<void> migratePasswordEntry(
    PasswordEntryModel password,
    String masterPassword,
  );
  Future<void> reencryptAllWithNewPassword(
    String oldPassword,
    String newPassword,
  );
}

class PasswordLocalDataSourceImpl implements PasswordLocalDataSource {
  final DatabaseService _databaseService;
  final EncryptionService _encryptionService;

  PasswordLocalDataSourceImpl({
    required DatabaseService databaseService,
    required EncryptionService encryptionService,
  }) : _databaseService = databaseService,
       _encryptionService = encryptionService;

  @override
  Future<List<PasswordEntryModel>> getAllPasswords() async {
    final passwordsData = await _databaseService.getAllPasswords();
    return passwordsData.map((data) {
      final decryptedData = _decryptPasswordData(data);
      return PasswordEntryModel.fromJson(decryptedData);
    }).toList();
  }

  @override
  Future<List<PasswordEntryModel>> getFavoritePasswords() async {
    final passwordsData = await _databaseService.getFavoritePasswords();
    return passwordsData.map((data) {
      final decryptedData = _decryptPasswordData(data);
      return PasswordEntryModel.fromJson(decryptedData);
    }).toList();
  }

  @override
  Future<List<PasswordEntryModel>> searchPasswords(String query) async {
    final passwordsData = await _databaseService.searchPasswords(query);
    return passwordsData.map((data) {
      final decryptedData = _decryptPasswordData(data);
      return PasswordEntryModel.fromJson(decryptedData);
    }).toList();
  }

  @override
  Future<PasswordEntryModel?> getPasswordById(String id) async {
    final passwordData = await _databaseService.getPassword(id);
    if (passwordData == null) return null;

    final decryptedData = _decryptPasswordData(passwordData);
    return PasswordEntryModel.fromJson(decryptedData);
  }

  @override
  Future<void> insertPassword(PasswordEntryModel password) async {
    final encryptedData = _encryptPasswordData(password.toJson());
    await _databaseService.insertPassword(encryptedData);
  }

  @override
  Future<void> updatePassword(PasswordEntryModel password) async {
    final encryptedData = _encryptPasswordData(password.toJson());
    await _databaseService.updatePassword(password.id, encryptedData);
  }

  @override
  Future<void> deletePassword(String id) async {
    await _databaseService.deletePassword(id);
  }

  @override
  Future<void> migratePasswordEntry(
    PasswordEntryModel password,
    String masterPassword,
  ) async {
    try {
      final jsonData = password.toJson();
      bool needsUpdate = false;

      if (jsonData['password'] != null &&
          _encryptionService.needsMigration(jsonData['password'])) {
        final migratedPassword = _encryptionService.migrateOldData(
          jsonData['password'],
          masterPassword,
        );
        jsonData['password'] = migratedPassword;
        needsUpdate = true;
      }

      if (jsonData['notes'] != null &&
          jsonData['notes'].isNotEmpty &&
          _encryptionService.needsMigration(jsonData['notes'])) {
        final migratedNotes = _encryptionService.migrateOldData(
          jsonData['notes'],
          masterPassword,
        );
        jsonData['notes'] = migratedNotes;
        needsUpdate = true;
      }

      if (needsUpdate) {
        await _databaseService.updatePassword(password.id, jsonData);
      }
    } catch (e) {
      /*print('Error al migrar entrada ${password.title}: $e');*/
    }
  }

  @override
  Future<void> reencryptAllWithNewPassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final allPasswords = await _databaseService.getAllPasswords();

      /*print(
        'Re-encriptando ${allPasswords.length} contraseñas con nueva contraseña maestra...',
      );*/

      int successCount = 0;
      int errorCount = 0;

      for (final passwordData in allPasswords) {
        try {
          final updatedData = Map<String, dynamic>.from(passwordData);
          bool needsUpdate = false;

          if (passwordData['password'] != null &&
              passwordData['password'].isNotEmpty) {
            try {
              final reencryptedPassword = _encryptionService
                  .reencryptWithNewPassword(
                    passwordData['password'],
                    oldPassword,
                    newPassword,
                  );
              updatedData['password'] = reencryptedPassword;
              needsUpdate = true;
            } catch (e) {
              /*print(
                'Error re-encriptando password para ${passwordData['id']}: $e',
              );*/
              errorCount++;
              continue;
            }
          }

          if (passwordData['notes'] != null &&
              passwordData['notes'].isNotEmpty) {
            try {
              final reencryptedNotes = _encryptionService
                  .reencryptWithNewPassword(
                    passwordData['notes'],
                    oldPassword,
                    newPassword,
                  );
              updatedData['notes'] = reencryptedNotes;
              needsUpdate = true;
            } catch (e) {
              /*print(
                'Error re-encriptando notes para ${passwordData['id']}: $e',
              );*/
            }
          }

          if (needsUpdate) {
            await _databaseService.updatePassword(
              passwordData['id'],
              updatedData,
            );
            successCount++;
          }
        } catch (e) {
          /*print('Error procesando entrada ${passwordData['id']}: $e');*/
          errorCount++;
        }
      }

      /*print(
        'Re-encriptación completada: $successCount exitosas, $errorCount errores',
      );*/

      if (errorCount > 0) {
        throw Exception(
          'Re-encriptación completada: $successCount exitosas, $errorCount errores.',
        );
      }
    } catch (e) {
      throw Exception('Error durante la re-encriptación: $e');
    }
  }

  Map<String, dynamic> _encryptPasswordData(Map<String, dynamic> data) {
    if (!_encryptionService.isInitialized) {
      throw Exception(
        'EncryptionService no está inicializado. Por favor inicia sesión primero.',
      );
    }

    final encryptedData = Map<String, dynamic>.from(data);

    encryptedData['password'] = _encryptionService.encrypt(data['password']);
    if (data['notes'] != null && data['notes'].isNotEmpty) {
      encryptedData['notes'] = _encryptionService.encrypt(data['notes']);
    }

    return encryptedData;
  }

  Map<String, dynamic> _decryptPasswordData(Map<String, dynamic> data) {
    if (!_encryptionService.isInitialized) {
      throw Exception(
        'EncryptionService no está inicializado. Por favor inicia sesión primero.',
      );
    }

    final decryptedData = Map<String, dynamic>.from(data);

    try {
      if (data['password'] != null && data['password'].isNotEmpty) {
        decryptedData['password'] = _encryptionService.decrypt(
          data['password'],
        );
      }
      if (data['notes'] != null && data['notes'].isNotEmpty) {
        decryptedData['notes'] = _encryptionService.decrypt(data['notes']);
      }
    } catch (e) {
      try {
        if (data['password'] != null && data['password'].isNotEmpty) {
          final migratedPassword = _tryMigrateField(data['password']);
          if (migratedPassword != null) {
            decryptedData['password'] = migratedPassword;

            decryptedData['_needsUpdate'] = true;
          } else {
            decryptedData['password'] =
                '[DATOS CORRUPTOS - Reingresa tu contraseña]';
            decryptedData['_corrupted'] = true;
          }
        }

        if (data['notes'] != null && data['notes'].isNotEmpty) {
          final migratedNotes = _tryMigrateField(data['notes']);
          if (migratedNotes != null) {
            decryptedData['notes'] = migratedNotes;
            decryptedData['_needsUpdate'] = true;
          } else {
            decryptedData['notes'] = '[DATOS CORRUPTOS - Reingresa tus notas]';
            decryptedData['_corrupted'] = true;
          }
        }

        /*print(
          'Intentando migrar entrada ${data['id']}: ${decryptedData['_needsUpdate'] == true ? 'éxito' : 'falló'}',
        );*/
      } catch (migrationError) {
        /*print('Error al migrar entrada ${data['id']}: $migrationError');*/

        decryptedData['password'] =
            '[DATOS CORRUPTOS - Reingresa tu contraseña]';
        decryptedData['notes'] =
            data['notes'] != null && data['notes'].isNotEmpty
                ? '[DATOS CORRUPTOS - Reingresa tus notas]'
                : null;
        decryptedData['_corrupted'] = true;
      }
    }

    return decryptedData;
  }

  String? _tryMigrateField(String encryptedField) {
    try {
      if (!_encryptionService.needsMigration(encryptedField)) {
        return null;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updatePasswordWithMigration(PasswordEntryModel password) async {
    final jsonData = password.toJson();
    if (jsonData['_needsUpdate'] == true) {
      jsonData.remove('_needsUpdate');
      jsonData.remove('_corrupted');
    }

    final encryptedData = _encryptPasswordData(jsonData);
    await _databaseService.updatePassword(password.id, encryptedData);
  }
}
