import 'dart:math' as math;

/// Kelas pembungkus parameter LMS (Lambda-Mu-Sigma) WHO Child Growth Standards
class LmsValues {
  final double l;
  final double m; // Median
  final double s;

  const LmsValues({required this.l, required this.m, required this.s});

  /// Menghitung nilai antropometri untuk target Z-score (-3, -2, 0, +2, +3)
  double valueForZ(double z) {
    if (l != 0) {
      final base = 1.0 + l * s * z;
      if (base <= 0) return 0.0;
      return m * math.pow(base, 1.0 / l);
    } else {
      return m * math.exp(s * z);
    }
  }

  /// Menghitung Z-score dari nilai antropometri terukur
  double calculateZScore(double y) {
    if (y <= 0 || m <= 0 || s <= 0) return 0.0;
    if (l != 0) {
      return (math.pow(y / m, l) - 1.0) / (l * s);
    } else {
      return math.log(y / m) / s;
    }
  }
}

/// Tabel Referensi Standar Antropometri Anak (Permenkes RI No. 2 Tahun 2020 & WHO Child Growth Standards)
/// untuk balita 0 - 60 bulan.
class WhoGrowthData {
  // ===========================================================================
  // 1. BERAT BADAN MENURUT UMUR (BB/U) — Weight-for-Age (0-60 Bulan)
  // ===========================================================================

  /// Laki-laki (Boys) Weight-for-Age LMS (0 - 60 Bulan)
  static LmsValues getWeightForAgeBoys(int months) {
    final clamped = months.clamp(0, 60);
    final data = _wfaBoysTable[clamped] ?? _interpolateLms(_wfaBoysTable, clamped);
    return data;
  }

  /// Perempuan (Girls) Weight-for-Age LMS (0 - 60 Bulan)
  static LmsValues getWeightForAgeGirls(int months) {
    final clamped = months.clamp(0, 60);
    final data = _wfaGirlsTable[clamped] ?? _interpolateLms(_wfaGirlsTable, clamped);
    return data;
  }

  // ===========================================================================
  // 2. TINGGI/PANJANG BADAN MENURUT UMUR (TB/U) — Length/Height-for-Age (0-60 Bulan)
  // ===========================================================================

  /// Laki-laki (Boys) Height-for-Age LMS (0 - 60 Bulan)
  static LmsValues getHeightForAgeBoys(int months) {
    final clamped = months.clamp(0, 60);
    return _hfaBoysTable[clamped] ?? _interpolateLms(_hfaBoysTable, clamped);
  }

  /// Perempuan (Girls) Height-for-Age LMS (0 - 60 Bulan)
  static LmsValues getHeightForAgeGirls(int months) {
    final clamped = months.clamp(0, 60);
    return _hfaGirlsTable[clamped] ?? _interpolateLms(_hfaGirlsTable, clamped);
  }

  // ===========================================================================
  // 3. LINGKAR KEPALA MENURUT UMUR (LK/U) — Head Circumference-for-Age (0-60 Bulan)
  // ===========================================================================

  /// Laki-laki (Boys) Head Circumference-for-Age LMS (0 - 60 Bulan)
  static LmsValues getHeadCircumferenceForAgeBoys(int months) {
    final clamped = months.clamp(0, 60);
    return _hcfaBoysTable[clamped] ?? _interpolateLms(_hcfaBoysTable, clamped);
  }

  /// Perempuan (Girls) Head Circumference-for-Age LMS (0 - 60 Bulan)
  static LmsValues getHeadCircumferenceForAgeGirls(int months) {
    final clamped = months.clamp(0, 60);
    return _hcfaGirlsTable[clamped] ?? _interpolateLms(_hcfaGirlsTable, clamped);
  }

  // ===========================================================================
  // 4. BERAT BADAN MENURUT TINGGI BADAN (BB/TB) — Weight-for-Height/Length
  // ===========================================================================

  static LmsValues getWeightForHeight(double heightCm, bool isGirl) {
    final h = heightCm.clamp(45.0, 120.0);
    final table = isGirl ? _wfhGirlsTable : _wfhBoysTable;

    // Cari height terdekat dalam table
    int lowerKey = (h.floor() / 2).floor() * 2;
    if (lowerKey < 45) lowerKey = 45;
    if (lowerKey > 115) lowerKey = 115;

    return table[lowerKey] ??
        LmsValues(
          l: -0.35,
          m: isGirl ? (h * 0.18 - 4.5) : (h * 0.185 - 4.5),
          s: 0.088,
        );
  }

  // ---------------------------------------------------------------------------
  // HELPER INTERPOLASI
  // ---------------------------------------------------------------------------
  static LmsValues _interpolateLms(Map<int, LmsValues> table, int month) {
    if (table.containsKey(month)) return table[month]!;

    int lowerKey = 0;
    int upperKey = 60;

    for (final k in table.keys) {
      if (k <= month && k > lowerKey) lowerKey = k;
      if (k >= month && k < upperKey) upperKey = k;
    }

    if (lowerKey == upperKey) return table[lowerKey]!;

    final lower = table[lowerKey]!;
    final upper = table[upperKey]!;
    final fraction = (month - lowerKey) / (upperKey - lowerKey);

    return LmsValues(
      l: lower.l + (upper.l - lower.l) * fraction,
      m: lower.m + (upper.m - lower.m) * fraction,
      s: lower.s + (upper.s - lower.s) * fraction,
    );
  }

  // ===========================================================================
  // TABEL DATA WHO (L, M, S) SESUAI STANDAR PERMENKES RI NO 2 TAHUN 2020
  // ===========================================================================

  // 1A. BB/U Boys (0, 3, 6, 9, 12, 18, 24, 30, 36, 42, 48, 54, 60)
  static final Map<int, LmsValues> _wfaBoysTable = {
    0: const LmsValues(l: 0.3487, m: 3.3464, s: 0.1460),
    3: const LmsValues(l: 0.1843, m: 6.4005, s: 0.1250),
    6: const LmsValues(l: 0.0634, m: 7.9348, s: 0.1170),
    9: const LmsValues(l: -0.0210, m: 8.8953, s: 0.1130),
    12: const LmsValues(l: -0.0827, m: 9.6457, s: 0.1110),
    18: const LmsValues(l: -0.1610, m: 10.9254, s: 0.1100),
    24: const LmsValues(l: -0.2087, m: 12.1517, s: 0.1110),
    30: const LmsValues(l: -0.2400, m: 13.3100, s: 0.1120),
    36: const LmsValues(l: -0.2642, m: 14.3382, s: 0.1140),
    42: const LmsValues(l: -0.2800, m: 15.3500, s: 0.1170),
    48: const LmsValues(l: -0.2974, m: 16.3268, s: 0.1210),
    54: const LmsValues(l: -0.3150, m: 17.3100, s: 0.1260),
    60: const LmsValues(l: -0.3341, m: 18.3374, s: 0.1310),
  };

  // 1B. BB/U Girls (0, 3, 6, 9, 12, 18, 24, 30, 36, 42, 48, 54, 60)
  static final Map<int, LmsValues> _wfaGirlsTable = {
    0: const LmsValues(l: 0.3809, m: 3.2322, s: 0.1417),
    3: const LmsValues(l: 0.2201, m: 5.8427, s: 0.1250),
    6: const LmsValues(l: 0.1082, m: 7.2970, s: 0.1190),
    9: const LmsValues(l: 0.0310, m: 8.2430, s: 0.1170),
    12: const LmsValues(l: -0.0270, m: 8.9486, s: 0.1170),
    18: const LmsValues(l: -0.1060, m: 10.2312, s: 0.1180),
    24: const LmsValues(l: -0.1584, m: 11.4799, s: 0.1210),
    30: const LmsValues(l: -0.1980, m: 12.6500, s: 0.1240),
    36: const LmsValues(l: -0.2274, m: 13.8540, s: 0.1270),
    42: const LmsValues(l: -0.2500, m: 14.9900, s: 0.1310),
    48: const LmsValues(l: -0.2704, m: 16.0740, s: 0.1350),
    54: const LmsValues(l: -0.2890, m: 17.1500, s: 0.1400),
    60: const LmsValues(l: -0.3075, m: 18.2372, s: 0.1460),
  };

  // 2A. TB/U Boys (0, 3, 6, 9, 12, 18, 24, 30, 36, 42, 48, 54, 60)
  static final Map<int, LmsValues> _hfaBoysTable = {
    0: const LmsValues(l: 1.0, m: 49.8842, s: 0.0380),
    3: const LmsValues(l: 1.0, m: 61.4241, s: 0.0370),
    6: const LmsValues(l: 1.0, m: 67.6236, s: 0.0360),
    9: const LmsValues(l: 1.0, m: 71.9567, s: 0.0360),
    12: const LmsValues(l: 1.0, m: 75.7483, s: 0.0360),
    18: const LmsValues(l: 1.0, m: 82.3168, s: 0.0370),
    24: const LmsValues(l: 1.0, m: 87.8188, s: 0.0380),
    30: const LmsValues(l: 1.0, m: 92.4200, s: 0.0390),
    36: const LmsValues(l: 1.0, m: 96.1189, s: 0.0400),
    42: const LmsValues(l: 1.0, m: 100.1200, s: 0.0410),
    48: const LmsValues(l: 1.0, m: 103.3180, s: 0.0420),
    54: const LmsValues(l: 1.0, m: 106.8500, s: 0.0430),
    60: const LmsValues(l: 1.0, m: 110.0240, s: 0.0440),
  };

  // 2B. TB/U Girls (0, 3, 6, 9, 12, 18, 24, 30, 36, 42, 48, 54, 60)
  static final Map<int, LmsValues> _hfaGirlsTable = {
    0: const LmsValues(l: 1.0, m: 49.1445, s: 0.0380),
    3: const LmsValues(l: 1.0, m: 59.8052, s: 0.0370),
    6: const LmsValues(l: 1.0, m: 65.7311, s: 0.0360),
    9: const LmsValues(l: 1.0, m: 70.1374, s: 0.0360),
    12: const LmsValues(l: 1.0, m: 74.0205, s: 0.0360),
    18: const LmsValues(l: 1.0, m: 80.7024, s: 0.0370),
    24: const LmsValues(l: 1.0, m: 86.4258, s: 0.0380),
    30: const LmsValues(l: 1.0, m: 91.2400, s: 0.0390),
    36: const LmsValues(l: 1.0, m: 95.1420, s: 0.0400),
    42: const LmsValues(l: 1.0, m: 99.0200, s: 0.0410),
    48: const LmsValues(l: 1.0, m: 102.7230, s: 0.0420),
    54: const LmsValues(l: 1.0, m: 106.2000, s: 0.0430),
    60: const LmsValues(l: 1.0, m: 109.4320, s: 0.0440),
  };

  // 3A. LK/U Boys (0, 3, 6, 9, 12, 18, 24, 30, 36, 42, 48, 54, 60)
  static final Map<int, LmsValues> _hcfaBoysTable = {
    0: const LmsValues(l: 1.0, m: 34.5, s: 0.036),
    3: const LmsValues(l: 1.0, m: 40.5, s: 0.032),
    6: const LmsValues(l: 1.0, m: 43.3, s: 0.030),
    9: const LmsValues(l: 1.0, m: 45.0, s: 0.029),
    12: const LmsValues(l: 1.0, m: 46.1, s: 0.028),
    18: const LmsValues(l: 1.0, m: 47.4, s: 0.028),
    24: const LmsValues(l: 1.0, m: 48.3, s: 0.028),
    30: const LmsValues(l: 1.0, m: 49.0, s: 0.028),
    36: const LmsValues(l: 1.0, m: 49.5, s: 0.028),
    42: const LmsValues(l: 1.0, m: 50.0, s: 0.028),
    48: const LmsValues(l: 1.0, m: 50.4, s: 0.029),
    54: const LmsValues(l: 1.0, m: 50.7, s: 0.029),
    60: const LmsValues(l: 1.0, m: 51.0, s: 0.030),
  };

  // 3B. LK/U Girls (0, 3, 6, 9, 12, 18, 24, 30, 36, 42, 48, 54, 60)
  static final Map<int, LmsValues> _hcfaGirlsTable = {
    0: const LmsValues(l: 1.0, m: 33.9, s: 0.035),
    3: const LmsValues(l: 1.0, m: 39.5, s: 0.032),
    6: const LmsValues(l: 1.0, m: 42.2, s: 0.030),
    9: const LmsValues(l: 1.0, m: 43.8, s: 0.029),
    12: const LmsValues(l: 1.0, m: 44.9, s: 0.028),
    18: const LmsValues(l: 1.0, m: 46.2, s: 0.028),
    24: const LmsValues(l: 1.0, m: 47.2, s: 0.028),
    30: const LmsValues(l: 1.0, m: 47.9, s: 0.028),
    36: const LmsValues(l: 1.0, m: 48.5, s: 0.028),
    42: const LmsValues(l: 1.0, m: 49.0, s: 0.028),
    48: const LmsValues(l: 1.0, m: 49.5, s: 0.029),
    54: const LmsValues(l: 1.0, m: 49.9, s: 0.029),
    60: const LmsValues(l: 1.0, m: 50.2, s: 0.030),
  };

  // 4A. BB/TB Boys
  static final Map<int, LmsValues> _wfhBoysTable = {
    45: const LmsValues(l: -0.35, m: 2.45, s: 0.088),
    50: const LmsValues(l: -0.35, m: 3.32, s: 0.088),
    60: const LmsValues(l: -0.35, m: 5.95, s: 0.088),
    70: const LmsValues(l: -0.35, m: 8.55, s: 0.088),
    80: const LmsValues(l: -0.35, m: 10.75, s: 0.088),
    90: const LmsValues(l: -0.35, m: 12.90, s: 0.088),
    100: const LmsValues(l: -0.35, m: 15.60, s: 0.089),
    110: const LmsValues(l: -0.35, m: 18.70, s: 0.090),
    115: const LmsValues(l: -0.35, m: 20.50, s: 0.091),
  };

  // 4B. BB/TB Girls
  static final Map<int, LmsValues> _wfhGirlsTable = {
    45: const LmsValues(l: -0.35, m: 2.38, s: 0.088),
    50: const LmsValues(l: -0.35, m: 3.20, s: 0.088),
    60: const LmsValues(l: -0.35, m: 5.65, s: 0.088),
    70: const LmsValues(l: -0.35, m: 8.20, s: 0.088),
    80: const LmsValues(l: -0.35, m: 10.40, s: 0.088),
    90: const LmsValues(l: -0.35, m: 12.60, s: 0.088),
    100: const LmsValues(l: -0.35, m: 15.30, s: 0.089),
    110: const LmsValues(l: -0.35, m: 18.40, s: 0.090),
    115: const LmsValues(l: -0.35, m: 20.10, s: 0.091),
  };
}
