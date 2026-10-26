import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/staff_account_model.dart';
import '../../models/doctor_permissions.dart';
import 'session_service.dart';
import 'storage_service.dart';
import 'superadmin_notification_service.dart';

/// Service untuk mengelola login dan akun staff internal PediaGrow.
///
/// Jenis akun staff:
/// - PMIK biasa
/// - PMIK Superadmin
/// - Dokter
///
/// Akun staff tidak memiliki pendaftaran mandiri.
/// Akun dibuat oleh PMIK Superadmin.
class StaffAuthService {
  static final StaffAuthService _instance = StaffAuthService._internal();

  factory StaffAuthService() => _instance;

  StaffAuthService._internal();

  static const String _collection = 'staff_accounts';

  /// Akun PMIK Superadmin bawaan sistem.
  static const String defaultSuperadminEmail = 'superadmin@pediagrow.com';
  static const String defaultSuperadminPassword = 'Superadmin123!';

  /// Akun Dokter bawaan sistem.
  static const String defaultDokterEmail = 'dokter@pediagrow.com';
  static const String defaultDokterPassword = 'Dokter123!';

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  /// Staff yang sedang login.
  ///
  /// null = tidak ada staff yang login.
  final ValueNotifier<StaffAccount?> currentStaffNotifier =
      ValueNotifier<StaffAccount?>(null);

  StaffAccount? get currentStaff => currentStaffNotifier.value;

  /// Keluar dari sesi staff.
  void logout() {
    currentStaffNotifier.value = null;
    SessionService().clearSession();
  }

  /// Mengatur akun staf aktif yang dipulihkan dari sesi.
  void setStaff(StaffAccount staff) {
    currentStaffNotifier.value = staff;
  }

  /// Pesan error terakhir saat login gagal untuk diagnostik UI.
  String? lastLoginError;

  /// Akun default superadmin untuk fallback offline/darurat.
  StaffAccount _createDefaultSuperadminAccount() {
    return StaffAccount(
      id: 'superadmin_default',
      name: 'Superadmin PediaGrow',
      email: defaultSuperadminEmail,
      passwordHash: _hashPassword(defaultSuperadminPassword),
      role: StaffRole.superadmin,
      pmikLevel: PmikLevel.superadmin,
      createdBy: 'system',
      createdAt: DateTime.now(),
      isActive: true,
      permissions: const {'hak_akses': true},
    );
  }

  /// Akun default dokter untuk fallback offline/darurat.
  StaffAccount _createDefaultDokterAccount() {
    return StaffAccount(
      id: 'dokter_default',
      name: 'dr. Reny, Sp.A',
      email: defaultDokterEmail,
      passwordHash: _hashPassword(defaultDokterPassword),
      role: StaffRole.dokter,
      pmikLevel: PmikLevel.biasa,
      createdBy: 'system',
      createdAt: DateTime.now(),
      isActive: true,
      permissions: DoctorPermissions.defaultPermissions,
      additionalInfo: const {
        'spesialisasi': 'Spesialis Anak',
      },
    );
  }

  /// Mengambil data staf dari Firestore berdasarkan document ID.
  Future<StaffAccount?> getStaffById(String id) async {
    if (id == 'superadmin_default') {
      return _createDefaultSuperadminAccount();
    }
    if (id == 'dokter_default') {
      return _createDefaultDokterAccount();
    }
    try {
      final db = _db;
      if (db == null || id.isEmpty) return null;

      final doc = await db.collection(_collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return StaffAccount.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('[StaffAuthService] getStaffById error: $e');
      return null;
    }
  }

  // ============================================================
  // CEK EMAIL STAFF
  // ============================================================

  /// Mengecek apakah email sudah terdaftar sebagai akun staff.
  ///
  /// Akun aktif maupun tidak aktif tetap dianggap sudah terdaftar.
  Future<bool> isStaffEmail(String email) async {
    try {
      final normalized = email.trim().toLowerCase();
      if (normalized == defaultSuperadminEmail.toLowerCase() ||
          normalized.contains('superadmin') ||
          normalized == defaultDokterEmail.toLowerCase() ||
          normalized.contains('dokter')) {
        return true;
      }

      final db = _db;
      if (db == null) return false;

      final query = await db
          .collection(_collection)
          .where('email', isEqualTo: normalized)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('[StaffAuthService] isStaffEmail error: $e');

      return false;
    }
  }

  // ============================================================
  // PASSWORD HASH
  // ============================================================

  String _hashPassword(String rawPassword) {
    final bytes = utf8.encode(rawPassword);

    return sha256.convert(bytes).toString();
  }

  // ============================================================
  // SEED PMIK SUPERADMIN
  // ============================================================

  /// Memastikan minimal ada satu akun PMIK Superadmin di Firestore.
  Future<void> ensureSuperadminSeeded() async {
    try {
      final db = _db;
      if (db == null) return;

      final query = await db
          .collection(_collection)
          .where('email', isEqualTo: defaultSuperadminEmail.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return;
      }

      await db.collection(_collection).add(
            StaffAccount(
              id: '',
              name: 'Superadmin PediaGrow',
              email: defaultSuperadminEmail,
              passwordHash: _hashPassword(defaultSuperadminPassword),
              role: StaffRole.superadmin,
              pmikLevel: PmikLevel.superadmin,
              createdBy: 'system',
              createdAt: DateTime.now(),
            ).toMap(),
          );
      debugPrint(
        '[StaffAuthService] Akun superadmin default dibuat: '
        '$defaultSuperadminEmail / $defaultSuperadminPassword',
      );
    } catch (e) {
      debugPrint('[StaffAuthService] Gagal seeding PMIK Superadmin: $e');
    }
  }

  /// Memastikan minimal ada satu akun Dokter di Firestore untuk demo / pengujian.
  Future<void> ensureDokterSeeded() async {
    try {
      final db = _db;
      if (db == null) return;

      final query = await db
          .collection(_collection)
          .where('email', isEqualTo: defaultDokterEmail.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return;
      }

      final newStaffRef = await db.collection(_collection).add(
            StaffAccount(
              id: '',
              name: 'dr. Reny, Sp.A',
              email: defaultDokterEmail,
              passwordHash: _hashPassword(defaultDokterPassword),
              role: StaffRole.dokter,
              pmikLevel: PmikLevel.biasa,
              createdBy: 'system',
              createdAt: DateTime.now(),
              permissions: DoctorPermissions.defaultPermissions,
              additionalInfo: {
                'spesialisasi': 'Spesialis Anak',
              },
            ).toMap(),
          );

      // Pastikan profil dokter di collection 'doctors' juga tersedia dan terhubung
      final docQuery = await db
          .collection('doctors')
          .where('email', isEqualTo: defaultDokterEmail.toLowerCase())
          .limit(1)
          .get();

      if (docQuery.docs.isEmpty) {
        await db.collection('doctors').add({
          'name': 'dr. Reny, Sp. A',
          'specialization': 'Spesialis Anak',
          'email': defaultDokterEmail,
          'experience_years': 8,
          'str_number': 'STR-33.1.1.100.2.20.123456',
          'places_of_practice': [
            'RSIA PediaGrow',
            'Praktek Mandiri',
          ],
          'hospital': 'RSIA PediaGrow',
          'staff_account_id': newStaffRef.id,
          'is_online': true,
        });
      }

      debugPrint(
        '[StaffAuthService] Akun dokter default dibuat: '
        '$defaultDokterEmail / $defaultDokterPassword',
      );
    } catch (e) {
      debugPrint('[StaffAuthService] Gagal seeding Dokter: $e');
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  /// Login staff menggunakan email dan password.
  ///
  /// Jenis akun yang dapat login:
  /// - PMIK biasa
  /// - PMIK Superadmin
  /// - Dokter
  Future<StaffAccount?> login(String email, String password) async {
    lastLoginError = null;
    final normalizedEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    final bool isDefaultSuperadmin =
        normalizedEmail == defaultSuperadminEmail.toLowerCase() &&
            cleanPassword == defaultSuperadminPassword;
    final bool isDefaultDokter =
        normalizedEmail == defaultDokterEmail.toLowerCase() &&
            cleanPassword == defaultDokterPassword;

    try {
      final db = _db;
      if (db == null) {
        if (isDefaultSuperadmin) {
          final account = _createDefaultSuperadminAccount();
          currentStaffNotifier.value = account;
          return account;
        }
        if (isDefaultDokter) {
          final account = _createDefaultDokterAccount();
          currentStaffNotifier.value = account;
          return account;
        }
        lastLoginError = 'Koneksi database Firestore tidak tersedia.';
        return null;
      }

      var query = await db
          .collection(_collection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (query.docs.isEmpty &&
          normalizedEmail == defaultSuperadminEmail.toLowerCase()) {
        await ensureSuperadminSeeded();
        query = await db
            .collection(_collection)
            .where('email', isEqualTo: normalizedEmail)
            .limit(1)
            .get();
      }

      if (query.docs.isEmpty &&
          (normalizedEmail == defaultDokterEmail.toLowerCase() ||
              normalizedEmail == 'dokter@pediagrow.com')) {
        await ensureDokterSeeded();
        query = await db
            .collection(_collection)
            .where('email', isEqualTo: normalizedEmail)
            .limit(1)
            .get();
      }

      if (query.docs.isEmpty) {
        if (isDefaultSuperadmin) {
          final account = _createDefaultSuperadminAccount();
          currentStaffNotifier.value = account;
          return account;
        }
        if (isDefaultDokter) {
          final account = _createDefaultDokterAccount();
          currentStaffNotifier.value = account;
          return account;
        }
        lastLoginError = 'Akun staf dengan email ini belum terdaftar.';
        return null;
      }

      final doc = query.docs.first;
      var account = StaffAccount.fromMap(doc.id, doc.data());

      final inputHash = _hashPassword(password);
      final cleanInputHash = _hashPassword(cleanPassword);

      // Verifikasi kecocokan kata sandi:
      // 1. Hash cocok (baik raw maupun trimmed)
      // 2. Data di Firestore tersimpan plain-text
      // 3. Kredensial default bawaan superadmin / dokter cocok
      final bool isPasswordValid = inputHash == account.passwordHash ||
          cleanInputHash == account.passwordHash ||
          password == account.passwordHash ||
          cleanPassword == account.passwordHash ||
          isDefaultSuperadmin ||
          isDefaultDokter;

      if (!isPasswordValid) {
        lastLoginError =
            'Kata sandi salah. Perhatikan huruf kapital dan tanda baca.';
        return null;
      }

      // Jika akun default superadmin login dengan kredensial default yang valid,
      // pulihkan status aktif dan perbaiki hash jika sebelumnya mismatch di database
      if (isDefaultSuperadmin) {
        if (account.passwordHash != cleanInputHash || !account.isActive) {
          try {
            await db.collection(_collection).doc(doc.id).update({
              'passwordHash': cleanInputHash,
              'isActive': true,
              'role': StaffRole.superadmin.name,
              'pmikLevel': PmikLevel.superadmin.name,
            });
            account = account.copyWith(
              passwordHash: cleanInputHash,
              isActive: true,
              role: StaffRole.superadmin,
              pmikLevel: PmikLevel.superadmin,
            );
          } catch (_) {}
        }
      }

      // Akun yang tidak aktif tidak dapat login (kecuali superadmin default yang dipulihkan di atas).
      if (!account.isActive) {
        lastLoginError =
            'Akun staf berstatus nonaktif. Silakan hubungi Superadmin.';
        return null;
      }

      // Jika email adalah superadmin atau memiliki hak_akses, pastikan rolenya superadmin
      if (account.isSuperAdmin && account.role != StaffRole.superadmin) {
        account = account.copyWith(role: StaffRole.superadmin);
      }

      // Simpan staff yang sedang login.
      currentStaffNotifier.value = account;

      return account;
    } catch (e) {
      debugPrint('[StaffAuthService] login error: $e');

      // Fallback tanggap darurat jika Firestore memicu error (permission-denied / offline / timeout)
      if (isDefaultSuperadmin) {
        final account = _createDefaultSuperadminAccount();
        currentStaffNotifier.value = account;
        return account;
      }
      if (isDefaultDokter) {
        final account = _createDefaultDokterAccount();
        currentStaffNotifier.value = account;
        return account;
      }

      final errorStr = e.toString();
      if (errorStr.contains('permission-denied')) {
        lastLoginError =
            'Akses Firestore ditolak (Permission Denied). Periksa Security Rules Firebase Console.';
      } else if (errorStr.contains('unavailable') ||
          errorStr.toLowerCase().contains('network')) {
        lastLoginError =
            'Gagal terhubung ke database. Periksa koneksi internet Anda.';
      } else {
        lastLoginError = 'Gagal masuk akun staf: $e';
      }

      return null;
    }
  }

  // ============================================================
  // MEMBUAT AKUN STAFF
  // ============================================================

  /// Dipanggil oleh Superadmin untuk membuat akun PMIK (admin) atau Dokter baru.
  /// Mengembalikan ID akun baru, atau null kalau gagal.
  Future<String?> createStaffAccount({
    required String name,
    required String email,
    required String password,
    required StaffRole role,
    required String createdByEmail,
    Map<String, bool>? permissions,
    String? avatarPath,
    String? experience,
    String? strNumber,
    String? birthDate,
    String? education,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final db = _db;
      if (db == null) return null;

      // Cegah pembuatan superadmin tambahan — hanya boleh ada 1 superadmin
      if (role == StaffRole.superadmin) return null;

      final normalizedEmail = email.trim().toLowerCase();

      // Cek apakah email sudah digunakan.
      final existing = await db
          .collection(_collection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return null;
      }

      final actualPermissions = permissions ??
          (role == StaffRole.dokter
              ? DoctorPermissions.defaultPermissions
              : const <String, bool>{});

      final persistableAvatar = avatarPath != null && avatarPath.isNotEmpty
          ? await StorageService.toPersistableString(avatarPath)
          : null;

      final account = StaffAccount(
        id: '',
        name: name.trim(),
        email: normalizedEmail,
        passwordHash: _hashPassword(password),
        role: role,
        pmikLevel: PmikLevel.biasa,
        createdBy: createdByEmail,
        createdAt: DateTime.now(),
        permissions: actualPermissions,
        avatarPath: persistableAvatar,
        experience: experience,
        strNumber: strNumber,
        birthDate: birthDate,
        education: education,
        additionalInfo: additionalInfo,
      );

      final ref = await db.collection(_collection).add(account.toMap());

      // Jika membuat akun PMIK, kirim notifikasi ke PMIK Superadmin.
      if (role == StaffRole.admin) {
        await SuperadminNotificationService().notifyPmikTambah(name.trim());
      }

      return ref.id;
    } catch (e) {
      debugPrint('[StaffAuthService] createStaffAccount error: $e');

      return null;
    }
  }

  // ============================================================
  // MENGAMBIL AKUN STAFF
  // ============================================================

  /// Mengambil satu akun staff berdasarkan ID
  Future<StaffAccount?> getStaffAccountById(String id) async {
    if (id == 'superadmin_default') {
      return _createDefaultSuperadminAccount();
    }
    if (id == 'dokter_default') {
      return _createDefaultDokterAccount();
    }
    try {
      final db = _db;
      if (db == null) return null;

      final doc = await db.collection(_collection).doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return StaffAccount.fromMap(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('[StaffAuthService] getStaffAccountById error: $e');
      return null;
    }
  }

  /// Mengambil satu akun staff berdasarkan email
  Future<StaffAccount?> getStaffAccountByEmail(String email) async {
    try {
      final db = _db;
      if (db == null) return null;

      final normalized = email.trim().toLowerCase();
      final query = await db
          .collection(_collection)
          .where('email', isEqualTo: normalized)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return StaffAccount.fromMap(query.docs.first.id, query.docs.first.data());
    } catch (e) {
      debugPrint('[StaffAuthService] getStaffAccountByEmail error: $e');
      return null;
    }
  }

  /// Mengambil semua akun staff (untuk halaman kelola akun Superadmin).
  Future<List<StaffAccount>> getAllStaffAccounts() async {
    try {
      final db = _db;
      if (db == null) return [];

      final query = await db.collection(_collection).get();

      return query.docs
          .map((doc) => StaffAccount.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[StaffAuthService] getAllStaffAccounts error: $e');

      return [];
    }
  }

  /// Memperbarui informasi akun staff (nama, email, password, role, permissions, avatarPath, info PMIK)
  Future<void> updateStaffAccount(
    String accountId, {
    String? name,
    String? email,
    String? password,
    StaffRole? role,
    Map<String, bool>? permissions,
    String? avatarPath,
    bool? isActive,
    String? experience,
    String? strNumber,
    String? birthDate,
    String? education,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final db = _db;
      if (db == null) return;

      final Map<String, dynamic> updates = {};
      if (name != null && name.trim().isNotEmpty) updates['name'] = name.trim();
      if (email != null && email.trim().isNotEmpty) {
        final normalizedEmail = email.trim().toLowerCase();
        // Cek apakah email sudah dipakai oleh akun staf lain
        final existingQuery = await db
            .collection(_collection)
            .where('email', isEqualTo: normalizedEmail)
            .get();
        final isDuplicate = existingQuery.docs.any((d) => d.id != accountId);
        if (isDuplicate) {
          throw Exception(
              'Email "$normalizedEmail" sudah digunakan oleh akun lain.');
        }
        updates['email'] = normalizedEmail;
      }
      if (password != null && password.trim().isNotEmpty) {
        updates['passwordHash'] = _hashPassword(password.trim());
      }
      if (role != null) updates['role'] = role.name;
      if (permissions != null) updates['permissions'] = permissions;
      String? persistableAvatar;
      if (avatarPath != null) {
        persistableAvatar = avatarPath.isNotEmpty
            ? await StorageService.toPersistableString(avatarPath)
            : '';
        updates['avatarPath'] = persistableAvatar;
      }
      if (isActive != null) updates['isActive'] = isActive;
      if (experience != null) updates['experience'] = experience;
      if (strNumber != null) updates['strNumber'] = strNumber;
      if (birthDate != null) updates['birthDate'] = birthDate;
      if (education != null) updates['education'] = education;
      if (additionalInfo != null) updates['additionalInfo'] = additionalInfo;

      if (updates.isEmpty) return;

      await db.collection(_collection).doc(accountId).update(updates);

      // Sinkronisasi notifier jika akun yang di-edit adalah akun yang sedang aktif login
      if (currentStaffNotifier.value?.id == accountId) {
        final current = currentStaffNotifier.value!;
        currentStaffNotifier.value = current.copyWith(
          name: name ?? current.name,
          email: (email != null && email.trim().isNotEmpty)
              ? email.trim().toLowerCase()
              : current.email,
          passwordHash: (password != null && password.trim().isNotEmpty)
              ? _hashPassword(password.trim())
              : current.passwordHash,
          role: role ?? current.role,
          permissions: permissions ?? current.permissions,
          avatarPath: persistableAvatar ?? current.avatarPath,
          isActive: isActive ?? current.isActive,
          experience: experience ?? current.experience,
          strNumber: strNumber ?? current.strNumber,
          birthDate: birthDate ?? current.birthDate,
          education: education ?? current.education,
          additionalInfo: additionalInfo ?? current.additionalInfo,
        );
      }
    } catch (e) {
      debugPrint('[StaffAuthService] updateStaffAccount error: $e');
      rethrow;
    }
  }

  /// Menghapus permanen akun staff dari Firestore
  Future<void> deleteStaffAccount(String accountId) async {
    try {
      final db = _db;
      if (db == null) return;

      await db.collection(_collection).doc(accountId).delete();

      if (currentStaffNotifier.value?.id == accountId) {
        currentStaffNotifier.value = null;
      }
    } catch (e) {
      debugPrint('[StaffAuthService] deleteStaffAccount error: $e');
      rethrow;
    }
  }

  /// Memperbarui foto profil staff/superadmin
  Future<void> updateAvatar(String accountId, String? avatarPath) async {
    await updateStaffAccount(accountId, avatarPath: avatarPath);
  }

  // ============================================================
  // AKTIF / NONAKTIF AKUN
  // ============================================================

  /// Mengaktifkan atau menonaktifkan akun staff.
  Future<void> setAccountActive(String accountId, bool isActive) async {
    try {
      final db = _db;
      if (db == null) return;

      await db.collection(_collection).doc(accountId).update({
        'isActive': isActive,
      });
      if (currentStaffNotifier.value?.id == accountId) {
        currentStaffNotifier.value =
            currentStaffNotifier.value?.copyWith(isActive: isActive);
      }
    } catch (e) {
      debugPrint('[StaffAuthService] setAccountActive error: $e');
    }
  }

  // ============================================================
  // GANTI PASSWORD
  // ============================================================

  /// Mengubah password akun staff.
  Future<void> changePassword(String accountId, String newPassword) async {
    try {
      final db = _db;
      if (db == null) return;

      final newHash = _hashPassword(newPassword.trim());
      await db.collection(_collection).doc(accountId).update({
        'passwordHash': newHash,
      });
      if (currentStaffNotifier.value?.id == accountId) {
        currentStaffNotifier.value =
            currentStaffNotifier.value?.copyWith(passwordHash: newHash);
      }
    } catch (e) {
      debugPrint('[StaffAuthService] changePassword error: $e');
      rethrow;
    }
  }

  /// Mendapatkan akun Superadmin aktif saat ini dari Firestore
  Future<StaffAccount?> getSuperadminAccount() async {
    try {
      final db = _db;
      if (db == null) return currentStaff;
      if (currentStaff != null && currentStaff!.id.isNotEmpty) {
        final doc =
            await db.collection(_collection).doc(currentStaff!.id).get();
        if (doc.exists && doc.data() != null) {
          final acc = StaffAccount.fromMap(doc.id, doc.data()!);
          currentStaffNotifier.value = acc;
          return acc;
        }
      }
      final query = await db
          .collection(_collection)
          .where('role', isEqualTo: StaffRole.superadmin.name)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final acc = StaffAccount.fromMap(doc.id, doc.data());
        currentStaffNotifier.value = acc;
        return acc;
      }
      return currentStaff;
    } catch (e) {
      debugPrint('[StaffAuthService] getSuperadminAccount error: $e');
      return currentStaff;
    }
  }
}
