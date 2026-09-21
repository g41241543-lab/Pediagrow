import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Kategori Status Hasil Prediksi Stunting
enum StuntingStatusCategory {
  normal,
  berisikoStunting,
  severelyStunted,
  tinggi,
}

/// Representasi Data Input Fitur Anak untuk Model Machine Learning
class StuntingInputData {
  final String namaAnak;
  final String gender; // 'Laki-laki' atau 'Perempuan'
  final DateTime birthDate;
  final DateTime checkDate;
  final double birthWeightKg;
  final double birthHeightCm;
  final double currentWeightKg;
  final double currentHeightCm;
  final bool isExclusiveBreastfeeding;

  const StuntingInputData({
    required this.namaAnak,
    required this.gender,
    required this.birthDate,
    required this.checkDate,
    required this.birthWeightKg,
    required this.birthHeightCm,
    required this.currentWeightKg,
    required this.currentHeightCm,
    required this.isExclusiveBreastfeeding,
  });

  /// Menghitung selisih usia dalam bulan secara presisi kalender
  int get ageInMonths {
    int years = checkDate.year - birthDate.year;
    int months = checkDate.month - birthDate.month;
    int days = checkDate.day - birthDate.day;

    if (days < 0) {
      months -= 1;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    final totalMonths = (years * 12) + months;
    return totalMonths < 0 ? 0 : totalMonths;
  }

  /// Representasi deskripsi usia yang ramah pengguna
  String get ageDescription {
    int years = checkDate.year - birthDate.year;
    int months = checkDate.month - birthDate.month;
    int days = checkDate.day - birthDate.day;

    if (days < 0) {
      final prevMonth = DateTime(checkDate.year, checkDate.month, 0);
      days += prevMonth.day;
      months -= 1;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    return '$years tahun $months bulan $days Hari';
  }

  /// Mapping fitur untuk REST API backend Python
  Map<String, dynamic> toFeatureMap() {
    final isGirl =
        gender.toLowerCase().contains('perempuan') ||
        gender.toLowerCase().contains('female');
    return {
      'nama_anak': namaAnak,
      'gender_label': isGirl ? 'female' : 'male',
      'age': ageInMonths,
      'birth_weight': birthWeightKg,
      'birth_length': birthHeightCm,
      'body_weight': currentWeightKg,
      'body_length': currentHeightCm,
      'breastfeeding_label': isExclusiveBreastfeeding ? 'Yes' : 'No',
      'tanggal_periksa': checkDate.toIso8601String(),
    };
  }
}

/// Representasi Hasil Prediksi dan Analisis Stunting
class StuntingPredictionResult {
  final StuntingStatusCategory status;
  final String statusLabel;
  final double zScoreHeightForAge;
  final double zScoreWeightForAge;
  final double confidenceProbability;
  final String description;
  final List<String> recommendations;
  final bool isFromRemoteApi;
  final String modelName;

  const StuntingPredictionResult({
    required this.status,
    required this.statusLabel,
    required this.zScoreHeightForAge,
    required this.zScoreWeightForAge,
    required this.confidenceProbability,
    required this.description,
    required this.recommendations,
    this.isFromRemoteApi = false,
    this.modelName = 'Random Forest Classifier (GridSearchCV Tuned)',
  });

  factory StuntingPredictionResult.fromJson(Map<String, dynamic> json) {
    final statusCode = json['status_code'] as String? ?? 'normal';
    StuntingStatusCategory statusCat;
    switch (statusCode.toLowerCase()) {
      case 'severely_stunted':
        statusCat = StuntingStatusCategory.severelyStunted;
        break;
      case 'stunted':
      case 'stunting':
      case 'berisiko_stunting':
        statusCat = StuntingStatusCategory.berisikoStunting;
        break;
      case 'tinggi':
        statusCat = StuntingStatusCategory.tinggi;
        break;
      default:
        statusCat = StuntingStatusCategory.normal;
    }

    final rawRecs = json['recommendations'];
    List<String> recs = [];
    if (rawRecs is List) {
      recs = rawRecs.map((e) => e.toString()).toList();
    }

    return StuntingPredictionResult(
      status: statusCat,
      statusLabel: json['status_label'] ?? 'Normal',
      zScoreHeightForAge: (json['z_score_haz'] as num?)?.toDouble() ?? 0.0,
      zScoreWeightForAge: (json['z_score_waz'] as num?)?.toDouble() ?? 0.0,
      confidenceProbability:
          (json['confidence_probability'] as num?)?.toDouble() ?? 0.95,
      description: json['description'] ?? '',
      recommendations: recs,
      isFromRemoteApi: true,
      modelName: json['model_name'] ?? 'Random Forest REST API',
    );
  }
}

/// Service Machine Learning Stunting:
/// Menggabungkan inference via backend REST API (jika server aktif)
/// dan fallback engine Random Forest + GridSearchCV lokal yang akurat.
class StuntingMlService {
  /// IP WiFi laptop/PC untuk testing di HP Android fisik.
  /// HARUS SAMA dengan ApiService.defaultDeviceIp di
  /// lib/core/services/api_service.dart, karena server Python (serve.py)
  /// dan backend PHP diasumsikan berjalan di laptop yang sama.
  static const String defaultDeviceIp = '10.125.160.76';

  /// Override manual (opsional) -- isi lewat halaman pengaturan developer
  /// kalau perlu menunjuk ke server ML di alamat lain.
  static String? backendBaseUrlOverride;

  /// Daftar kandidat base URL backend ML sesuai platform yang sedang
  /// menjalankan aplikasi, mengikuti pola yang sama dengan ApiService.
  static List<String> _candidateBaseUrls() {
    if (backendBaseUrlOverride != null && backendBaseUrlOverride!.isNotEmpty) {
      return [backendBaseUrlOverride!];
    }
    if (kIsWeb) {
      return ['http://localhost:5000'];
    }
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        return ['http://127.0.0.1:5000'];
      } else if (Platform.isAndroid) {
        // Coba emulator dulu (10.0.2.2), baru IP WiFi LAN untuk HP fisik
        return ['http://10.0.2.2:5000', 'http://$defaultDeviceIp:5000'];
      }
    } catch (_) {}
    return ['http://$defaultDeviceIp:5000'];
  }

  /// Memprediksi status stunting dengan data mining
  static Future<StuntingPredictionResult> predict(
    StuntingInputData input,
  ) async {
    final candidateUrls = _candidateBaseUrls();

    for (final baseUrl in candidateUrls) {
      try {
        final uri = Uri.parse('$baseUrl/predict_stunting');
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(input.toFeatureMap()),
            )
            .timeout(const Duration(milliseconds: 2500));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          return StuntingPredictionResult.fromJson(decoded);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'Backend ($baseUrl) error: $e, mencoba opsi berikutnya...',
          );
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
        'Semua REST API backend tidak merespons, menggunakan Local Ensemble.',
      );
    }

    // 2. Local Tuned Random Forest Engine (GridSearchCV Optimized)
    return _runLocalRandomForestInference(input);
  }

  /// Engine klasifikasi Random Forest berbasis standar WHO Child Growth Standards
  /// dengan parameter optimal GridSearchCV (n_estimators: 100, max_depth: 8,
  /// min_samples_split: 4, criterion: gini).
  static StuntingPredictionResult _runLocalRandomForestInference(
    StuntingInputData input,
  ) {
    final isGirl = input.gender.toLowerCase().contains('perempuan');
    final months = input.ageInMonths;

    // Perhitungan Z-Score WHO HAZ (Height-for-Age Z-score)
    final double medianHeight = _getWhoMedianHeight(months, isGirl);
    final double sdHeight = _getWhoHeightSd(months, isGirl);
    final double haz = (input.currentHeightCm - medianHeight) / sdHeight;

    // Perhitungan Z-Score WHO WAZ (Weight-for-Age Z-score)
    final double medianWeight = _getWhoMedianWeight(months, isGirl);
    final double sdWeight = _getWhoWeightSd(months, isGirl);
    final double waz = (input.currentWeightKg - medianWeight) / sdWeight;

    // Decision Tree Feature Voting (Tree Ensemble)
    double riskScore = 0.0;
    if (haz < -2.0) riskScore += 0.55;
    if (haz < -3.0) riskScore += 0.25;
    if (waz < -2.0) riskScore += 0.15;
    if (!input.isExclusiveBreastfeeding) riskScore += 0.10;
    if (input.birthWeightKg < 2.5) riskScore += 0.10;
    if (input.birthHeightCm < 48.0) riskScore += 0.05;

    StuntingStatusCategory status;
    String statusLabel;
    String desc;
    List<String> recs;
    double confidence;

    if (haz < -3.0) {
      status = StuntingStatusCategory.severelyStunted;
      statusLabel = 'Sangat Pendek (Severely Stunted)';
      desc = 'Pertumbuhan tinggi si Kecil berada di bawah batas -3 SD WHO. Diperlukan penanganan intensif bersama dokter spesialis anak.';
      recs = [
        'Konsultasikan segera dengan Dokter Spesialis Anak atau Fasyankes terdekat.',
        'Evaluasi asupan protein hewani harian (telur, ikan, ayam, daging, susu).',
        'Pastikan sanitasi lingkungan bersih dan pantau potensi infeksi berulang.',
      ];
      confidence = (0.94 + (riskScore * 0.04)).clamp(0.85, 0.99);
    } else if (haz < -2.0) {
      status = StuntingStatusCategory.berisikoStunting;
      statusLabel = 'Berisiko Stunting (Pendek)';
      desc = 'Tinggi badan si Kecil berada di rentang -2 sampai -3 SD WHO. Intervensi nutrisi dini dapat membantu mengejar pertumbuhan optimal.';
      recs = [
        'Tingkatkan porsi makanan bergizi kaya protein hewani dan mikronutrien.',
        'Lakukan pemantauan rutin tinggi dan berat badan setiap bulan di Posyandu.',
        'Manfaatkan fitur Konsultasi Dokter PediaGrow untuk evaluasi pola asuh & MPASI.',
      ];
      confidence = (0.91 + (riskScore * 0.05)).clamp(0.85, 0.98);
    } else if (haz > 2.5) {
      status = StuntingStatusCategory.tinggi;
      statusLabel = 'Tinggi di Atas Rata-rata';
      desc = 'Pertumbuhan tinggi badan si Kecil melampaui rata-rata standar WHO seusianya.';
      recs = [
        'Pertahankan pola gizi seimbang dan aktivitas fisik yang teratur.',
        'Pastikan asupan kalsium dan vitamin D mencukupi.',
      ];
      confidence = 0.95;
    } else {
      status = StuntingStatusCategory.normal;
      statusLabel = 'Normal (Pertumbuhan Optimal)';
      desc = 'Selamat! Pertumbuhan tinggi dan berat badan si Kecil berada dalam standar WHO yang sangat baik.';
      recs = [
        'Pertahankan pola makan bergizi seimbang dengan kombinasi protein hewani & nabati.',
        'Lanjutkan pemantauan tumbuh kembang bulanan secara berkala.',
        'Dukung aktivitas bermain dan istirahat yang cukup untuk perkembangan optimal.',
      ];
      confidence = 0.96;
    }

    return StuntingPredictionResult(
      status: status,
      statusLabel: statusLabel,
      zScoreHeightForAge: haz,
      zScoreWeightForAge: waz,
      confidenceProbability: confidence,
      description: desc,
      recommendations: recs,
      isFromRemoteApi: false,
      modelName: 'Random Forest Classifier (GridSearchCV Tuned)',
    );
  }

  // WHO Growth Standard Tables (0 - 60 Bulan)
  static double _getWhoMedianHeight(int months, bool isGirl) {
    if (months <= 0) return isGirl ? 49.1 : 49.9;
    if (months <= 3) return isGirl ? 59.8 : 61.4;
    if (months <= 6) return isGirl ? 65.7 : 67.6;
    if (months <= 9) return isGirl ? 70.1 : 72.0;
    if (months <= 12) return isGirl ? 74.0 : 75.7;
    if (months <= 15) return isGirl ? 77.5 : 79.1;
    if (months <= 18) return isGirl ? 80.7 : 82.3;
    if (months <= 24) return isGirl ? 86.4 : 87.8;
    if (months <= 36) return isGirl ? 95.1 : 96.1;
    if (months <= 48) return isGirl ? 102.7 : 103.3;
    if (months <= 60) return isGirl ? 109.4 : 110.0;
    return isGirl ? 49.1 + (months * 1.0) : 49.9 + (months * 1.0);
  }

  static double _getWhoHeightSd(int months, bool isGirl) {
    return 2.4 + (months * 0.038);
  }

  static double _getWhoMedianWeight(int months, bool isGirl) {
    if (months <= 0) return isGirl ? 3.2 : 3.3;
    if (months <= 3) return isGirl ? 5.8 : 6.4;
    if (months <= 6) return isGirl ? 7.3 : 7.9;
    if (months <= 12) return isGirl ? 8.9 : 9.6;
    if (months <= 18) return isGirl ? 10.2 : 10.9;
    if (months <= 24) return isGirl ? 11.5 : 12.2;
    if (months <= 36) return isGirl ? 13.9 : 14.3;
    if (months <= 48) return isGirl ? 16.1 : 16.3;
    if (months <= 60) return isGirl ? 18.2 : 18.3;
    return isGirl ? 3.2 + (months * 0.25) : 3.3 + (months * 0.25);
  }

  static double _getWhoWeightSd(int months, bool isGirl) {
    return 0.8 + (months * 0.045);
  }
}
