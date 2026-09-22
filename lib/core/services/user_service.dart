import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/user_model.dart';
import 'staff_auth_service.dart';

/// Hasil dari proses daftar/masuk pengguna dengan email & password.
class UserAuthResult {
  final bool isSuccess;
  final String? errorMessage;

  const UserAuthResult._({required this.isSuccess, this.errorMessage});

  factory UserAuthResult.success() => const UserAuthResult._(isSuccess: true);

  factory UserAuthResult.failure(String message) =>
      UserAuthResult._(isSuccess: false, errorMessage: message);
}

/// Service singleton untuk mengelola data & autentikasi pengguna masyarakat
/// (bukan staff) melalui Firestore, collection 'users'.
///
/// Menggunakan [ValueNotifier] agar perubahan data pengguna (nama, foto profil, dll.)
/// dapat didengar secara reaktif oleh widget UI secara dinamis.
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String _collection = 'users';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// State pengguna aktif. Default: state tamu (belum login).
  final ValueNotifier<UserModel> currentUserNotifier = ValueNotifier<UserModel>(
    const UserModel(id: '', name: 'Tamu', email: ''),
  );

  /// Mengambil data pengguna aktif saat ini
  UserModel get currentUser => currentUserNotifier.value;

  /// Apakah ada pengguna yang sedang login (bukan tamu)
  bool get isLoggedIn => currentUserNotifier.value.id.isNotEmpty;

  String _hashPassword(String rawPassword) {
    final bytes = utf8.encode(rawPassword);
    return sha256.convert(bytes).toString();
  }

  // ---------------------------------------------------------------------
  // DAFTAR & MASUK DENGAN EMAIL/PASSWORD
  // ---------------------------------------------------------------------

  /// Mendaftarkan pengguna baru dengan nama, email, dan password.
  /// Menolak jika email sudah terdaftar sebelumnya.
  Future<UserAuthResult> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      // Email staf tidak boleh dipakai mendaftar sebagai pengguna biasa
      if (await StaffAuthService().isStaffEmail(normalizedEmail)) {
        return UserAuthResult.failure(
          'Email ini sudah terdaftar. Silakan masuk.',
        );
      }

      final existing = await _db
          .collection(_collection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return UserAuthResult.failure(
          'Email ini sudah terdaftar. Silakan masuk.',
        );
      }

      final newUser = UserModel(
        id: '', // diisi otomatis oleh Firestore
        name: name.trim(),
        email: normalizedEmail,
        passwordHash: _hashPassword(password),
      );

      final docRef = await _db.collection(_collection).add(newUser.toMap());

      currentUserNotifier.value = newUser.copyWith(id: docRef.id);
      return UserAuthResult.success();
    } catch (e) {
      debugPrint('[UserService] registerWithEmail error: $e');
      return UserAuthResult.failure('Gagal mendaftar: $e');
    }
  }

  /// Login pengguna dengan email & password.
  Future<UserAuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      final query = await _db
          .collection(_collection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return UserAuthResult.failure(
          'Email belum terdaftar. Silakan daftar dulu.',
        );
      }

      final doc = query.docs.first;
      final user = UserModel.fromMap({...doc.data(), 'id': doc.id});

      final inputHash = _hashPassword(password);
      if (inputHash != user.passwordHash) {
        return UserAuthResult.failure('Password salah.');
      }

      currentUserNotifier.value = user;
      return UserAuthResult.success();
    } catch (e) {
      debugPrint('[UserService] loginWithEmail error: $e');
      return UserAuthResult.failure('Gagal masuk: $e');
    }
  }

  // ---------------------------------------------------------------------
  // MASUK DENGAN GOOGLE
  // ---------------------------------------------------------------------

  /// Dipanggil setelah GoogleAuthService berhasil sign-in.
  /// Jika email belum pernah dipakai, otomatis buat akun baru di Firestore.
  /// Jika sudah ada, langsung masuk dengan data yang tersimpan.
  Future<void> loginWithGoogle(GoogleSignInAccount account) async {
    try {
      final normalizedEmail = account.email.trim().toLowerCase();

      final query = await _db
          .collection(_collection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        // Pengguna baru lewat Google — buat dokumen baru (tanpa passwordHash)
        final newUser = UserModel(
          id: '',
          name: account.displayName ?? normalizedEmail,
          email: normalizedEmail,
          avatarPath: account.photoUrl,
        );
        final docRef = await _db.collection(_collection).add(newUser.toMap());
        currentUserNotifier.value = newUser.copyWith(id: docRef.id);
      } else {
        // Pengguna lama — muat data yang sudah ada
        final doc = query.docs.first;
        currentUserNotifier.value = UserModel.fromMap({
          ...doc.data(),
          'id': doc.id,
        });
      }
    } catch (e) {
      debugPrint('[UserService] loginWithGoogle error: $e');
    }
  }

  // ---------------------------------------------------------------------
  // PROFIL
  // ---------------------------------------------------------------------

  /// Memperbarui path foto profil pengguna (lokal + Firestore)
  Future<void> updateAvatar(String? path) async {
    currentUserNotifier.value = currentUserNotifier.value.copyWith(
      avatarPath: path,
    );
    await _syncCurrentUserToFirestore();
  }

  /// Memperbarui nama lengkap pengguna (lokal + Firestore)
  Future<void> updateName(String newName) async {
    currentUserNotifier.value = currentUserNotifier.value.copyWith(
      name: newName,
    );
    await _syncCurrentUserToFirestore();
  }

  /// Memperbarui profil pengguna secara lengkap (lokal + Firestore)
  Future<void> updateProfile({
    String? name,
    String? email,
    String? gender,
    String? birthDate,
    String? province,
    String? city,
    String? district,
    String? subDistrict,
  }) async {
    currentUserNotifier.value = currentUserNotifier.value.copyWith(
      name: name,
      email: email,
      gender: gender,
      birthDate: birthDate,
      province: province,
      city: city,
      district: district,
      subDistrict: subDistrict,
    );
    await _syncCurrentUserToFirestore();
  }

  /// Menyimpan perubahan data pengguna yang sedang login ke Firestore.
  Future<void> _syncCurrentUserToFirestore() async {
    final user = currentUserNotifier.value;
    if (user.id.isEmpty)
      return; // masih tamu, tidak ada dokumen untuk di-update
    try {
      await _db.collection(_collection).doc(user.id).update(user.toMap());
    } catch (e) {
      debugPrint('[UserService] sync error: $e');
    }
  }

  /// Mengatur ulang sesi pengguna (logout) — hanya reset state lokal,
  /// data di Firestore tetap tersimpan untuk login berikutnya.
  void logout() {
    currentUserNotifier.value = const UserModel(
      id: '',
      name: 'Tamu',
      email: '',
    );
  }
}
