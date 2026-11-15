import 'dart:math';

import '../../../core/services/soal_service.dart';
import '../../../models/soal_model.dart';

/// Controller untuk mengatur logika putaran kuis:
/// memuat bank soal aktif, mengacak secara acak tanpa duplikat,
/// dan menyediakan 10 soal unik per putaran kuis User.
class GameController {
  /// Jumlah soal per putaran kuis
  static const int totalSoalPerPutaran = 10;

  /// Jumlah sesi per putaran (masing-masing 2 soal)
  static const int totalSesi = 5;

  /// Poin per soal yang dijawab benar
  static const int poinPerSoal = 25;

  /// Maksimum poin dalam satu putaran (10 soal × 25)
  static const int maksimalPoin = totalSoalPerPutaran * poinPerSoal;

  /// Waktu per soal dalam detik
  static const int detikPerSoal = 30;

  // ──────────────────────────────────────────────────────────────────
  // LOAD & SHUFFLE
  // ──────────────────────────────────────────────────────────────────

  /// Menghasilkan daftar [totalSoalPerPutaran] (10) soal unik yang sudah diacak
  /// dari seluruh bank soal yang berstatus aktif.
  ///
  /// - Mengambil seluruh soal aktif dari database / cache
  /// - Mengacak menggunakan [Random] sehingga kombinasi & urutan selalu baru
  /// - Bebas duplikasi dalam satu putaran kuis
  /// - Soal baru yang ditambahkan Admin langsung ikut masuk ke dalam kolam kuis
  static Future<List<SoalModel>> generatePutaranBaru() async {
    // Ambil soal aktif dari bank soal (seluruh 25 soal atau lebih)
    final bankSoalAktif = await SoalService.getSoalAktif();

    // Fallback jika bank aktif masih kosong, muat soal awal
    final List<SoalModel> pool = bankSoalAktif.isNotEmpty
        ? List<SoalModel>.from(bankSoalAktif)
        : (await SoalService.loadInitialSoal()).where((s) => s.isActive).toList();

    // Acak seluruh bank soal
    final random = Random();
    pool.shuffle(random);

    // Ambil 10 soal pertama dari hasil acak tanpa duplikat
    if (pool.length <= totalSoalPerPutaran) {
      return pool;
    }
    return pool.sublist(0, totalSoalPerPutaran);
  }

  // ──────────────────────────────────────────────────────────────────
  // KALKULASI SKOR
  // ──────────────────────────────────────────────────────────────────

  /// Menghitung jumlah jawaban benar dari daftar hasil soal.
  static int hitungJumlahBenar(List<HasilSoal> hasil) =>
      hasil.where((h) => !h.diSkip && h.benar).length;

  /// Menghitung total poin dari daftar hasil soal.
  static int hitungTotalPoin(List<HasilSoal> hasil) =>
      hitungJumlahBenar(hasil) * poinPerSoal;
}
