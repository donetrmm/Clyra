import 'package:uuid/uuid.dart';
import '../../../../core/viewmodel/base_viewmodel.dart';
import '../../../../utils/generators/password_generator_service.dart';
import '../../domain/entities/password_entry.dart';
import '../../domain/repositories/password_repository.dart';
import '../../data/models/password_entry_model.dart';

class PasswordViewModel extends BaseViewModel {
  final PasswordRepository _passwordRepository;
  final Uuid _uuid = const Uuid();

  PasswordViewModel({required PasswordRepository passwordRepository})
    : _passwordRepository = passwordRepository;

  List<PasswordEntry> _passwords = [];
  List<PasswordEntry> _filteredPasswords = [];
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  List<PasswordEntry> get passwords => _filteredPasswords;
  String get searchQuery => _searchQuery;
  bool get showFavoritesOnly => _showFavoritesOnly;
  bool get hasPasswords => _passwords.isNotEmpty;

  bool get hasCorruptedPasswords {
    return _passwords.any((password) {
      if (password is PasswordEntryModel) {
        return password.isCorrupted;
      }
      return false;
    });
  }

  List<PasswordEntry> get corruptedPasswords {
    return _passwords.where((password) {
      if (password is PasswordEntryModel) {
        return password.isCorrupted;
      }
      return false;
    }).toList();
  }

  Future<void> loadPasswords() async {
    await runAsyncOperation(() async {
      _passwords = await _passwordRepository.getAllPasswords();
      _applyFilters();
    });
  }

  Future<void> loadFavoritePasswords() async {
    await runAsyncOperation(() async {
      _passwords = await _passwordRepository.getFavoritePasswords();
      _filteredPasswords = _passwords;
      notifyListeners();
    });
  }

  void searchPasswords(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void toggleFavoritesFilter() {
    _showFavoritesOnly = !_showFavoritesOnly;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredPasswords =
        _passwords.where((password) {
          final matchesSearch =
              _searchQuery.isEmpty ||
              password.title.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              password.username.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              (password.website?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false);

          final matchesFavorites = !_showFavoritesOnly || password.isFavorite;

          return matchesSearch && matchesFavorites;
        }).toList();

    notifyListeners();
  }

  Future<void> createPassword({
    required String title,
    required String username,
    required String password,
    String? website,
    String? notes,
    String? category,
  }) async {
    await runAsyncOperation(() async {
      final now = DateTime.now();
      final passwordEntry = PasswordEntry(
        id: _uuid.v4(),
        title: title,
        username: username,
        password: password,
        website: website,
        notes: notes,
        category: category,
        createdAt: now,
        updatedAt: now,
      );

      await _passwordRepository.createPassword(passwordEntry);
      await loadPasswords();
    });
  }

  Future<void> updatePassword(PasswordEntry password) async {
    await runAsyncOperation(() async {
      final updatedPassword = password.copyWith(updatedAt: DateTime.now());
      await _passwordRepository.updatePassword(updatedPassword);
      await loadPasswords();
    });
  }

  Future<void> toggleFavorite(String passwordId) async {
    await runAsyncOperation(() async {
      final password = _passwords.firstWhere((p) => p.id == passwordId);
      final updatedPassword = password.copyWith(
        isFavorite: !password.isFavorite,
        updatedAt: DateTime.now(),
      );
      await _passwordRepository.updatePassword(updatedPassword);
      await loadPasswords();
    });
  }

  Future<void> deletePassword(String passwordId) async {
    await runAsyncOperation(() async {
      await _passwordRepository.deletePassword(passwordId);
      await loadPasswords();
    });
  }

  String generatePassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
    bool excludeSimilar = false,
  }) {
    return PasswordGeneratorService.generatePassword(
      length: length,
      includeUppercase: includeUppercase,
      includeLowercase: includeLowercase,
      includeNumbers: includeNumbers,
      includeSymbols: includeSymbols,
      excludeSimilar: excludeSimilar,
    );
  }

  PasswordStrength checkPasswordStrength(String password) {
    return PasswordGeneratorService.checkPasswordStrength(password);
  }

  String getPasswordStrengthText(PasswordStrength strength) {
    return PasswordGeneratorService.getStrengthText(strength);
  }

  List<String> getPasswordSuggestions(String password) {
    return PasswordGeneratorService.getPasswordSuggestions(password);
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
  }

  void clearFilters() {
    _searchQuery = '';
    _showFavoritesOnly = false;
    _applyFilters();
  }
}
