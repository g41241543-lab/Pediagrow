/// Validator terpusat untuk Nomor KK dan NIK Anak.
///
/// Menerapkan validasi berlapis:
/// 1. Format: 16 digit angka.
/// 2. Anti-Dummy: Tolak pola angka sembarangan (semua sama, sekuensial).
/// 3. Kode Provinsi: 2 digit pertama harus kode provinsi valid Indonesia
///    berdasarkan data Kemendagri.
/// 4. Cross-Validation NIK (khusus NIK): Cocokkan digit 7–12 dengan
///    tanggal lahir & jenis kelamin anak sesuai format NIK Indonesia.
///
/// Referensi format NIK:
/// - Digit 1–2  : Kode provinsi
/// - Digit 3–4  : Kode kabupaten/kota
/// - Digit 5–6  : Kode kecamatan
/// - Digit 7–8  : Tanggal lahir (hari); perempuan = hari + 40
/// - Digit 9–10 : Bulan lahir
/// - Digit 11–12: Tahun lahir (2 digit terakhir)
/// - Digit 13–16: Nomor urut (0001–9999)
class KkNikValidator {
  // Konstruktor private — kelas ini hanya berisi metode statis.
  KkNikValidator._();

  /// Daftar kode provinsi valid Indonesia (Kemendagri).
  static const _validProvinceCodes = {
    '11', '12', '13', '14', '15', '16', '17', '18', '19', '21',
    '31', '32', '33', '34', '35', '36',
    '51', '52', '53',
    '61', '62', '63', '64', '65',
    '71', '72', '73', '74', '75', '76',
    '81', '82',
    '91', '92', '94', '96',
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Validasi Nomor KK.
  ///
  /// Pemeriksaan:
  /// - Harus tepat 16 digit angka.
  /// - Tidak boleh pola dummy (semua digit sama atau sekuensial).
  /// - 2 digit pertama harus kode provinsi valid.
  ///
  /// Mengembalikan `null` jika valid, atau pesan error (String) jika tidak.
  static String? validateNoKk(String noKk) {
    // 1. Panjang
    if (noKk.length != 16) {
      return 'Nomor KK harus 16 digit angka';
    }

    // 2. Anti-dummy: semua digit sama
    if (_isAllSameDigit(noKk)) {
      return 'Nomor KK tidak valid (angka tidak boleh semua sama)';
    }

    // 3. Anti-dummy: sekuensial naik atau turun
    if (_isSequential(noKk)) {
      return 'Nomor KK tidak valid (angka tidak boleh berurutan)';
    }

    // 4. Kode provinsi (2 digit pertama)
    final provCode = noKk.substring(0, 2);
    if (!_validProvinceCodes.contains(provCode)) {
      return 'Nomor KK tidak valid (kode wilayah "$provCode" tidak dikenal)';
    }

    return null;
  }

  /// Validasi NIK Anak.
  ///
  /// Pemeriksaan:
  /// - Harus tepat 16 digit angka.
  /// - Tidak boleh pola dummy (semua digit sama atau sekuensial).
  /// - 2 digit pertama harus kode provinsi valid.
  /// - Digit 13–16 (nomor urut) tidak boleh `0000`.
  /// - Jika [birthDate] diberikan: digit 7–12 harus cocok dengan tanggal
  ///   lahir dan [gender] anak sesuai aturan NIK Indonesia.
  ///
  /// [nik]       : 16 digit NIK yang akan divalidasi.
  /// [birthDate] : Tanggal lahir anak (nullable — jika null, skip cross-validation).
  /// [gender]    : `'Laki-laki'` atau `'Perempuan'`.
  ///
  /// Mengembalikan `null` jika valid, atau pesan error (String) jika tidak.
  static String? validateNik(
    String nik, {
    DateTime? birthDate,
    String? gender,
  }) {
    // 1. Panjang
    if (nik.length != 16) {
      return 'NIK Anak harus 16 digit angka';
    }

    // 2. Anti-dummy: semua digit sama
    if (_isAllSameDigit(nik)) {
      return 'NIK tidak valid (angka tidak boleh semua sama)';
    }

    // 3. Anti-dummy: sekuensial naik atau turun
    if (_isSequential(nik)) {
      return 'NIK tidak valid (angka tidak boleh berurutan)';
    }

    // 4. Kode provinsi (2 digit pertama)
    final provCode = nik.substring(0, 2);
    if (!_validProvinceCodes.contains(provCode)) {
      return 'NIK tidak valid (kode wilayah "$provCode" tidak dikenal)';
    }

    // 5. Nomor urut (digit 13–16) tidak boleh 0000
    final seqNum = nik.substring(12, 16);
    if (seqNum == '0000') {
      return 'NIK tidak valid (nomor urut tidak boleh 0000)';
    }

    // 6. Cross-validation tanggal lahir & jenis kelamin (jika birthDate tersedia)
    if (birthDate != null) {
      final dayStr   = nik.substring(6, 8);
      final monthStr = nik.substring(8, 10);
      final yearStr  = nik.substring(10, 12);

      final dayInt   = int.tryParse(dayStr);
      final monthInt = int.tryParse(monthStr);
      final yearInt  = int.tryParse(yearStr);

      if (dayInt == null || monthInt == null || yearInt == null) {
        return 'NIK tidak valid (format tanggal lahir pada NIK tidak dikenali)';
      }

      // Perempuan: hari di NIK = hari lahir + 40
      final isPerempuan =
          gender != null && gender.toLowerCase().contains('perempuan');
      final effectiveDay = isPerempuan ? dayInt - 40 : dayInt;

      // Pastikan hari efektif masuk rentang 1–31
      if (effectiveDay < 1 || effectiveDay > 31) {
        return 'NIK tidak sesuai dengan jenis kelamin ananda. '
            'Periksa kembali dokumen KK/KIA.';
      }

      // Cocokkan dengan tanggal lahir anak
      final birthDay        = birthDate.day;
      final birthMonth      = birthDate.month;
      final birthYearShort  = birthDate.year % 100; // 2 digit terakhir tahun

      if (effectiveDay != birthDay ||
          monthInt != birthMonth ||
          yearInt != birthYearShort) {
        return 'NIK tidak sesuai dengan tanggal lahir ananda. '
            'Periksa kembali dokumen KK/KIA.';
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Mengembalikan true jika seluruh karakter dalam [s] identik.
  /// Contoh: `'1111111111111111'` → true.
  static bool _isAllSameDigit(String s) {
    if (s.isEmpty) return false;
    final first = s[0];
    return s.split('').every((c) => c == first);
  }

  /// Mengembalikan true jika [s] merupakan deretan digit naik atau turun
  /// secara siklik (wrap-around 0–9).
  /// Contoh naik : `'1234567890123456'` → true.
  /// Contoh turun: `'9876543210987654'` → true.
  static bool _isSequential(String s) {
    if (s.length < 4) return false;

    bool asc  = true;
    bool desc = true;

    for (int i = 1; i < s.length; i++) {
      final cur  = int.parse(s[i]);
      final prev = int.parse(s[i - 1]);

      // Naik siklik: (cur - prev + 10) % 10 == 1
      if ((cur - prev + 10) % 10 != 1) asc = false;
      // Turun siklik: (prev - cur + 10) % 10 == 1
      if ((prev - cur + 10) % 10 != 1) desc = false;

      // Hentikan lebih awal jika keduanya sudah false
      if (!asc && !desc) return false;
    }

    return asc || desc;
  }
}

