import '../../domain/entities/password_entry.dart';
import '../../domain/repositories/password_repository.dart';
import '../datasources/local/password_local_datasource.dart';
import '../models/password_entry_model.dart';

class PasswordRepositoryImpl implements PasswordRepository {
  final PasswordLocalDataSource _localDataSource;

  PasswordRepositoryImpl({required PasswordLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  @override
  Future<List<PasswordEntry>> getAllPasswords() async {
    final passwordModels = await _localDataSource.getAllPasswords();
    return passwordModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<PasswordEntry>> getFavoritePasswords() async {
    final passwordModels = await _localDataSource.getFavoritePasswords();
    return passwordModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<PasswordEntry>> searchPasswords(String query) async {
    final passwordModels = await _localDataSource.searchPasswords(query);
    return passwordModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<PasswordEntry?> getPasswordById(String id) async {
    final passwordModel = await _localDataSource.getPasswordById(id);
    return passwordModel?.toEntity();
  }

  @override
  Future<void> createPassword(PasswordEntry password) async {
    final passwordModel = PasswordEntryModel.fromEntity(password);
    await _localDataSource.insertPassword(passwordModel);
  }

  @override
  Future<void> updatePassword(PasswordEntry password) async {
    final passwordModel = PasswordEntryModel.fromEntity(password);
    await _localDataSource.updatePassword(passwordModel);
  }

  @override
  Future<void> deletePassword(String id) async {
    await _localDataSource.deletePassword(id);
  }
}
