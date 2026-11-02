import '../../../core/services/soal_service.dart';
import '../../../models/soal_model.dart';

/// Controller sederhana (tanpa package eksternal) untuk mengatur
/// logika putaran kuis: memuat soal dari JSON, mengacak, dan
/// menyediakan 10 soal unik per putaran.
///
/// Dipakai langsung di GameMulaiPage untuk men-generate putaran baru.
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

  /// Memuat bank soal secara instan dari cache SoalService atau asset lokal.
  static Future<List<SoalModel>> _loadBankSoal() async {
    final cached = SoalService.cachedSoal;
    if (cached != null && cached.isNotEmpty) {
      return List<SoalModel>.from(cached);
    }
    return SoalService.loadInitialSoal();
  }

  /// Menghasilkan daftar [totalSoalPerPutaran] soal unik yang sudah diacak
  /// untuk satu putaran kuis baru.
  ///
  /// Jika bank soal memiliki lebih dari [totalSoalPerPutaran] soal, diambil
  /// sebanyak [totalSoalPerPutaran] secara acak tanpa duplikat.
  /// Jika bank soal ≤ [totalSoalPerPutaran], semua soal dipakai (juga diacak).
  static Future<List<SoalModel>> generatePutaranBaru() async {
    final rawBankSoal = await _loadBankSoal();
    // Revisi S-1: Soal nomor 11 sampai 20 tidak diikutsertakan dalam pengacakan kuis
    final bankSoal = rawBankSoal.where((s) => s.id <= 10).toList();
    bankSoal.shuffle();

    if (bankSoal.length <= totalSoalPerPutaran) {
      return bankSoal;
    }
    return bankSoal.sublist(0, totalSoalPerPutaran);
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
