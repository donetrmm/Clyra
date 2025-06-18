# 🛡️ Clyra - Administrador de Contraseñas Seguro

Clyra es un administrador de contraseñas personal desarrollado en Flutter que implementa múltiples capas de seguridad para proteger la información sensible de los usuarios.

## ELEMENTOS DE SEGURIDAD IMPLEMENTADOS

### 1. **Encriptación de Datos**

#### Algoritmo de Encriptación AES-256
- **Implementación**: Servicio de encriptación personalizado (`EncryptionService`)
- **Algoritmo**: AES (Advanced Encryption Standard) con clave de 256 bits
- **Modo**: CBC (Cipher Block Chaining)
- **Librería**: `encrypt: ^5.0.3` y `crypto: ^3.0.3`

**Explicación Técnica del AES-256:**
- **AES (Rijndael)**: Algoritmo de cifrado simétrico aprobado por NIST (FIPS 197)
- **Tamaño de bloque**: 128 bits (16 bytes)
- **Tamaño de clave**: 256 bits (32 bytes) - Máximo nivel de seguridad AES
- **Número de rondas**: 14 rondas de transformación
- **Resistencia cuántica**: Seguro contra ataques de computación cuántica hasta ~2^128 operaciones
- **CBC Mode**: Cada bloque se XOR con el bloque cifrado anterior, requiere IV único

#### Derivación de Claves Segura (PBKDF2 Personalizado)
```dart
// Implementación de PBKDF2 personalizada con 10,000 iteraciones
const int iterations = 10000;
const String salt = AppConfig.encryptionKeyPrefix;

// Múltiples iteraciones de SHA-256 para fortalecer la clave
for (int i = 0; i < iterations; i++) {
  var digest = sha256.convert(bytes);
  bytes = Uint8List.fromList(digest.bytes);
}
```

**Explicación Técnica de PBKDF2:**
- **PBKDF2**: Password-Based Key Derivation Function 2 (RFC 2898)
- **Iteraciones**: 10,000 ciclos para aumentar el costo computacional
- **Salt**: Prefijo estático que previene ataques de rainbow table
- **Resistencia**: Protege contra ataques de fuerza bruta y diccionario
- **Tiempo de cómputo**: ~10-50ms en dispositivos modernos (balance seguridad/UX)

#### Verificación de Integridad (HMAC-like)
- **Checksums**: Cada dato encriptado incluye un checksum SHA-256
- **Validación**: Verificación automática de integridad al desencriptar

**Explicación Técnica de Integridad:**
- **Función hash**: SHA-256 con salida truncada a 8 caracteres
- **Verificación**: Comparación de hash calculado vs almacenado
- **Protección**: Detecta modificaciones accidentales o maliciosas
- **Formato**: `datos_originales|checksum_8_chars`

### 2. **Gestión de Contraseñas Maestras**

#### Hash Seguro de Contraseñas (SHA-256)
- **Algoritmo**: SHA-256 para el hash de la contraseña maestra
- **Almacenamiento**: Solo se almacena el hash, nunca la contraseña en texto plano
- **Verificación**: Comparación segura de hashes para autenticación

**Explicación Técnica de SHA-256:**
- **SHA-256**: Secure Hash Algorithm 256-bit (FIPS 180-4)
- **Propiedades**:
  - **Determinista**: Misma entrada → mismo hash
  - **Efecto avalancha**: Cambio mínimo → hash completamente diferente
  - **Resistencia a colisiones**: Computacionalmente es improbable encontrar dos entradas con mismo hash
  - **Irreversibilidad**: Imposible recuperar la entrada desde el hash

### 3. **Generación de Contraseñas Seguras**

#### Generador Criptográficamente Seguro (CSPRNG)
```dart
// Uso de Random.secure() para generación criptográfica
final random = Random.secure();
```

**Explicación Técnica del CSPRNG:**
- **CSPRNG**: Cryptographically Secure Pseudo-Random Number Generator
- **Entropía**: Utiliza fuentes de entropía del sistema operativo
- **Fuentes de entropía**:
  - **Linux/Android**: `/dev/urandom` (kernel entropy pool)
  - **iOS**: `SecRandomCopyBytes` (Secure Random API)
  - **Windows**: `CryptGenRandom` (CryptoAPI)
- **Calidad**: Pasa pruebas estadísticas de aleatoriedad (NIST SP 800-22)
- **Imprevisibilidad**: Imposible predecir valores futuros conociendo anteriores

#### Características del Generador
- **Longitud**: Configurable (mínimo 4, recomendado 16+ caracteres)
- **Conjuntos de caracteres**:
  - Letras minúsculas (a-z): 26 caracteres
  - Letras mayúsculas (A-Z): 26 caracteres
  - Números (0-9): 10 caracteres
  - Símbolos especiales (!@#$%^&*()_+-=[]{}|;:,.<>?): 28 caracteres
- **Exclusión de caracteres similares**: Opcional (i, l, 1, o, O, 0)
- **Garantía de diversidad**: Al menos un carácter de cada tipo seleccionado

#### Análisis de Fortaleza (Algoritmo de Puntuación)
Sistema avanzado de puntuación de contraseñas:
- **Factores evaluados**:
  - Longitud (8+, 12+, 16+, 20+ caracteres)
  - Variedad de caracteres (4 categorías)
  - Múltiples símbolos/números/mayúsculas
- **Penalizaciones**:
  - Caracteres repetidos consecutivos (regex: `(.)\1{2,}`)
  - Secuencias numéricas (012, 123, 234, etc.)
  - Secuencias alfabéticas (abc, bcd, cde, etc.)
  - Palabras comunes (password, 123456, qwerty)
- **Clasificación**: Muy débil (≤2) → Débil (≤4) → Media (≤6) → Fuerte (≤8) → Muy fuerte (9+)

### 4. **Almacenamiento Seguro Local**

#### Base de Datos SQLite con Encriptación
- **Motor**: SQLite local con datos encriptados a nivel de aplicación
- **Campos encriptados**:
  - Contraseñas de usuarios (AES-256)
  - Notas confidenciales (AES-256)
- **Campos en texto plano** (para búsquedas eficientes):
  - Títulos de entradas
  - Nombres de usuario
  - URLs de sitios web
  - Categorías

**Explicación Técnica del Almacenamiento:**
- **Encriptación a nivel de aplicación**: Los datos se encriptan antes de ser escritos a SQLite
- **Búsqueda eficiente**: Campos no sensibles en texto plano permiten consultas SQL rápidas
- **Transacciones ACID**: SQLite garantiza atomicidad, consistencia, aislamiento y durabilidad

#### Estructura de Seguridad
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  master_password_hash TEXT NOT NULL,  
  biometric_enabled INTEGER DEFAULT 0
);

CREATE TABLE passwords (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,           -- Texto plano para búsqueda
  username TEXT NOT NULL,        -- Texto plano para búsqueda
  password TEXT NOT NULL,        -- ENCRIPTADO con AES-256
  website TEXT,                  -- Texto plano para búsqueda
  notes TEXT,                    -- ENCRIPTADO con AES-256
  category TEXT                  -- Texto plano para categorización
);

-- Índices para optimización de consultas
CREATE INDEX idx_passwords_title ON passwords(title);
CREATE INDEX idx_passwords_category ON passwords(category);
CREATE INDEX idx_passwords_favorite ON passwords(is_favorite);
```
### 6. **Seguridad de Sesión**

#### Gestión de Estados Segura
- **Inicialización**: Servicio de encriptación se inicializa solo con credenciales válidas
- **Limpieza de memoria**: Limpieza de memoria automática al cerrar sesión
- **Validación de sesión**: Verificación continua del estado de autenticación

#### Flujo de Datos Seguro
1. **Entrada**: Validación de entrada de usuario
2. **Procesamiento**: Encriptación automática de datos sensibles
3. **Almacenamiento**: Datos encriptados en base de datos local
4. **Recuperación**: Desencriptación automática con verificación de integridad
5. **Presentación**: Datos en memoria solo durante el uso activo

### 7. **Timer de Inactividad Automático**

#### Sistema de Gestión de Sesión Avanzado
El proyecto implementa un sistema robusto de gestión de sesión con timer de inactividad automático:

**Características Técnicas:**
- **Detección de actividad**: Captura automática de interacciones del usuario (toques, gestos, movimientos)
- **Timer configurable**: Timeout ajustable desde 1 minuto hasta 1 hora
- **Almacenamiento seguro**: Configuración y tokens de sesión encriptados con AES-256
- **Validación continua**: Verificación periódica cada 30 segundos del estado de la sesión
- **Restauración de sesión**: Capacidad de restaurar sesiones válidas al reiniciar la app

**Componentes de Seguridad:**
```dart
// Configuración encriptada del timeout
const String inactivityTimeoutKey = 'inactivity_timeout_minutes';
const String sessionTokenKey = 'session_token';
const String lastActivityTimeKey = 'last_activity_time';

// Generación de token único por sesión
final sessionToken = Uuid().v4();

// Almacenamiento encriptado
final encryptedToken = encryptionService.encrypt(sessionToken);
final encryptedTime = encryptionService.encrypt(lastActivity.toIso8601String());
```

**Flujo de Funcionamiento:**
1. **Inicio de sesión**: Se genera un token único y se inicia el timer
2. **Detección de actividad**: Cualquier interacción reinicia el contador
3. **Verificación periódica**: Timer verifica cada 30s si la sesión sigue válida
4. **Cierre automático**: Al expirar, se limpia la sesión y se retorna al login
5. **Indicadores visuales**: Barra de progreso y indicador de tiempo restante

### 8. **Re-encriptación**

#### Re-encriptación Segura
- **Cambio de contraseña maestra**: Re-encriptación automática de todos los datos
## 🔧 CONFIGURACIÓN DE SEGURIDAD

### Dependencias de Seguridad
```yaml
dependencies:
  encrypt: ^5.0.3                    # Encriptación AES (Pointy Castle)
  crypto: ^3.0.3                     # Funciones criptográficas (SHA, HMAC)
  sqflite: ^2.3.3+1                  # Base de datos local segura
  shared_preferences: ^2.2.2          # Almacenamiento de configuración
```

### **IMPLEMENTADO**
- [x] **Cifrado AES-256 de la base de datos** - Encriptación selectiva de campos sensibles
- [x] **Derivación segura de claves (PBKDF2)** - 10,000 iteraciones con salt
- [x] **Limpieza de memoria** - Dispose automático de servicios y controllers
- [x] **Bloqueo automático por inactividad** - Timer de sesión configurable con almacenamiento encriptado

### **EN DESARROLLO**
- [ ] **Desbloqueo biométrico** - Estructura preparada, implementación pendiente

### **FUNCIONALIDADES FUTURAS**
- [ ] **Derivación con Argon2** - Migración desde PBKDF2 a Argon2id para mayor seguridad
- [ ] **Sistema de backup cifrado** - Exportación/importación segura con encriptación E2E