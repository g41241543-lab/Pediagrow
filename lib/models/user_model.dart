class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarPath;
  final String? phone;
  final String? gender;
  final String? birthDate;
  final String? province;
  final String? city;
  final String? district;
  final String? subDistrict;
  final String? passwordHash;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarPath,
    this.phone,
    this.gender,
    this.birthDate,
    this.province,
    this.city,
    this.district,
    this.subDistrict,
    this.passwordHash,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarPath,
    String? phone,
    String? gender,
    String? birthDate,
    String? province,
    String? city,
    String? district,
    String? subDistrict,
    String? passwordHash,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      province: province ?? this.province,
      city: city ?? this.city,
      district: district ?? this.district,
      subDistrict: subDistrict ?? this.subDistrict,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarPath': avatarPath,
      'phone': phone,
      'gender': gender,
      'birthDate': birthDate,
      'province': province,
      'city': city,
      'district': district,
      'subDistrict': subDistrict,
      'passwordHash': passwordHash,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatarPath: map['avatarPath'] as String?,
      phone: map['phone'] as String?,
      gender: map['gender'] as String?,
      birthDate: map['birthDate'] as String?,
      province: map['province'] as String?,
      city: map['city'] as String?,
      district: map['district'] as String?,
      subDistrict: map['subDistrict'] as String?,
      passwordHash: map['passwordHash'] as String?,
    );
  }
}
