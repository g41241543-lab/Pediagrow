class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarPath;
  final String? phone;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarPath,
    this.phone,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarPath,
    String? phone,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarPath': avatarPath,
      'phone': phone,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatarPath: map['avatarPath'] as String?,
      phone: map['phone'] as String?,
    );
  }
}
