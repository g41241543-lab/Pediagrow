import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_auth_config.dart';
import '../../models/user_model.dart';
import 'user_service.dart';

/// Hasil dari proses Google Authentication.
class GoogleAuthResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? errorMessage;
  final int? statusCode;
  final GoogleSignInAccount? account;

  const GoogleAuthResult._({
    required this.isSuccess,
    this.isCancelled = false,
    this.errorMessage,
    this.statusCode,
    this.account,
  });

  factory GoogleAuthResult.success(GoogleSignInAccount account) {
    return GoogleAuthResult._(isSuccess: true, account: account);
  }

  factory GoogleAuthResult.cancelled() {
    return const GoogleAuthResult._(isSuccess: false, isCancelled: true);
  }

  factory GoogleAuthResult.failure(String message, {int? statusCode}) {
    return GoogleAuthResult._(
      isSuccess: false,
      errorMessage: message,
      statusCode: statusCode,
    );
  }
}

/// Service singleton untuk mengelola Google Sign-In di PediaGrow.
///
/// Menyediakan autentikasi Google nyata via [GoogleSignIn],
/// penanganan error yang komprehensif (misal: SHA-1 belum terdaftar di Google Cloud),
/// dan opsi akun demo saat dalam tahap pengembangan.
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  /// Instance GoogleSignIn.
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: GoogleAuthConfig.webClientId,
  );

  /// Memulai alur sign-in Google.
  ///
  /// Menampilkan account picker bawaan sistem (native OS dialog).
  /// Setelah akun dipilih, data akun Google (nama, email, photoUrl)
  /// langsung disimpan ke [UserService].
  ///
  /// Mengembalikan [GoogleAuthResult] dengan status keberhasilan,
  /// pembatalan, atau pesan error diagnostik.

  Future<GoogleAuthResult> signIn() async {
    try {
      await _googleSignIn.signOut(); // <-- BARIS BARU: hapus sesi lama dulu

      final account = await _googleSignIn.signIn();
      if (account == null) {
        // Pengguna menekan tombol Kembali / membatalkan dialog
        return GoogleAuthResult.cancelled();
      }

      // Simpan data akun Google ke UserService agar tersedia di seluruh app
      UserService().loginWithGoogle(account);

      return GoogleAuthResult.success(account);
    } catch (e) {
      debugPrint('[GoogleAuthService] signIn error: $e');
      final errorStr = e.toString();

      int? statusCode;
      String message;

      if (errorStr.contains('10') || errorStr.contains('DEVELOPER_ERROR')) {
        statusCode = 10;
        message =
            'Google API menolak koneksi (ApiException: 10 - DEVELOPER_ERROR).\n'
            'SHA-1 debug (${GoogleAuthConfig.debugSha1}) belum didaftarkan di Google Cloud Console '
            'untuk package ${GoogleAuthConfig.androidPackageName}.';
      } else if (errorStr.contains('12500')) {
        statusCode = 12500;
        message =
            'Google Sign-In gagal (Error 12500).\n'
            'Layar Izin OAuth (OAuth Consent Screen) belum dikonfigurasi di Google Cloud Console.';
      } else if (errorStr.contains('7') ||
          errorStr.toLowerCase().contains('network')) {
        statusCode = 7;
        message = 'Gagal terhubung ke Google. Periksa koneksi internet perangkat Anda.';
      } else {
        message = 'Gagal masuk dengan Google: $e';
      }

      return GoogleAuthResult.failure(message, statusCode: statusCode);
    }
  }

  /// Masuk menggunakan akun uji coba (Demo Account) jika Google Cloud Console
  /// belum selesai dikonfigurasi oleh pengembang.
  void loginWithDemoUser({
    String name = 'Pengguna Google (Demo)',
    String email = 'user.pediagrow@gmail.com',
  }) {
    UserService().currentUserNotifier.value = UserModel(
      id: 'google_demo_123',
      name: name,
      email: email,
      avatarPath: null,
    );
  }

  /// Menandatangani keluar pengguna dari Google Sign-In
  /// dan mereset [UserService] ke state tamu.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      UserService().logout();
    } catch (e) {
      debugPrint('[GoogleAuthService] signOut error: $e');
    }
  }

  /// Mengecek apakah pengguna saat ini masih memiliki session Google aktif.
  Future<bool> isSignedIn() => _googleSignIn.isSignedIn();

  /// Mencoba silent sign-in menggunakan session sebelumnya.
  Future<GoogleSignInAccount?> trySilentSignIn() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        UserService().loginWithGoogle(account);
      }
      return account;
    } catch (_) {
      return null;
    }
  }
}
