import 'package:flutter/foundation.dart';
import 'package:pediagrow/features/Grafik_Pertumbuhan/services/who_growth_data.dart';

import '../../../core/services/child_service.dart';
import '../../../models/child_model.dart';
import '../models/growth_record_model.dart';
import 'zscore_calculator.dart';

/// Helper function untuk format tanggal Indonesia
String formatTanggalIndonesia(DateTime date) {
  const List<String> months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Service singleton untuk mengelola data pertumbuhan dan riwayat pengukuran anak.
///
/// Mendukung [ValueNotifier] agar perubahan data pertumbuhan secara reaktif
/// langsung memperbarui grafik, kartu statistik, dan riwayat secara instan.
class GrowthService {
  static final GrowthService _instance = GrowthService._internal();
  factory GrowthService() => _instance;
  GrowthService._internal() {
    _initService();
  }

  /// State riwayat pertumbuhan per child ID
  final ValueNotifier<Map<String, List<GrowthRecordModel>>> recordsNotifier =
      ValueNotifier<Map<String, List<GrowthRecordModel>>>({});

  void _initService() {
    // Dengarkan perubahan profil anak dari ChildService
    ChildService().childrenNotifier.addListener(_syncWithChildService);
    _syncWithChildService();
  }

  /// Sinkronisasi titik data awal (saat lahir) untuk setiap anak yang terdaftar
  void _syncWithChildService() {
    final children = ChildService().children;
    final currentMap = Map<String, List<GrowthRecordModel>>.from(
      recordsNotifier.value,
    );

    for (final child in children) {
      if (!currentMap.containsKey(child.id) || currentMap[child.id]!.isEmpty) {
        currentMap[child.id] = _generateInitialRecordsForChild(child);
      }
    }

    recordsNotifier.value = currentMap;
  }

  /// Membuat titik data awal dari data kelahiran anak + beberapa riwayat contoh
  /// jika anak sudah berusia beberapa bulan, agar grafik memiliki kontinuitas realistis.
  List<GrowthRecordModel> _generateInitialRecordsForChild(ChildModel child) {
    final List<GrowthRecordModel> records = [];
    final isGirl = child.gender.toLowerCase().contains('perempuan');
    final birthDate =
        child.birthDate ??
        DateTime.now().subtract(const Duration(days: 365 + 90)); // ~1.2 tahun

    // 1. Titik Data Pertama: Saat Lahir (Usia 0 Bulan 0 Hari)
    final birthWeight = child.weightKg ?? (isGirl ? 3.2 : 3.3);
    final birthHeight = child.heightCm ?? (isGirl ? 49.1 : 49.9);
    final birthHead = child.headCircumferenceCm ?? (isGirl ? 33.9 : 34.5);

    final zWfhBirth = ZScoreCalculator.calculateZScoreWeightForHeight(
      weightKg: birthWeight,
      heightCm: birthHeight,
      isGirl: isGirl,
    );

    records.add(
      GrowthRecordModel(
        id: 'rec_birth_${child.id}',
        childId: child.id,
        date: birthDate,
        ageMonths: 0,
        ageDays: 0,
        ageFormatted: '0 tahun 0 bulan 0 hari',
        weightKg: birthWeight,
        heightCm: birthHeight,
        headCircumferenceCm: birthHead,
        zScoreWeightForAge: ZScoreCalculator.calculateZScoreWeightForAge(
          weightKg: birthWeight,
          ageMonths: 0,
          isGirl: isGirl,
        ),
        zScoreHeightForAge: ZScoreCalculator.calculateZScoreHeightForAge(
          heightCm: birthHeight,
          ageMonths: 0,
          isGirl: isGirl,
        ),
        zScoreHeadForAge: ZScoreCalculator.calculateZScoreHeadForAge(
          headCircumferenceCm: birthHead,
          ageMonths: 0,
          isGirl: isGirl,
        ),
        zScoreWeightForHeight: zWfhBirth,
        statusGizi: ZScoreCalculator.classifyStatusGizi(zWfhBirth),
        isBirthRecord: true,
        notes: 'Data pengukuran saat lahir',
      ),
    );

    // 2. Tambahkan titik data pengukuran bertahap sesuai usia anak saat ini
    final now = DateTime.now();
    final totalDays = now.difference(birthDate).inDays;
    final totalMonths = (totalDays / 30.4375).floor();

    if (totalMonths >= 3) {
      // Riwayat bulan ke-3
      final dateM3 = birthDate.add(const Duration(days: 90));
      final w3 = isGirl ? 5.8 : 6.3;
      final h3 = isGirl ? 59.8 : 61.4;
      final hc3 = isGirl ? 39.5 : 40.5;
      final z3 = ZScoreCalculator.calculateZScoreWeightForHeight(
        weightKg: w3,
        heightCm: h3,
        isGirl: isGirl,
      );
      records.add(
        GrowthRecordModel(
          id: 'rec_m3_${child.id}',
          childId: child.id,
          date: dateM3,
          ageMonths: 3,
          ageDays: 90,
          ageFormatted: '0 tahun 3 bulan 0 hari',
          weightKg: w3,
          heightCm: h3,
          headCircumferenceCm: hc3,
          zScoreWeightForAge: ZScoreCalculator.calculateZScoreWeightForAge(
            weightKg: w3,
            ageMonths: 3,
            isGirl: isGirl,
          ),
          zScoreHeightForAge: ZScoreCalculator.calculateZScoreHeightForAge(
            heightCm: h3,
            ageMonths: 3,
            isGirl: isGirl,
          ),
          zScoreHeadForAge: ZScoreCalculator.calculateZScoreHeadForAge(
            headCircumferenceCm: hc3,
            ageMonths: 3,
            isGirl: isGirl,
          ),
          zScoreWeightForHeight: z3,
          statusGizi: ZScoreCalculator.classifyStatusGizi(z3),
          notes: 'Pemeriksaan Posyandu',
        ),
      );
    }

    if (totalMonths >= 6) {
      // Riwayat bulan ke-6
      final dateM6 = birthDate.add(const Duration(days: 180));
      final w6 = isGirl ? 7.3 : 7.9;
      final h6 = isGirl ? 65.7 : 67.6;
      final hc6 = isGirl ? 42.2 : 43.3;
      final z6 = ZScoreCalculator.calculateZScoreWeightForHeight(
        weightKg: w6,
        heightCm: h6,
        isGirl: isGirl,
      );
      records.add(
        GrowthRecordModel(
          id: 'rec_m6_${child.id}',
          childId: child.id,
          date: dateM6,
          ageMonths: 6,
          ageDays: 180,
          ageFormatted: '0 tahun 6 bulan 0 hari',
          weightKg: w6,
          heightCm: h6,
          headCircumferenceCm: hc6,
          zScoreWeightForAge: ZScoreCalculator.calculateZScoreWeightForAge(
            weightKg: w6,
            ageMonths: 6,
            isGirl: isGirl,
          ),
          zScoreHeightForAge: ZScoreCalculator.calculateZScoreHeightForAge(
            heightCm: h6,
            ageMonths: 6,
            isGirl: isGirl,
          ),
          zScoreHeadForAge: ZScoreCalculator.calculateZScoreHeadForAge(
            headCircumferenceCm: hc6,
            ageMonths: 6,
            isGirl: isGirl,
          ),
          zScoreWeightForHeight: z6,
          statusGizi: ZScoreCalculator.classifyStatusGizi(z6),
          notes: 'Pemeriksaan Puskesmas Rutin',
        ),
      );
    }

    if (totalMonths >= 12) {
      // Riwayat bulan ke-12
      final dateM12 = birthDate.add(const Duration(days: 365));
      final w12 = isGirl ? 8.9 : 9.6;
      final h12 = isGirl ? 74.0 : 75.7;
      final hc12 = isGirl ? 44.9 : 46.1;
      final z12 = ZScoreCalculator.calculateZScoreWeightForHeight(
        weightKg: w12,
        heightCm: h12,
        isGirl: isGirl,
      );
      records.add(
        GrowthRecordModel(
          id: 'rec_m12_${child.id}',
          childId: child.id,
          date: dateM12,
          ageMonths: 12,
          ageDays: 365,
          ageFormatted: '1 tahun 0 bulan 0 hari',
          weightKg: w12,
          heightCm: h12,
          headCircumferenceCm: hc12,
          zScoreWeightForAge: ZScoreCalculator.calculateZScoreWeightForAge(
            weightKg: w12,
            ageMonths: 12,
            isGirl: isGirl,
          ),
          zScoreHeightForAge: ZScoreCalculator.calculateZScoreHeightForAge(
            heightCm: h12,
            ageMonths: 12,
            isGirl: isGirl,
          ),
          zScoreHeadForAge: ZScoreCalculator.calculateZScoreHeadForAge(
            headCircumferenceCm: hc12,
            ageMonths: 12,
            isGirl: isGirl,
          ),
          zScoreWeightForHeight: z12,
          statusGizi: ZScoreCalculator.classifyStatusGizi(z12),
          notes: 'Evaluasi Tumbuh Kembang 1 Tahun',
        ),
      );
    }

    return records;
  }

  /// Mengambil riwayat pertumbuhan untuk anak tertentu,
  /// terurut dari termuda ke tertua (cocok untuk plot grafik garis).
  List<GrowthRecordModel> getRecordsForChildOldestFirst(String childId) {
    final list = List<GrowthRecordModel>.from(
      recordsNotifier.value[childId] ?? <GrowthRecordModel>[],
    );
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Mengambil riwayat pertumbuhan untuk anak tertentu,
  /// terurut dari terbaru ke terlama (cocok untuk tabel riwayat & card).
  List<GrowthRecordModel> getRecordsForChildNewestFirst(String childId) {
    final list = List<GrowthRecordModel>.from(
      recordsNotifier.value[childId] ?? <GrowthRecordModel>[],
    );
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Mengambil pengukuran terbaru untuk anak tertentu
  GrowthRecordModel? getLatestRecord(String childId) {
    final list = getRecordsForChildNewestFirst(childId);
    if (list.isNotEmpty) return list.first;
    return null;
  }

  /// Menambahkan entri pertumbuhan baru
  void addRecord(GrowthRecordModel record) {
    final currentMap = Map<String, List<GrowthRecordModel>>.from(
      recordsNotifier.value,
    );
    final childList = List<GrowthRecordModel>.from(
      currentMap[record.childId] ?? <GrowthRecordModel>[],
    );

    childList.add(record);
    currentMap[record.childId] = childList;
    recordsNotifier.value = currentMap;
  }

  /// Menambahkan entri pengukuran yang didapat dari fitur Cek Stunting
  void addMeasurementFromStunting({
    required ChildModel child,
    required double weightKg,
    required double heightCm,
    double? headCircumferenceCm,
    DateTime? measurementDate,
    String? notes,
  }) {
    final date = measurementDate ?? DateTime.now();
    final birthDate = child.birthDate ?? date;
    final isGirl = child.gender.toLowerCase().contains('perempuan');

    final diffDays = date.difference(birthDate).inDays;
    final ageMonths = (diffDays / 30.4375).floor().clamp(0, 60);

    // Hitung usia dalam format "X tahun Y bulan Z hari"
    int years = date.year - birthDate.year;
    int months = date.month - birthDate.month;
    int days = date.day - birthDate.day;
    if (days < 0) {
      final prevMonth = DateTime(date.year, date.month, 0);
      days += prevMonth.day;
      months -= 1;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    final ageFormatted = '$years tahun $months bulan $days hari';

    // Perhitungan Z-Scores
    final zWfh = ZScoreCalculator.calculateZScoreWeightForHeight(
      weightKg: weightKg,
      heightCm: heightCm,
      isGirl: isGirl,
    );
    final zWfa = ZScoreCalculator.calculateZScoreWeightForAge(
      weightKg: weightKg,
      ageMonths: ageMonths,
      isGirl: isGirl,
    );
    final zHfa = ZScoreCalculator.calculateZScoreHeightForAge(
      heightCm: heightCm,
      ageMonths: ageMonths,
      isGirl: isGirl,
    );

    // Jika lingkar kepala tidak diisi, gunakan estimasi median WHO
    final effectiveHead =
        headCircumferenceCm ??
        (isGirl
            ? WhoGrowthData.getHeadCircumferenceForAgeGirls(ageMonths).m
            : WhoGrowthData.getHeadCircumferenceForAgeBoys(ageMonths).m);

    final zHcfa = ZScoreCalculator.calculateZScoreHeadForAge(
      headCircumferenceCm: effectiveHead,
      ageMonths: ageMonths,
      isGirl: isGirl,
    );

    final newRecord = GrowthRecordModel(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      childId: child.id,
      date: date,
      ageMonths: ageMonths,
      ageDays: diffDays,
      ageFormatted: ageFormatted,
      weightKg: weightKg,
      heightCm: heightCm,
      headCircumferenceCm: effectiveHead,
      zScoreWeightForAge: zWfa,
      zScoreHeightForAge: zHfa,
      zScoreHeadForAge: zHcfa,
      zScoreWeightForHeight: zWfh,
      statusGizi: ZScoreCalculator.classifyStatusGizi(zWfh),
      isBirthRecord: false,
      notes: notes ?? 'Hasil Pengukuran Cek Stunting',
    );

    addRecord(newRecord);
  }
}
