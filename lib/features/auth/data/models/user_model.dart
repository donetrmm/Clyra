import 'dart:convert';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.masterPasswordHash,
    required super.createdAt,
    required super.lastLoginAt,
    super.biometricEnabled,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      masterPasswordHash: json['master_password_hash'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: DateTime.parse(json['last_login_at'] as String),
      biometricEnabled: (json['biometric_enabled'] as int) == 1,
    );
  }

  factory UserModel.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return UserModel.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'master_password_hash': masterPasswordHash,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt.toIso8601String(),
      'biometric_enabled': biometricEnabled ? 1 : 0,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory UserModel.fromEntity(User entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      masterPasswordHash: entity.masterPasswordHash,
      createdAt: entity.createdAt,
      lastLoginAt: entity.lastLoginAt,
      biometricEnabled: entity.biometricEnabled,
    );
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      masterPasswordHash: masterPasswordHash,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      biometricEnabled: biometricEnabled,
    );
  }

  @override
  UserModel copyWith({
    String? id,
    String? email,
    String? masterPasswordHash,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? biometricEnabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      masterPasswordHash: masterPasswordHash ?? this.masterPasswordHash,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}
