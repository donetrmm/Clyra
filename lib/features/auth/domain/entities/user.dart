class User {
  final String id;
  final String email;
  final String masterPasswordHash;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool biometricEnabled;

  const User({
    required this.id,
    required this.email,
    required this.masterPasswordHash,
    required this.createdAt,
    required this.lastLoginAt,
    this.biometricEnabled = false,
  });

  User copyWith({
    String? id,
    String? email,
    String? masterPasswordHash,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? biometricEnabled,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      masterPasswordHash: masterPasswordHash ?? this.masterPasswordHash,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, email: $email)';
  }
}
