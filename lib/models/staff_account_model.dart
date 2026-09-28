import 'doctor_permissions.dart';

/// Peran (role) untuk akun staff internal PediaGrow.
///
/// Akun staff internal hanya dapat dibuat oleh
/// PMIK Superadmin dan tidak memiliki pendaftaran mandiri.
enum StaffRole {
  superadmin,
  admin, // PMIK
  dokter;

  /// Label tampilan yang enak dibaca untuk UI.
  String get label {
    switch (this) {
      case StaffRole.superadmin:
        return 'Superadmin';
      case StaffRole.admin:
        return 'PMIK';
      case StaffRole.dokter:
        return 'Dokter';
    }
  }

  /// Mengubah string dari Firestore menjadi enum StaffRole.
  static StaffRole fromString(String value) {
    final clean = value
        .trim()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '');
    if (clean == 'superadmin' || clean == 'pmiksuperadmin') {
      return StaffRole.superadmin;
    }
    if (clean == 'admin' || clean == 'pmik') {
      return StaffRole.admin;
    }
    if (clean == 'dokter' || clean == 'doctor') {
      return StaffRole.dokter;
    }
    return StaffRole.values.firstWhere(
      (r) => r.name.toLowerCase() == clean,
      orElse: () => StaffRole.dokter,
    );
  }
}

/// Tingkat kewenangan untuk akun PMIK.
///
/// PMIK memiliki dua tingkat:
/// - biasa
/// - superadmin
enum PmikLevel {
  biasa,
  superadmin;

  /// Label tampilan untuk UI.
  String get label {
    switch (this) {
      case PmikLevel.biasa:
        return 'PMIK';
      case PmikLevel.superadmin:
        return 'PMIK Superadmin';
    }
  }

  /// Mengubah string dari Firestore menjadi enum PmikLevel.
  static PmikLevel fromString(String value) {
    return PmikLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => PmikLevel.biasa,
    );
  }
}

/// Model data untuk satu akun staff (superadmin/admin/dokter).
class StaffAccount {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final StaffRole role;

  /// Tingkat PMIK (biasa atau superadmin).
  final PmikLevel pmikLevel;

  final String createdBy;
  final DateTime? createdAt;
  final bool isActive;
  final Map<String, bool> permissions;
  final String? avatarPath;
  final String? experience;
  final String? strNumber;
  final String? birthDate;
  final String? education;
  final Map<String, dynamic>? additionalInfo;

  const StaffAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.pmikLevel = PmikLevel.biasa,
    required this.createdBy,
    this.createdAt,
    this.isActive = true,
    this.permissions = const {},
    this.avatarPath,
    this.experience,
    this.strNumber,
    this.birthDate,
    this.education,
    this.additionalInfo,
  });

  /// Apakah akun ini merupakan PMIK?
  bool get isPmik => role == StaffRole.admin;

  /// Apakah akun ini merupakan PMIK Superadmin?
  bool get isPmikSuperadmin => isSuperAdmin;

  /// Apakah akun ini merupakan PMIK biasa?
  bool get isPmikBiasa =>
      role == StaffRole.admin && !isSuperAdmin;

  /// Apakah akun ini merupakan dokter?
  bool get isDokter => role == StaffRole.dokter;

  /// Membuat objek StaffAccount dari data Firestore.
  factory StaffAccount.fromMap(String id, Map<String, dynamic> map) {
    Map<String, bool> parsedPermissions = {};
    if (map['permissions'] is Map) {
      parsedPermissions = (map['permissions'] as Map).map(
        (key, value) => MapEntry(key.toString(), value == true),
      );
    } else if (map['hak_akses'] is Map) {
      parsedPermissions = (map['hak_akses'] as Map).map(
        (key, value) => MapEntry(key.toString(), value == true),
      );
    }

    // Jika email mengandung superadmin, pastikan role adalah superadmin
    final rawEmail = (map['email'] as String? ?? '').trim().toLowerCase();
    var role = StaffRole.fromString(map['role'] as String? ?? 'dokter');
    if (rawEmail.contains('superadmin') || rawEmail == 'superadmin@pediagrow.com') {
      role = StaffRole.superadmin;
    }

    // Jika dokter dan belum ada permission, gunakan default
    if (role == StaffRole.dokter && parsedPermissions.isEmpty) {
      parsedPermissions = DoctorPermissions.defaultPermissions;
    }

    Map<String, dynamic>? addInfo;
    if (map['additionalInfo'] is Map) {
      addInfo = Map<String, dynamic>.from(map['additionalInfo'] as Map);
    }

    final rawPmikLevel = map['pmikLevel'] as String?;
    final defaultPmikLevel =
        (role == StaffRole.superadmin) ? PmikLevel.superadmin : PmikLevel.biasa;

    return StaffAccount(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      passwordHash: map['passwordHash'] as String? ?? '',
      role: role,
      pmikLevel: rawPmikLevel != null
          ? PmikLevel.fromString(rawPmikLevel)
          : defaultPmikLevel,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
      isActive: map['isActive'] as bool? ?? true,
      permissions: parsedPermissions,
      avatarPath: map['avatarPath'] as String? ?? map['avatar_url'] as String?,
      experience: map['experience']?.toString() ?? map['experienceYears']?.toString(),
      strNumber: map['strNumber']?.toString() ?? map['str_number']?.toString(),
      birthDate: map['birthDate']?.toString() ?? map['birth_date']?.toString(),
      education: map['education']?.toString(),
      additionalInfo: addInfo,
    );
  }

  /// Mengubah objek menjadi Map untuk Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'role': role.name,
      'pmikLevel': pmikLevel.name,
      'createdBy': createdBy,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'isActive': isActive,
      'permissions': permissions,
      'avatarPath': avatarPath,
      'experience': experience,
      'strNumber': strNumber,
      'birthDate': birthDate,
      'education': education,
      if (additionalInfo != null) 'additionalInfo': additionalInfo,
    };
  }

  StaffAccount copyWith({
    String? id,
    String? name,
    String? email,
    String? passwordHash,
    StaffRole? role,
    PmikLevel? pmikLevel,
    String? createdBy,
    DateTime? createdAt,
    bool? isActive,
    Map<String, bool>? permissions,
    String? avatarPath,
    String? experience,
    String? strNumber,
    String? birthDate,
    String? education,
    Map<String, dynamic>? additionalInfo,
  }) {
    return StaffAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      pmikLevel: pmikLevel ?? this.pmikLevel,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
      avatarPath: avatarPath ?? this.avatarPath,
      experience: experience ?? this.experience,
      strNumber: strNumber ?? this.strNumber,
      birthDate: birthDate ?? this.birthDate,
      education: education ?? this.education,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  /// Cek apakah akun ini adalah Superadmin (baik dari role, email, atau hak_akses)
  bool get isSuperAdmin {
    if (role == StaffRole.superadmin) return true;
    if (pmikLevel == PmikLevel.superadmin) return true;
    if (email.trim().toLowerCase().contains('superadmin')) return true;
    if (email.trim().toLowerCase() == 'superadmin@pediagrow.com') return true;
    if (permissions['hak_akses'] == true) return true;
    return false;
  }

  /// Label peran PMIK: jika hak akses 'hak_akses' bernilai true, menjadi PMIK (SUPER ADMIN)
  String get pmikRoleDisplay {
    if (isSuperAdmin) return 'SUPERADMIN';
    if (permissions['hak_akses'] == true) {
      return 'PMIK (SUPER ADMIN)';
    }
    return 'PMIK';
  }

  /// Mengecek apakah staf memiliki hak akses untuk fitur tertentu
  bool hasPermission(String permissionKey) {
    if (isSuperAdmin) return true;
    if (permissions.isEmpty) return true;
    return permissions[permissionKey] ?? false;
  }
}
