import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user_model.dart';

/// Service singleton untuk mengelola data pengguna yang sedang aktif (login).
///
/// Menggunakan [ValueNotifier] agar perubahan data pengguna (nama, foto profil, dll.)
/// dapat didengar secara reaktif oleh widget UI secara dinamis.
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  /// State pengguna aktif dengan nilai default awal sesuai data desain
  final ValueNotifier<UserModel> currentUserNotifier = ValueNotifier<UserModel>(
    const UserModel(
      id: 'usr_001',
      name: 'Susanti Saputri Dewi',
      email: 'susanti.saputri@gmail.com',
      phone: '081234567890',
      avatarPath: null,
    ),
  );

  /// Mengambil data pengguna aktif saat ini
  UserModel get currentUser => currentUserNotifier.value;

  /// Memperbarui path foto profil pengguna
  void updateAvatar(String? path) {
    currentUserNotifier.value = currentUserNotifier.value.copyWith(
      avatarPath: path,
    );
  }

  /// Memperbarui nama lengkap pengguna
  void updateName(String newName) {
    currentUserNotifier.value = currentUserNotifier.value.copyWith(
      name: newName,
    );
  }

  /// Memperbarui profil pengguna secara lengkap
  void updateProfile({
    String? name,
    String? email,
    String? gender,
    String? birthDate,
    String? province,
    String? city,
    String? district,
    String? subDistrict,
  }) {
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
  }

  /// Login menggunakan akun Google.
  /// Dipanggil oleh [GoogleAuthService] setelah sign-in berhasil.
  /// Data nama, email, dan foto profil diambil langsung dari [GoogleSignInAccount].
  void loginWithGoogle(GoogleSignInAccount account) {
    currentUserNotifier.value = UserModel(
      id: account.id,
      name: account.displayName ?? account.email.split('@').first,
      email: account.email,
      // photoUrl dari Google adalah URL https — disimpan sebagai avatarPath
      // Halaman profil perlu mengecek apakah ini URL atau path lokal
      avatarPath: account.photoUrl,
    );
  }

  /// Mengatur ulang sesi pengguna (logout)
  void logout() {
    currentUserNotifier.value = const UserModel(
      id: '',
      name: 'Tamu',
      email: '',
      avatarPath: null,
    );
  }
}
