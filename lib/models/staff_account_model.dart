/// Peran (role) untuk akun staff internal PediaGrow.
///
/// Berbeda dari pengguna masyarakat biasa (yang bisa daftar sendiri
/// lewat email/Google), akun dengan role ini HANYA bisa dibuat
/// oleh Superadmin — tidak ada pendaftaran mandiri.
enum StaffRole {
  superadmin,
  admin, // PMIK
  dokter;

  /// Label tampilan yang enak dibaca (untuk UI).
  String get label {
    switch (this) {
      case StaffRole.superadmin:
        return 'Superadmin';
      case StaffRole.admin:
        return 'Admin (PMIK)';
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

/// Model data untuk satu akun staff (superadmin/admin/dokter).
class StaffAccount {
  final String id; // ID dokumen Firestore
  final String name;
  final String email;
  final String passwordHash;
  final StaffRole role;
  final String createdBy; // email superadmin yang membuat akun ini
  final DateTime? createdAt;
  final bool isActive;

  const StaffAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.createdBy,
    this.createdAt,
    this.isActive = true,
  });

  /// Membuat objek StaffAccount dari data Firestore (Map).
  factory StaffAccount.fromMap(String id, Map<String, dynamic> map) {
    return StaffAccount(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      passwordHash: map['passwordHash'] as String? ?? '',
      role: StaffRole.fromString(map['role'] as String? ?? 'dokter'),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  /// Mengubah objek ini menjadi Map untuk disimpan ke Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'role': role.name,
      'createdBy': createdBy,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'isActive': isActive,
    };
  }
}
