import '../../domain/entities/password_entry.dart';

class PasswordEntryModel extends PasswordEntry {
  const PasswordEntryModel({
    required super.id,
    required super.title,
    required super.username,
    required super.password,
    super.website,
    super.notes,
    super.category,
    required super.createdAt,
    required super.updatedAt,
    super.isFavorite,
  });

  factory PasswordEntryModel.fromJson(Map<String, dynamic> json) {
    return PasswordEntryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      website: json['website'] as String?,
      notes: json['notes'] as String?,
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isFavorite: (json['is_favorite'] as int) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'website': website,
      'notes': notes,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory PasswordEntryModel.fromEntity(PasswordEntry entity) {
    return PasswordEntryModel(
      id: entity.id,
      title: entity.title,
      username: entity.username,
      password: entity.password,
      website: entity.website,
      notes: entity.notes,
      category: entity.category,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isFavorite: entity.isFavorite,
    );
  }

  PasswordEntry toEntity() {
    return PasswordEntry(
      id: id,
      title: title,
      username: username,
      password: password,
      website: website,
      notes: notes,
      category: category,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isFavorite: isFavorite,
    );
  }

  bool get isCorrupted {
    return password.contains('[DATOS CORRUPTOS');
  }
}
