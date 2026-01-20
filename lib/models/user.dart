class User {
  final String idUser;
  final String fullname;
  final String username;
  final String password;
  final String role; 
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.idUser,
    required this.fullname,
    required this.username,
    required this.password,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_user': idUser,
      'fullname': fullname,
      'username': username,
      'password': password,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      idUser: map['id_user'],
      fullname: map['fullname'],
      username: map['username'],
      password: map['password'],
      role: map['role'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  User copyWith({
    String? idUser,
    String? fullname,
    String? username,
    String? password,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      idUser: idUser ?? this.idUser,
      fullname: fullname ?? this.fullname,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
