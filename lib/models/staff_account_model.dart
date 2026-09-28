/// Peran untuk akun staff internal PediaGrow.
///
/// Akun staff internal hanya dapat dibuat oleh
/// PMIK Superadmin dan tidak memiliki pendaftaran mandiri.
enum StaffRole {
  admin, // PMIK
  dokter;

  /// Label tampilan yang enak dibaca untuk UI.
  String get label {
    switch (this) {
      case StaffRole.admin:
        return 'PMIK';
      case StaffRole.dokter:
        return 'Dokter';
    }
  }

  /// Mengubah string dari Firestore menjadi enum StaffRole.
  static StaffRole fromString(String value) {
    return StaffRole.values.firstWhere(
      (r) => r.name == value,
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

/// Model data untuk satu akun staff.
///
/// Staff dapat berupa:
/// - PMIK biasa
/// - PMIK Superadmin
/// - Dokter
class StaffAccount {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final StaffRole role;

  /// Hanya digunakan untuk role PMIK.
  ///
  /// Untuk dokter nilainya PmikLevel.biasa secara default
  /// dan tidak digunakan sebagai hak akses PMIK.
  final PmikLevel pmikLevel;

  final String createdBy;
  final DateTime? createdAt;
  final bool isActive;

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
  });

  /// Apakah akun ini merupakan PMIK?
  bool get isPmik => role == StaffRole.admin;

  /// Apakah akun ini merupakan PMIK Superadmin?
  bool get isPmikSuperadmin =>
      role == StaffRole.admin && pmikLevel == PmikLevel.superadmin;

  /// Apakah akun ini merupakan PMIK biasa?
  bool get isPmikBiasa =>
      role == StaffRole.admin && pmikLevel == PmikLevel.biasa;

  /// Apakah akun ini merupakan dokter?
  bool get isDokter => role == StaffRole.dokter;

  /// Membuat objek StaffAccount dari data Firestore.
  factory StaffAccount.fromMap(String id, Map<String, dynamic> map) {
    return StaffAccount(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      passwordHash: map['passwordHash'] as String? ?? '',
      role: StaffRole.fromString(map['role'] as String? ?? 'dokter'),
      pmikLevel: PmikLevel.fromString(map['pmikLevel'] as String? ?? 'biasa'),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
      isActive: map['isActive'] as bool? ?? true,
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
    };
  }
}
