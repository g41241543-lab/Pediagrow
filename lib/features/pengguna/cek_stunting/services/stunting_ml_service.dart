import 'stunting_rf_model.dart';

/// Kategori Status Hasil Prediksi Stunting
///
/// Catatan: model Random Forest hanya membedakan 2 kelas (Yes/No), sehingga
/// hanya [normal] dan [berisikoStunting] yang dihasilkan. [severelyStunted]
/// dan [tinggi] dipertahankan agar kode UI lain tetap bisa dikompilasi.
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

  /// Mapping fitur (tetap dipertahankan, mis. untuk disimpan ke backend PHP)
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

  /// Perkiraan z-score dari tabel WHO yang disederhanakan. BUKAN keluaran
  /// Random Forest; hanya info tambahan untuk tampilan.
  final double zScoreHeightForAge;
  final double zScoreWeightForAge;

  /// Tingkat kesepakatan 100 pohon (0.5 - 1.0), bukan peluang medis.
  final double confidenceProbability;
  final String description;
  final List<String> recommendations;
  final bool isFromRemoteApi;
  final String modelName;

  /// false jika input di luar rentang data training (usia 1-59 bulan, dll).
  /// UI sebaiknya menampilkan peringatan ketika nilainya false.
  final bool isInTrainingRange;

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
    this.isInTrainingRange = true,
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

/// Service Machine Learning Stunting.
///
/// Seluruh inferensi Random Forest (100 pohon, hasil GridSearchCV) berjalan
/// langsung di dalam aplikasi lewat [StuntingRandomForest]; tidak memakai
/// server Python, REST API, maupun koneksi internet.
class StuntingMlService {
  /// Rentang usia (bulan) pada data training. Dipakai juga untuk validasi form.
  static const int minSupportedAgeMonths = 1;
  static const int maxSupportedAgeMonths = 59;

  /// Dipertahankan hanya agar file lain yang masih mereferensikannya tidak
  /// error saat build. Tidak lagi berpengaruh karena tidak ada panggilan HTTP.
  @Deprecated('Tidak dipakai lagi: model Random Forest sudah tertanam di aplikasi.')
  static const String defaultDeviceIp = '10.125.173.83';

  @Deprecated('Tidak dipakai lagi: model Random Forest sudah tertanam di aplikasi.')
  static String? backendBaseUrlOverride;

  /// Memprediksi status stunting. Tetap `Future` agar pemanggil yang memakai
  /// `await` tidak perlu diubah.
  static Future<StuntingPredictionResult> predict(
    StuntingInputData input,
  ) async {
    return _runEmbeddedRandomForest(input);
  }

  static StuntingPredictionResult _runEmbeddedRandomForest(
    StuntingInputData input,
  ) {
    final g = input.gender.toLowerCase();
    final isGirl = g.contains('perempuan') || g.contains('female');
    final months = input.ageInMonths;

    // Urutan fitur HARUS sama dengan training:
    // Gender(female=0, male=1), Age, Birth Weight, Birth Length,
    // Body Weight, Body Length, Breastfeeding(No=0, Yes=1)
    final features = <double>[
      isGirl ? 0.0 : 1.0,
      months.toDouble(),
      input.birthWeightKg,
      input.birthHeightCm,
      input.currentWeightKg,
      input.currentHeightCm,
      input.isExclusiveBreastfeeding ? 1.0 : 0.0,
    ];

    final pYes = StuntingRandomForest.predictProbaYes(features);
    final isStunting = pYes > 0.5; // seri 0.5 -> "No", sama seperti scikit-learn
    final confidence =
        ((isStunting ? pYes : 1.0 - pYes) * 1000).round() / 1000;

    final inRange =
        months >= minSupportedAgeMonths &&
        months <= maxSupportedAgeMonths &&
        input.birthWeightKg >= 1.8 &&
        input.birthWeightKg <= 4 &&
        input.birthHeightCm >= 42 &&
        input.birthHeightCm <= 53 &&
        input.currentWeightKg >= 2.9 &&
        input.currentWeightKg <= 24.5 &&
        input.currentHeightCm >= 53 &&
        input.currentHeightCm <= 111;

    const outOfRangeNote =
        ' Perhatian: data si Kecil berada di luar rentang data pelatihan model '
        '(usia 1-59 bulan), sehingga hasil ini kurang dapat diandalkan.';

    // Perkiraan z-score WHO (hanya info tambahan, bukan keluaran model)
    final haz =
        (input.currentHeightCm - _getWhoMedianHeight(months, isGirl)) /
        _getWhoHeightSd(months, isGirl);
    final waz =
        (input.currentWeightKg - _getWhoMedianWeight(months, isGirl)) /
        _getWhoWeightSd(months, isGirl);

    final StuntingStatusCategory status;
    final String statusLabel;
    final String desc;
    final List<String> recs;

    if (isStunting) {
      status = StuntingStatusCategory.berisikoStunting;
      statusLabel = 'Berisiko Stunting';
      desc =
          'Model Random Forest mengenali pola data si Kecil yang mirip dengan '
          'kasus stunting pada data pelatihan. Hasil ini adalah skrining awal, '
          'bukan diagnosis; konfirmasikan dengan pengukuran dan tenaga kesehatan.';
      recs = [
        'Tingkatkan porsi makanan bergizi kaya protein hewani dan mikronutrien.',
        'Lakukan pemantauan rutin tinggi dan berat badan setiap bulan di Posyandu.',
        'Manfaatkan fitur Konsultasi Dokter PediaGrow untuk evaluasi pola asuh & MPASI.',
      ];
    } else {
      status = StuntingStatusCategory.normal;
      statusLabel = 'Normal (Pertumbuhan Sesuai)';
      desc =
          'Pola data si Kecil mirip dengan anak berpertumbuhan normal pada data '
          'pelatihan model. Tetap lakukan pemantauan tumbuh kembang secara rutin.';
      recs = [
        'Pertahankan pola makan bergizi seimbang dengan kombinasi protein hewani & nabati.',
        'Lanjutkan pemantauan tumbuh kembang bulanan secara berkala.',
        'Dukung aktivitas bermain dan istirahat yang cukup untuk perkembangan optimal.',
      ];
    }

    return StuntingPredictionResult(
      status: status,
      statusLabel: statusLabel,
      zScoreHeightForAge: haz,
      zScoreWeightForAge: waz,
      confidenceProbability: confidence,
      description: inRange ? desc : '$desc$outOfRangeNote',
      recommendations: recs,
      isFromRemoteApi: false,
      modelName: 'Random Forest (100 pohon, GridSearchCV) - berjalan di aplikasi',
      isInTrainingRange: inRange,
    );
  }

  // Tabel pendekatan WHO (0 - 60 bulan) -- hanya untuk perkiraan z-score tampilan.
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
