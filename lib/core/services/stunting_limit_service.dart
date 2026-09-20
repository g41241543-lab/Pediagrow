import 'dart:math' as math;
import '../../features/Grafik_Pertumbuhan/services/growth_service.dart';

/// Service untuk membatasi penggunaan fitur Cek Stunting.
///
/// Setiap profil anak hanya diperbolehkan melakukan Cek Stunting
/// **maksimal 2 kali per bulan kalender**.
/// Logika yang sama berlaku untuk "Data Pertumbuhan Baru" pada
/// halaman Grafik Pertumbuhan (keduanya memanggil FormCekStuntingPage).
///
/// Data tersimpan secara reaktif dan otomatis sinkron dengan riwayat pengukuran
/// di [GrowthService] serta dicatat per sesi aktif.
class StuntingLimitService {
  // Singleton
  static final StuntingLimitService _instance =
      StuntingLimitService._internal();
  factory StuntingLimitService() => _instance;
  StuntingLimitService._internal();

  /// Batas maksimum cek stunting per anak per bulan kalender
  static const int maxPerMonth = 2;

  /// Penyimpanan in-memory per sesi: key = "{childId}_{year}_{month}"
  final Map<String, int> _counts = {};

  /// Menghasilkan key unik berdasarkan ID anak, tahun, dan bulan.
  String _key(String childId, [DateTime? ref]) {
    final d = ref ?? DateTime.now();
    return '${childId}_${d.year}_${d.month}';
  }

  /// Mengembalikan jumlah cek stunting / data pertumbuhan pada bulan ini untuk [childId].
  /// Menggabungkan data pengukuran baru dari [GrowthService] dan hitungan sesi aktif.
  int countThisMonth(String childId, [DateTime? ref]) {
    final d = ref ?? DateTime.now();
    final memoryCount = _counts[_key(childId, d)] ?? 0;

    int growthCount = 0;
    try {
      final records = GrowthService().getRecordsForChildNewestFirst(childId);
      growthCount = records.where((r) {
        if (r.isBirthRecord) return false;
        if (r.id.startsWith('rec_birth_') ||
            r.id.startsWith('rec_m6_') ||
            r.id.startsWith('rec_m12_')) {
          return false;
        }
        return r.date.year == d.year && r.date.month == d.month;
      }).length;
    } catch (_) {}

    return math.max(memoryCount, growthCount);
  }

  /// Apakah [childId] masih diperbolehkan melakukan cek stunting bulan ini?
  bool canCheck(String childId, [DateTime? ref]) {
    return countThisMonth(childId, ref) < maxPerMonth;
  }

  /// Sisa kuota cek stunting bulan ini untuk [childId].
  int remaining(String childId, [DateTime? ref]) {
    final used = countThisMonth(childId, ref);
    final rem = maxPerMonth - used;
    return rem < 0 ? 0 : rem;
  }

  /// Mencatat satu sesi cek stunting yang berhasil dilakukan oleh [childId].
  void recordCheck(String childId, [DateTime? ref]) {
    final k = _key(childId, ref);
    _counts[k] = (_counts[k] ?? 0) + 1;
  }

  /// Mereset hitungan untuk [childId] pada bulan tertentu (untuk keperluan pengujian).
  void resetForTesting(String childId, [DateTime? ref]) {
    _counts.remove(_key(childId, ref));
  }
}
