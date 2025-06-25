class User {
  final String id;
  final String email;
  final String name;
  final String phone;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? profileImagePath; // Tambahkan properti foto profil

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.createdAt,
    this.lastLogin,
    this.profileImagePath,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'profileImagePath': profileImagePath,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
      profileImagePath: json['profileImagePath'],
    );
  }
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? profileImagePath,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}
