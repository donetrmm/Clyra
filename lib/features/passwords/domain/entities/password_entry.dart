class PasswordEntry {
  final String id;
  final String title;
  final String username;
  final String password;
  final String? website;
  final String? notes;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  const PasswordEntry({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    this.website,
    this.notes,
    this.category,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  PasswordEntry copyWith({
    String? id,
    String? title,
    String? username,
    String? password,
    String? website,
    String? notes,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PasswordEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PasswordEntry(id: $id, title: $title, username: $username)';
  }
}
