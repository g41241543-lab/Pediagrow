import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/staff_account_model.dart';

/// Service untuk mengelola login & akun staff internal
/// (Superadmin, Admin/PMIK, Dokter) melalui Firestore.
class StaffAuthService {
  static final StaffAuthService _instance = StaffAuthService._internal();
  factory StaffAuthService() => _instance;
  StaffAuthService._internal();

  static const String _collection = 'staff_accounts';

  static const String defaultSuperadminEmail = 'superadmin@pediagrow.com';
  static const String defaultSuperadminPassword = 'Superadmin123!';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _hashPassword(String rawPassword) {
    final bytes = utf8.encode(rawPassword);
    return sha256.convert(bytes).toString();
  }

  /// Memastikan minimal ada satu akun Superadmin di Firestore.
  Future<void> ensureSuperadminSeeded() async {
    try {
      final query = await _db
          .collection(_collection)
          .where('role', isEqualTo: StaffRole.superadmin.name)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        await _db
            .collection(_collection)
            .add(
              StaffAccount(
                id: '',
                name: 'Superadmin PediaGrow',
                email: defaultSuperadminEmail,
                passwordHash: _hashPassword(defaultSuperadminPassword),
                role: StaffRole.superadmin,
                createdBy: 'system',
                createdAt: DateTime.now(),
              ).toMap(),
            );
        debugPrint(
          '[StaffAuthService] Akun superadmin default dibuat: '
          '$defaultSuperadminEmail / $defaultSuperadminPassword '
          '(SEGERA GANTI PASSWORD INI!)',
        );
      }
    } catch (e) {
      debugPrint('[StaffAuthService] Gagal seeding superadmin: $e');
    }
  }

  /// Login staff (superadmin/admin/dokter) dengan email + password.
  Future<StaffAccount?> login(String email, String password) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final query = await _db
          .collection(_collection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final doc = query.docs.first;
      final account = StaffAccount.fromMap(doc.id, doc.data());

      if (!account.isActive) return null;

      final inputHash = _hashPassword(password);
      if (inputHash != account.passwordHash) return null;

      return account;
    } catch (e) {
      debugPrint('[StaffAuthService] login error: $e');
      return null;
    }
  }

  /// Dipanggil oleh Superadmin untuk membuat akun Admin/Dokter baru.
  Future<bool> createStaffAccount({
    required String name,
    required String email,
    required String password,
    required StaffRole role,
    required String createdByEmail,
  }) async {
    try {
      // Cegah pembuatan superadmin tambahan — hanya boleh ada 1 superadmin
      if (role == StaffRole.superadmin) return false;

      final normalizedEmail = email.trim().toLowerCase();

      final existing = await _db
          .collection(_collection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return false;

      await _db
          .collection(_collection)
          .add(
            StaffAccount(
              id: '',
              name: name.trim(),
              email: normalizedEmail,
              passwordHash: _hashPassword(password),
              role: role,
              createdBy: createdByEmail,
              createdAt: DateTime.now(),
            ).toMap(),
          );
      return true;
    } catch (e) {
      debugPrint('[StaffAuthService] createStaffAccount error: $e');
      return false;
    }
  }

  /// Mengambil semua akun staff (untuk halaman kelola akun Superadmin).
  Future<List<StaffAccount>> getAllStaffAccounts() async {
    try {
      final query = await _db.collection(_collection).get();
      return query.docs
          .map((doc) => StaffAccount.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[StaffAuthService] getAllStaffAccounts error: $e');
      return [];
    }
  }

  /// Menonaktifkan/mengaktifkan akun staff (bukan hapus permanen).
  Future<void> setAccountActive(String accountId, bool isActive) async {
    try {
      await _db.collection(_collection).doc(accountId).update({
        'isActive': isActive,
      });
    } catch (e) {
      debugPrint('[StaffAuthService] setAccountActive error: $e');
    }
  }

  /// Mengubah password akun staff.
  Future<void> changePassword(String accountId, String newPassword) async {
    try {
      await _db.collection(_collection).doc(accountId).update({
        'passwordHash': _hashPassword(newPassword),
      });
    } catch (e) {
      debugPrint('[StaffAuthService] changePassword error: $e');
    }
  }
}
