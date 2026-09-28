class UserModel {
  final String id;
  final String name;
  final String? username;
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
    this.username,
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

  /// Nama/username untuk teks sapaan di header Beranda ("Hai, <greetingName>")
  String get greetingName {
    // 1. Prioritaskan username jika ada
    if (username != null && username!.trim().isNotEmpty) {
      return username!.trim();
    }
    // 2. Jika tidak ada username khusus, gunakan nama pengguna
    if (name.trim().isNotEmpty && name.trim().toLowerCase() != 'tamu') {
      return name.trim();
    }
    // 3. Jika nama kosong/tamu, gunakan bagian sebelum @ pada email
    if (email.trim().isNotEmpty) {
      return email.trim().split('@').first;
    }
    // 4. Fallback default
    return 'Susanti';
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
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
      username: username ?? this.username,
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
      if (username != null) 'username': username,
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
    final rawUsername = (map['username'] ?? map['user_name'])?.toString();
    final rawName = (map['name'] ??
            map['nama'] ??
            map['fullName'] ??
            map['full_name'] ??
            map['displayName'] ??
            rawUsername ??
            '')
        .toString();

    return UserModel(
      id: map['id']?.toString() ?? '',
      name: rawName,
      username: rawUsername,
      email: map['email']?.toString() ?? '',
      avatarPath: (map['avatarPath'] ?? map['avatar_url'] ?? map['photoUrl'])?.toString(),
      phone: (map['phone'] ?? map['nomor_telepon'] ?? map['no_hp'])?.toString(),
      gender: map['gender']?.toString(),
      birthDate: (map['birthDate'] ?? map['tanggal_lahir'])?.toString(),
      province: map['province']?.toString(),
      city: map['city']?.toString(),
      district: map['district']?.toString(),
      subDistrict: map['subDistrict']?.toString(),
      passwordHash: (map['passwordHash'] ?? map['password'])?.toString(),
    );
  }
}
