import '../entities/password_entry.dart';

abstract class PasswordRepository {
  Future<List<PasswordEntry>> getAllPasswords();
  Future<List<PasswordEntry>> getFavoritePasswords();
  Future<List<PasswordEntry>> searchPasswords(String query);
  Future<PasswordEntry?> getPasswordById(String id);
  Future<void> createPassword(PasswordEntry password);
  Future<void> updatePassword(PasswordEntry password);
  Future<void> deletePassword(String id);
}
