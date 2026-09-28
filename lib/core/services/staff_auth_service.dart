import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/staff_account_model.dart';
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

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Staff yang sedang login.
  ///
  /// null = tidak ada staff yang login.
  final ValueNotifier<StaffAccount?> currentStaffNotifier =
      ValueNotifier<StaffAccount?>(null);

  StaffAccount? get currentStaff => currentStaffNotifier.value;

  /// Keluar dari sesi staff.
  void logout() {
    currentStaffNotifier.value = null;
  }

  // ============================================================
  // CEK EMAIL STAFF
  // ============================================================

  /// Mengecek apakah email sudah terdaftar sebagai akun staff.
  ///
  /// Akun aktif maupun tidak aktif tetap dianggap sudah terdaftar.
  Future<bool> isStaffEmail(String email) async {
    try {
      final query = await _db
          .collection(_collection)
          .where('email', isEqualTo: email.trim().toLowerCase())
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

  /// Memastikan minimal ada satu akun PMIK Superadmin
  /// di Firestore.
  ///
  /// Struktur akun Superadmin:
  ///
  /// role      = admin
  /// pmikLevel = superadmin
  Future<void> ensureSuperadminSeeded() async {
    try {
      final query = await _db
          .collection(_collection)
          .where('role', isEqualTo: StaffRole.admin.name)
          .where('pmikLevel', isEqualTo: PmikLevel.superadmin.name)
          .limit(1)
          .get();

      // Jika sudah ada PMIK Superadmin,
      // tidak membuat akun baru.
      if (query.docs.isNotEmpty) {
        return;
      }

      await _db
          .collection(_collection)
          .add(
            StaffAccount(
              id: '',
              name: 'Superadmin PediaGrow',
              email: defaultSuperadminEmail,
              passwordHash: _hashPassword(defaultSuperadminPassword),
              role: StaffRole.admin,
              pmikLevel: PmikLevel.superadmin,
              createdBy: 'system',
              createdAt: DateTime.now(),
            ).toMap(),
          );

      debugPrint(
        '[StaffAuthService] '
        'Akun PMIK Superadmin default berhasil dibuat.',
      );
    } catch (e) {
      debugPrint(
        '[StaffAuthService] '
        'Gagal seeding PMIK Superadmin: $e',
      );
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
    try {
      final normalizedEmail = email.trim().toLowerCase();

      final query = await _db
          .collection(_collection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      final doc = query.docs.first;

      final account = StaffAccount.fromMap(doc.id, doc.data());

      // Akun yang tidak aktif tidak dapat login.
      if (!account.isActive) {
        return null;
      }

      final inputHash = _hashPassword(password);

      // Password salah.
      if (inputHash != account.passwordHash) {
        return null;
      }

      // Simpan staff yang sedang login.
      currentStaffNotifier.value = account;

      return account;
    } catch (e) {
      debugPrint('[StaffAuthService] login error: $e');

      return null;
    }
  }

  // ============================================================
  // MEMBUAT AKUN STAFF
  // ============================================================

  /// Membuat akun staff baru.
  ///
  /// Yang dapat dibuat melalui fungsi ini:
  /// - PMIK biasa
  /// - Dokter
  ///
  /// PMIK Superadmin tidak dibuat melalui fungsi ini.
  /// Akun PMIK Superadmin adalah akun khusus sistem.
  Future<String?> createStaffAccount({
    required String name,
    required String email,
    required String password,
    required StaffRole role,
    required String createdByEmail,
  }) async {
    try {
      // PMIK Superadmin tidak boleh dibuat dari fungsi
      // pembuatan akun staff biasa.
      //
      // Pada struktur baru, Superadmin bukan StaffRole
      // tersendiri. Superadmin adalah:
      //
      // role = admin
      // pmikLevel = superadmin
      //
      // Fungsi ini hanya membuat PMIK biasa atau dokter.

      final normalizedEmail = email.trim().toLowerCase();

      // Cek apakah email sudah digunakan.
      final existing = await _db
          .collection(_collection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return null;
      }

      // Karena fungsi ini hanya membuat PMIK biasa
      // atau dokter, maka level PMIK selalu biasa.
      final account = StaffAccount(
        id: '',
        name: name.trim(),
        email: normalizedEmail,
        passwordHash: _hashPassword(password),
        role: role,
        pmikLevel: PmikLevel.biasa,
        createdBy: createdByEmail,
        createdAt: DateTime.now(),
      );

      final ref = await _db.collection(_collection).add(account.toMap());

      // Jika membuat akun PMIK, kirim notifikasi
      // ke PMIK Superadmin.
      if (role == StaffRole.admin) {
        await SuperadminNotificationService().notifyPmikTambah(name.trim());
      }

      return ref.id;
    } catch (e) {
      debugPrint(
        '[StaffAuthService] '
        'createStaffAccount error: $e',
      );

      return null;
    }
  }

  // ============================================================
  // MENGAMBIL SEMUA AKUN STAFF
  // ============================================================

  /// Mengambil semua akun staff.
  ///
  /// Digunakan pada halaman pengelolaan akun
  /// milik PMIK Superadmin.
  Future<List<StaffAccount>> getAllStaffAccounts() async {
    try {
      final query = await _db.collection(_collection).get();

      return query.docs
          .map((doc) => StaffAccount.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint(
        '[StaffAuthService] '
        'getAllStaffAccounts error: $e',
      );

      return [];
    }
  }

  // ============================================================
  // AKTIF / NONAKTIF AKUN
  // ============================================================

  /// Mengaktifkan atau menonaktifkan akun staff.
  ///
  /// Akun tidak dihapus permanen.
  Future<void> setAccountActive(String accountId, bool isActive) async {
    try {
      await _db.collection(_collection).doc(accountId).update({
        'isActive': isActive,
      });
    } catch (e) {
      debugPrint(
        '[StaffAuthService] '
        'setAccountActive error: $e',
      );
    }
  }

  // ============================================================
  // GANTI PASSWORD
  // ============================================================

  /// Mengubah password akun staff.
  Future<void> changePassword(String accountId, String newPassword) async {
    try {
      await _db.collection(_collection).doc(accountId).update({
        'passwordHash': _hashPassword(newPassword),
      });
    } catch (e) {
      debugPrint(
        '[StaffAuthService] '
        'changePassword error: $e',
      );
    }
  }
}
