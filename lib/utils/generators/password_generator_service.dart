import 'dart:math';

class PasswordGeneratorService {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  static String generatePassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
    bool excludeSimilar = false,
  }) {
    if (length < 4) {
      throw ArgumentError('La longitud mínima de la contraseña debe ser 4');
    }

    String charset = '';
    List<String> requiredChars = [];

    if (includeLowercase) {
      charset +=
          excludeSimilar
              ? _lowercase.replaceAll(RegExp(r'[il1oO0]'), '')
              : _lowercase;
      requiredChars.add(
        _getRandomChar(
          charset.substring(charset.length - (excludeSimilar ? 20 : 26)),
        ),
      );
    }

    if (includeUppercase) {
      final upperChars =
          excludeSimilar
              ? _uppercase.replaceAll(RegExp(r'[IL1OO0]'), '')
              : _uppercase;
      charset += upperChars;
      requiredChars.add(_getRandomChar(upperChars));
    }

    if (includeNumbers) {
      final numberChars =
          excludeSimilar ? _numbers.replaceAll(RegExp(r'[10O]'), '') : _numbers;
      charset += numberChars;
      requiredChars.add(_getRandomChar(numberChars));
    }

    if (includeSymbols) {
      charset += _symbols;
      requiredChars.add(_getRandomChar(_symbols));
    }

    if (charset.isEmpty) {
      throw ArgumentError('Debe incluir al menos un tipo de carácter');
    }

    final random = Random.secure();
    final password = List<String>.generate(
      length - requiredChars.length,
      (index) => charset[random.nextInt(charset.length)],
    );

    password.addAll(requiredChars);

    password.shuffle(random);

    return password.join();
  }

  static String _getRandomChar(String charset) {
    final random = Random.secure();
    return charset[random.nextInt(charset.length)];
  }

  static PasswordStrength checkPasswordStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength.veryWeak;
    }

    int score = 0;
    int bonusPoints = 0;

    // score por longitud
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (password.length >= 16) score += 1;
    if (password.length >= 20) {
      //punto extra para contraseñas muy largas
      score += 1; 
    }

    // puntos por variedad de caracteres
    if (password.contains(RegExp(r'[a-z]'))) score += 1;
    if (password.contains(RegExp(r'[A-Z]'))) score += 1;
    if (password.contains(RegExp(r'[0-9]'))) score += 1;
    if (password.contains(RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]'))) {
      score += 1;
    }

    // puntos bonus por diversidad
    if (password.length >= 16 && score >= 6) {
      bonusPoints += 1; 
    }
    if (password.contains(
      RegExp(
        r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?].*[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]',
      ),
    )) {
      //bonus por símbolos
      bonusPoints += 1;
    }
    if (password.contains(RegExp(r'[A-Z].*[A-Z]'))) {
      //bonus por mayúsculas
      bonusPoints += 1; 
    }
    if (password.contains(RegExp(r'[0-9].*[0-9]'))) {
      //bonus por números
      bonusPoints += 1;
    }

    // penalizaciones
    int penalties = 0;
    if (password.contains(RegExp(r'(.)\1{2,}'))) {
      //penalización por caracteres repetidos
      penalties++;
    }
    if (password.contains(RegExp(r'(012|123|234|345|456|567|678|789|890)'))) {
      //penalización por secuencias numéricas
      penalties++; 
    }
    if (password.contains(
      RegExp(
        r'(abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)',
        caseSensitive: false,
      ),
    )) {
      //penalización por secuencias alfabéticas
      penalties++; 
    }
    if (password.toLowerCase().contains('password') ||
        password.toLowerCase().contains('123456') ||
        password.toLowerCase().contains('qwerty')) {
      //penalización por palabras comunes, agregale más
      penalties += 2;
    }

    final finalScore = score + bonusPoints - penalties;

    if (finalScore <= 2) return PasswordStrength.veryWeak;
    if (finalScore <= 4) return PasswordStrength.weak;
    if (finalScore <= 6) return PasswordStrength.medium;
    if (finalScore <= 8) return PasswordStrength.strong;
    //9+ puntos
    return PasswordStrength.veryStrong;
  }

  static String getStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return 'Muy débil';
      case PasswordStrength.weak:
        return 'Débil';
      case PasswordStrength.medium:
        return 'Media';
      case PasswordStrength.strong:
        return 'Fuerte';
      case PasswordStrength.veryStrong:
        return 'Muy fuerte';
    }
  }

  static List<String> getPasswordSuggestions(String password) {
    final suggestions = <String>[];

    if (password.length < 8) {
      suggestions.add('Usa al menos 8 caracteres');
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      suggestions.add('Incluye letras minúsculas');
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      suggestions.add('Incluye letras mayúsculas');
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      suggestions.add('Incluye números');
    }

    if (!password.contains(RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]'))) {
      suggestions.add('Incluye símbolos especiales');
    }

    if (password.contains(RegExp(r'(.)\1{2,}'))) {
      suggestions.add('Evita caracteres repetidos');
    }

    return suggestions;
  }
}

enum PasswordStrength { veryWeak, weak, medium, strong, veryStrong }
