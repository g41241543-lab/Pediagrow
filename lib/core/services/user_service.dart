import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
/// Menggunakan [ValueNotifier] agar perubahan data pengguna (nama, username, foto profil, dll.)
/// dapat didengar secara reaktif oleh widget UI secara dinamis real-time.
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String _collection = 'users';
  static const String _prefKeyUserId = 'current_user_id';

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// State pengguna aktif. Default: state tamu (belum login).
  final ValueNotifier<UserModel> currentUserNotifier = ValueNotifier<UserModel>(
    const UserModel(id: '', name: 'Tamu', email: ''),
  );

  /// Subscription listener dokumen user di Firestore
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;

  /// Mengambil data pengguna aktif saat ini
  UserModel get currentUser => currentUserNotifier.value;

  /// Apakah ada pengguna yang sedang login (bukan tamu)
  bool get isLoggedIn => currentUserNotifier.value.id.isNotEmpty;

  String _hashPassword(String rawPassword) {
    final bytes = utf8.encode(rawPassword);
    return sha256.convert(bytes).toString();
  }

  // ---------------------------------------------------------------------
  // INISIALISASI & PERSISTENSI SESI
  // ---------------------------------------------------------------------

  /// Inisialisasi sesi pengguna saat aplikasi dibuka:
  /// 1. Coba pulihkan userId dari SharedPreferences.
  /// 2. Jika ada, muat dokumen dari collection 'users' dan dengarkan real-time.
  /// 3. Jika belum ada di preferences, cari apakah ada akun di collection 'users'
  ///    untuk dihubungkan agar sapaan langsung sinkron dengan database pengguna.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString(_prefKeyUserId);

      final db = _db;
      if (db == null) return;

      if (savedUserId != null && savedUserId.isNotEmpty) {
        final doc = await db.collection(_collection).doc(savedUserId).get();
        if (doc.exists && doc.data() != null) {
          final user = UserModel.fromMap({...doc.data()!, 'id': doc.id});
          currentUserNotifier.value = user;
          _startListeningToUser(savedUserId);
          return;
        }
      }

      // Fallback: jika belum ada sesi tersimpan tetapi ada dokumen di collection 'users'
      if (currentUserNotifier.value.id.isEmpty) {
        final query = await db.collection(_collection).limit(1).get();
        if (query.docs.isNotEmpty) {
          final firstDoc = query.docs.first;
          final user = UserModel.fromMap({...firstDoc.data(), 'id': firstDoc.id});
          currentUserNotifier.value = user;
          await _saveSession(firstDoc.id);
          _startListeningToUser(firstDoc.id);
        }
      }
    } catch (e) {
      debugPrint('[UserService] init error: $e');
    }
  }

  /// Mulai mendengarkan pembaruan data pengguna di Firestore secara real-time
  void _startListeningToUser(String userId) {
    _userSubscription?.cancel();
    if (userId.isEmpty) return;

    final db = _db;
    if (db == null) return;

    try {
      _userSubscription = db
          .collection(_collection)
          .doc(userId)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists && snapshot.data() != null) {
                final updated = UserModel.fromMap({
                  ...snapshot.data()!,
                  'id': snapshot.id,
                });
                currentUserNotifier.value = updated;
              }
            },
            onError: (error) {
              debugPrint('[UserService] listen error: $error');
            },
          );
    } catch (e) {
      debugPrint('[UserService] start listening error: $e');
    }
  }

  Future<void> _saveSession(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyUserId, userId);
    } catch (e) {
      debugPrint('[UserService] saveSession error: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyUserId);
    } catch (e) {
      debugPrint('[UserService] clearSession error: $e');
    }
  }

  // ---------------------------------------------------------------------
  // DAFTAR & MASUK DENGAN EMAIL / USERNAME / PASSWORD
  // ---------------------------------------------------------------------

  /// Mendaftarkan pengguna baru dengan nama/username, email, dan password.
  /// Menolak jika email sudah terdaftar sebelumnya.
  Future<UserAuthResult> registerWithEmail({
    required String name,
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      final db = _db;
      if (db == null) {
        return UserAuthResult.failure('Koneksi database tidak tersedia.');
      }

      final normalizedEmail = email.trim().toLowerCase();

      // Email staf tidak boleh dipakai mendaftar sebagai pengguna biasa
      if (await StaffAuthService().isStaffEmail(normalizedEmail)) {
        return UserAuthResult.failure(
          'Email ini sudah terdaftar. Silakan masuk.',
        );
      }

      final existing = await db
          .collection(_collection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return UserAuthResult.failure(
          'Email ini sudah terdaftar. Silakan masuk.',
        );
      }

      final cleanName = name.trim();
      final cleanUsername = (username?.trim().isNotEmpty == true)
          ? username!.trim()
          : cleanName;

      final newUser = UserModel(
        id: '', // diisi otomatis oleh Firestore
        name: cleanName,
        username: cleanUsername,
        email: normalizedEmail,
        passwordHash: _hashPassword(password),
      );

      final docRef = await db.collection(_collection).add(newUser.toMap());
      final savedUser = newUser.copyWith(id: docRef.id);

      currentUserNotifier.value = savedUser;
      await _saveSession(docRef.id);
      _startListeningToUser(docRef.id);

      return UserAuthResult.success();
    } catch (e) {
      debugPrint('[UserService] registerWithEmail error: $e');
      return UserAuthResult.failure('Gagal mendaftar: $e');
    }
  }

  /// Login pengguna dengan email atau username & password.
  Future<UserAuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final db = _db;
      if (db == null) {
        return UserAuthResult.failure('Koneksi database tidak tersedia.');
      }

      final input = email.trim();
      final normalizedEmail = input.toLowerCase();

      // 1. Coba cari berdasarkan email
      var query = await db
          .collection(_collection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      // 2. Jika tidak ditemukan, coba cari berdasarkan username
      if (query.docs.isEmpty) {
        query = await db
            .collection(_collection)
            .where('username', isEqualTo: input)
            .limit(1)
            .get();
      }

      // 3. Jika masih kosong, coba cari berdasarkan field name
      if (query.docs.isEmpty) {
        query = await db
            .collection(_collection)
            .where('name', isEqualTo: input)
            .limit(1)
            .get();
      }

      if (query.docs.isEmpty) {
        return UserAuthResult.failure(
          'Akun belum terdaftar. Silakan daftar dulu.',
        );
      }

      final doc = query.docs.first;
      final user = UserModel.fromMap({...doc.data(), 'id': doc.id});

      final inputHash = _hashPassword(password);
      if (inputHash != user.passwordHash) {
        return UserAuthResult.failure('Password salah.');
      }

      currentUserNotifier.value = user;
      await _saveSession(doc.id);
      _startListeningToUser(doc.id);

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
      final db = _db;
      if (db == null) return;

      final normalizedEmail = account.email.trim().toLowerCase();

      final query = await db
          .collection(_collection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        final displayName = account.displayName ?? normalizedEmail.split('@').first;
        final newUser = UserModel(
          id: '',
          name: displayName,
          username: displayName,
          email: normalizedEmail,
          avatarPath: account.photoUrl,
        );
        final docRef = await db.collection(_collection).add(newUser.toMap());
        final savedUser = newUser.copyWith(id: docRef.id);
        currentUserNotifier.value = savedUser;
        await _saveSession(docRef.id);
        _startListeningToUser(docRef.id);
      } else {
        final doc = query.docs.first;
        final user = UserModel.fromMap({
          ...doc.data(),
          'id': doc.id,
        });
        currentUserNotifier.value = user;
        await _saveSession(doc.id);
        _startListeningToUser(doc.id);
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

  /// Memperbarui username pengguna (lokal + Firestore)
  Future<void> updateUsername(String newUsername) async {
    currentUserNotifier.value = currentUserNotifier.value.copyWith(
      username: newUsername,
    );
    await _syncCurrentUserToFirestore();
  }

  /// Memperbarui profil pengguna secara lengkap (lokal + Firestore)
  Future<void> updateProfile({
    String? name,
    String? username,
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
      username: username,
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
    if (user.id.isEmpty) return;
    try {
      final db = _db;
      if (db == null) return;
      await db.collection(_collection).doc(user.id).update(user.toMap());
    } catch (e) {
      debugPrint('[UserService] sync error: $e');
    }
  }

  /// Mengatur ulang sesi pengguna (logout)
  void logout() {
    _userSubscription?.cancel();
    _userSubscription = null;
    _clearSession();
    currentUserNotifier.value = const UserModel(
      id: '',
      name: 'Tamu',
      email: '',
    );
  }
}
