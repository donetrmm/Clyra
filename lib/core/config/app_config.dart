class AppConfig {
  // db sqlite
  static const String databaseName = 'clyra.db';
  static const int databaseVersion = 1;

  // prefijos para la parte encriptar
  static const String encryptionKeyPrefix = 'clyra_key_';
  static const String encryptionIVPrefix = 'clyra_iv_';

  // variable para alamacenar la key del usuario actual
  static const String currentUserKey = 'current_user';

  // configuración del timer de inactividad
  static const String inactivityTimeoutKey = 'inactivity_timeout_minutes';
  static const String sessionTokenKey = 'session_token';
  static const String lastActivityTimeKey = 'last_activity_time';

  // tiempo por defecto de inactividad (5 minutos)
  static const int defaultInactivityTimeoutMinutes = 5;

  // tiempo mínimo y máximo configurable
  static const int minInactivityTimeoutMinutes = 1;
  static const int maxInactivityTimeoutMinutes = 60;
}
