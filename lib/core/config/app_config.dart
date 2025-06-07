class AppConfig {
  // db sqlite
  static const String databaseName = 'clyra.db';
  static const int databaseVersion = 1;

  // prefijos para la parte encriptar
  static const String encryptionKeyPrefix = 'clyra_key_';
  static const String encryptionIVPrefix = 'clyra_iv_';

  // variable para alamacenar la key del usuario actual
  static const String currentUserKey = 'current_user';
}
