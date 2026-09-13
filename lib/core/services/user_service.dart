import 'package:flutter/foundation.dart';
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
