import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import '../config/app_config.dart';

class EncryptionService {
  Encrypter? _encrypter;
  IV? _staticIV;
  bool _isInitialized = false;

  static const String _versionPrefix = 'v1:';

  static final IV _fixedIV = IV.fromBase64(
    'AAAAAAAAAAAAAAAAAAAAAA==',
  );

  EncryptionService._();
  static final EncryptionService _instance = EncryptionService._();
  static EncryptionService get instance => _instance;

  bool get isInitialized => _isInitialized;

  void initialize(String masterPassword) {
    final key = _deriveKeyFromPassword(masterPassword);
    _encrypter = Encrypter(AES(key));
    _staticIV = _fixedIV;
    _isInitialized = true;
  }

  Key _deriveKeyFromPassword(String password) {
    const int iterations = 10000;
    const String salt = AppConfig.encryptionKeyPrefix;

    var bytes = utf8.encode(salt + password);

    for (int i = 0; i < iterations; i++) {
      var digest = sha256.convert(bytes);
      bytes = Uint8List.fromList(digest.bytes);
    }

    return Key(bytes);
  }

  String encrypt(String plainText) {
    if (!_isInitialized || _encrypter == null || _staticIV == null) {
      throw Exception(
        'EncryptionService no está inicializado. Llama a initialize() primero.',
      );
    }

    if (plainText.isEmpty) return '';

    try {
      final dataWithChecksum = _addChecksum(plainText);
      final encrypted = _encrypter!.encrypt(dataWithChecksum, iv: _staticIV!);

      return _versionPrefix + encrypted.base64;
    } catch (e) {
      throw Exception('Error al encriptar: $e');
    }
  }

  String decrypt(String encryptedText) {
    if (!_isInitialized || _encrypter == null || _staticIV == null) {
      throw Exception('EncryptionService no está inicializado.');
    }

    if (encryptedText.isEmpty) return '';

    try {
      String base64Data;
      if (encryptedText.startsWith(_versionPrefix)) {
        base64Data = encryptedText.substring(_versionPrefix.length);
      } else {
        throw Exception('Datos encriptados sin versión o formato incompatible');
      }

      final encrypted = Encrypted.fromBase64(base64Data);
      final decryptedWithChecksum = _encrypter!.decrypt(
        encrypted,
        iv: _staticIV!,
      );

      return _verifyAndRemoveChecksum(decryptedWithChecksum);
    } catch (e) {
      throw Exception('Error al desencriptar: $e');
    }
  }

  String _addChecksum(String data) {
    final checksum = _calculateChecksum(data);
    return '$data|$checksum';
  }

  String _verifyAndRemoveChecksum(String dataWithChecksum) {
    final parts = dataWithChecksum.split('|');
    if (parts.length != 2) {
      throw Exception('Formato de datos inválido - falta checksum');
    }

    final data = parts[0];
    final checksum = parts[1];
    final expectedChecksum = _calculateChecksum(data);

    if (checksum != expectedChecksum) {
      throw Exception('Checksum inválido - datos corruptos');
    }

    return data;
  }

  String _calculateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8); 
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }

  bool needsMigration(String encryptedText) {
    return !encryptedText.startsWith(_versionPrefix);
  }

  String migrateOldData(String oldEncryptedData, String masterPassword) {
    try {
      final oldKey = _deriveOldKeyFromPassword(masterPassword);
      final oldIV = _deriveOldIVFromPassword(masterPassword);
      final oldEncrypter = Encrypter(AES(oldKey));

      final encrypted = Encrypted.fromBase64(oldEncryptedData);
      final decrypted = oldEncrypter.decrypt(encrypted, iv: oldIV);

      return encrypt(decrypted);
    } catch (e) {
      throw Exception('No se pudo migrar los datos antiguos: $e');
    }
  }

  Key _deriveOldKeyFromPassword(String password) {
    final bytes = utf8.encode(AppConfig.encryptionKeyPrefix + password);
    final digest = sha256.convert(bytes);
    return Key(Uint8List.fromList(digest.bytes));
  }

  IV _deriveOldIVFromPassword(String password) {
    final bytes = utf8.encode(AppConfig.encryptionIVPrefix + password);
    final digest = sha256.convert(bytes);
    return IV(Uint8List.fromList(digest.bytes.take(16).toList()));
  }

  void dispose() {
    _encrypter = null;
    _staticIV = null;
    _isInitialized = false;
  }

  static EncryptionService createTemporary(String password) {
    final tempService = EncryptionService._();
    tempService.initialize(password);
    return tempService;
  }

  String reencryptWithNewPassword(
    String encryptedText,
    String oldPassword,
    String newPassword,
  ) {
    final oldService = createTemporary(oldPassword);

    final plainText = oldService.decrypt(encryptedText);

    final newService = createTemporary(newPassword);

    return newService.encrypt(plainText);
  }
}
