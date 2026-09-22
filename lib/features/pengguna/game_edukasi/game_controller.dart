import 'dart:convert';
import 'package:flutter/services.dart';
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

  /// Memuat seluruh bank soal dari assets/data/soal_kuis.json.
  static Future<List<SoalModel>> _loadBankSoal() async {
    final String rawJson =
        await rootBundle.loadString('assets/data/soal_kuis.json');
    final List<dynamic> jsonList = json.decode(rawJson) as List<dynamic>;
    return jsonList
        .map((e) => SoalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Menghasilkan daftar [totalSoalPerPutaran] soal unik yang sudah diacak
  /// untuk satu putaran kuis baru.
  ///
  /// Jika bank soal memiliki lebih dari [totalSoalPerPutaran] soal, diambil
  /// sebanyak [totalSoalPerPutaran] secara acak tanpa duplikat.
  /// Jika bank soal ≤ [totalSoalPerPutaran], semua soal dipakai (juga diacak).
  static Future<List<SoalModel>> generatePutaranBaru() async {
    final bankSoal = await _loadBankSoal();
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
