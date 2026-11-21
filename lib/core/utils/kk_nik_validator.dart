/// Validator terpusat untuk Nomor KK dan NIK Anak.
///
/// Disesuaikan untuk kebutuhan integrasi sandbox (SATUSEHAT) & kemudahan input:
/// - Hanya memvalidasi bahwa input wajib diisi dan tepat 16 digit angka.
class KkNikValidator {
  // Konstruktor private — kelas ini hanya berisi metode statis.
  KkNikValidator._();

  /// Validasi Nomor KK.
  ///
  /// Memeriksa:
  /// - Wajib tepat 16 digit angka.
  ///
  /// Mengembalikan `null` jika valid, atau pesan error (String) jika tidak.
  static String? validateNoKk(String noKk) {
    final clean = noKk.trim();
    if (clean.isEmpty) {
      return 'Nomor KK wajib diisi';
    }
    if (clean.length != 16 || !RegExp(r'^\d{16}$').hasMatch(clean)) {
      return 'Nomor KK harus 16 digit angka';
    }
    return null;
  }

  /// Validasi NIK Anak.
  ///
  /// Memeriksa:
  /// - Wajib tepat 16 digit angka.
  ///
  /// Parameter opsional [birthDate] dan [gender] dipertahankan agar kompatibel
  /// dengan seluruh pemanggil fungsi tanpa memaksakan validasi silang (cross-validation).
  ///
  /// Mengembalikan `null` jika valid, atau pesan error (String) jika tidak.
  static String? validateNik(
    String nik, {
    DateTime? birthDate,
    String? gender,
  }) {
    final clean = nik.trim();
    if (clean.isEmpty) {
      return 'NIK Anak wajib diisi';
    }
    if (clean.length != 16 || !RegExp(r'^\d{16}$').hasMatch(clean)) {
      return 'NIK Anak harus 16 digit angka';
    }
    return null;
  }
}

