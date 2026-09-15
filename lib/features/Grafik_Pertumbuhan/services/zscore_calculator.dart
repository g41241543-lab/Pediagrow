import 'dart:ui';
import 'who_growth_data.dart';

enum ChartIndicatorType {
  weight, // Berat Badan (kg)
  height, // Tinggi Badan (cm)
  headCircumference, // Lingkar Kepala (cm)
}

/// Helper kalkulator Antropometri & Z-score WHO / Permenkes RI No. 2 Tahun 2020
class ZScoreCalculator {
  /// Menghitung Z-score BB/TB (Berat Badan menurut Panjang/Tinggi Badan)
  static double calculateZScoreWeightForHeight({
    required double weightKg,
    required double heightCm,
    required bool isGirl,
  }) {
    if (weightKg <= 0 || heightCm <= 0) return 0.0;
    final lms = WhoGrowthData.getWeightForHeight(heightCm, isGirl);
    return lms.calculateZScore(weightKg);
  }

  /// Menghitung Z-score BB/U (Weight-for-Age)
  static double calculateZScoreWeightForAge({
    required double weightKg,
    required int ageMonths,
    required bool isGirl,
  }) {
    if (weightKg <= 0) return 0.0;
    final lms = isGirl
        ? WhoGrowthData.getWeightForAgeGirls(ageMonths)
        : WhoGrowthData.getWeightForAgeBoys(ageMonths);
    return lms.calculateZScore(weightKg);
  }

  /// Menghitung Z-score TB/U (Height-for-Age)
  static double calculateZScoreHeightForAge({
    required double heightCm,
    required int ageMonths,
    required bool isGirl,
  }) {
    if (heightCm <= 0) return 0.0;
    final lms = isGirl
        ? WhoGrowthData.getHeightForAgeGirls(ageMonths)
        : WhoGrowthData.getHeightForAgeBoys(ageMonths);
    return lms.calculateZScore(heightCm);
  }

  /// Menghitung Z-score LK/U (Head Circumference-for-Age)
  static double calculateZScoreHeadForAge({
    required double headCircumferenceCm,
    required int ageMonths,
    required bool isGirl,
  }) {
    if (headCircumferenceCm <= 0) return 0.0;
    final lms = isGirl
        ? WhoGrowthData.getHeadCircumferenceForAgeGirls(ageMonths)
        : WhoGrowthData.getHeadCircumferenceForAgeBoys(ageMonths);
    return lms.calculateZScore(headCircumferenceCm);
  }

  /// Mengklasifikasikan status gizi berdasarkan Z-score BB/TB sesuai spesifikasi:
  /// - 'Gizi Normal' jika Z-score berada pada rentang -3 SD s/d +3 SD
  /// - 'Gizi Buruk' jika Z-score di luar rentang tersebut (< -3 SD atau > +3 SD)
  static String classifyStatusGizi(double zScoreWeightForHeight) {
    if (zScoreWeightForHeight >= -3.0 && zScoreWeightForHeight <= 3.0) {
      return 'Gizi Normal';
    } else {
      return 'Gizi Buruk';
    }
  }

  /// Teks deskripsi penjelasan status gizi resmi
  static String getStatusDescription(String statusGizi) {
    if (statusGizi == 'Gizi Normal') {
      return 'Anak tergolong gizi baik. Pantau ulang berat badan dan tinggi badan secara berkala. Untuk konsultasi lebih lanjut, anda bisa jadwalkan kunjungan ke dokter spesialis anak.';
    } else {
      return 'Anak mengalami gizi buruk. Segera bawa ke fasilitas kesehatan terdekat. Untuk konsultasi lebih lanjut, anda bisa jadwalkan kunjungan ke dokter spesialis anak.';
    }
  }

  /// Warna teks & border status gizi
  static Color getStatusColor(String statusGizi) {
    if (statusGizi == 'Gizi Normal') {
      return const Color(0xFF2E7D32); // Hijau botol elegan
    } else {
      return const Color(0xFFB13535); // Merah peringatan
    }
  }

  /// Warna latar belakang (badge/bar) status gizi
  static Color getStatusBgColor(String statusGizi) {
    if (statusGizi == 'Gizi Normal') {
      return const Color(0xFFE8F5E9); // Hijau pastel lembut
    } else {
      return const Color(0xFFFFEBEE); // Merah pastel lembut
    }
  }

  /// Mengambil titik kurva persentil WHO untuk bulan 0..60
  /// Mengembalikan map yang memetakan bulan ke nilai antropometri untuk target SD
  static Map<int, double> getPercentileCurve({
    required ChartIndicatorType indicator,
    required bool isGirl,
    required double targetZ, // e.g. -3.0, -2.0, 0.0, +2.0, +3.0
  }) {
    final Map<int, double> result = {};
    for (int m = 0; m <= 60; m++) {
      LmsValues lms;
      switch (indicator) {
        case ChartIndicatorType.weight:
          lms = isGirl
              ? WhoGrowthData.getWeightForAgeGirls(m)
              : WhoGrowthData.getWeightForAgeBoys(m);
          break;
        case ChartIndicatorType.height:
          lms = isGirl
              ? WhoGrowthData.getHeightForAgeGirls(m)
              : WhoGrowthData.getHeightForAgeBoys(m);
          break;
        case ChartIndicatorType.headCircumference:
          lms = isGirl
              ? WhoGrowthData.getHeadCircumferenceForAgeGirls(m)
              : WhoGrowthData.getHeadCircumferenceForAgeBoys(m);
          break;
      }
      result[m] = lms.valueForZ(targetZ);
    }
    return result;
  }
}
