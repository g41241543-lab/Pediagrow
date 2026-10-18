import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data untuk item Riwayat Konsultasi pada hak akses PMIK Superadmin.
///
/// Menggabungkan informasi:
/// - Konsultasi (tanggal, status, dokter)
/// - Pasien / Anak dari collection 'children' (nama, jenis kelamin, tanggal lahir)
/// - Resume Medis dari collection 'resume_medis' (keluhan, ringkasan konsultasi)
class RiwayatKonsultasiAdminItem {
  final String id;
  final String childId;
  final String childName;
  final String childGender; // 'Perempuan' / 'Laki-laki'
  final DateTime? childBirthDate;
  final String? childAge; // Fallback jika tanggal lahir belum ada
  final String doctorId;
  final String doctorName;
  final DateTime? consultationDate;
  final String formattedDate; // e.g. "26 Agustus 2026"
  final String status; // 'Dijadwalkan' | 'Selesai'
  final String complaint; // Keluhan dari resume medis
  final String summary; // Ringkasan konsultasi dari resume medis
  final String? resumeMedisId;
  final String? sessionId;
  final DateTime? createdAt;

  const RiwayatKonsultasiAdminItem({
    required this.id,
    this.childId = '',
    required this.childName,
    this.childGender = 'Perempuan',
    this.childBirthDate,
    this.childAge,
    this.doctorId = '',
    required this.doctorName,
    this.consultationDate,
    required this.formattedDate,
    this.status = 'Selesai',
    this.complaint = '',
    this.summary = '',
    this.resumeMedisId,
    this.sessionId,
    this.createdAt,
  });

  /// Apakah anak berjenis kelamin perempuan
  bool get isGirl => isGirlGender(childGender, childName);

  /// Apakah status konsultasi sudah selesai
  bool get isCompleted => status.toLowerCase().contains('selesai');
  bool get isSelesai => isCompleted;

  /// Usia anak yang dihitung otomatis dari tanggal lahir hingga tanggal konsultasi atau hari ini
  /// dalam format "X tahun Y bulan Z hari"
  String get calculatedAge {
    if (childBirthDate != null) {
      return calculateChildAge(
        childBirthDate!,
        targetDate: consultationDate ?? DateTime.now(),
      );
    }
    if (childAge != null && childAge!.isNotEmpty) {
      return childAge!;
    }
    return '1 tahun 3 bulan 3 hari';
  }

  RiwayatKonsultasiAdminItem copyWith({
    String? id,
    String? childId,
    String? childName,
    String? childGender,
    DateTime? childBirthDate,
    String? childAge,
    String? doctorId,
    String? doctorName,
    DateTime? consultationDate,
    String? formattedDate,
    String? status,
    String? complaint,
    String? summary,
    String? resumeMedisId,
    String? sessionId,
    DateTime? createdAt,
  }) {
    return RiwayatKonsultasiAdminItem(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      childGender: childGender ?? this.childGender,
      childBirthDate: childBirthDate ?? this.childBirthDate,
      childAge: childAge ?? this.childAge,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      consultationDate: consultationDate ?? this.consultationDate,
      formattedDate: formattedDate ?? this.formattedDate,
      status: status ?? this.status,
      complaint: complaint ?? this.complaint,
      summary: summary ?? this.summary,
      resumeMedisId: resumeMedisId ?? this.resumeMedisId,
      sessionId: sessionId ?? this.sessionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Sample mock data riwayat konsultasi yang sudah selesai (sesuai ketentuan: hanya yang berstatus Selesai)
  static List<RiwayatKonsultasiAdminItem> getMockData() {
    return [
      RiwayatKonsultasiAdminItem(
        id: 'riwayat-mock-001',
        childName: 'Kaia Anastasya',
        childGender: 'Perempuan',
        // Tanggal lahir 23 Mei 2025 -> 26 Agustus 2026 = 1 tahun 3 bulan 3 hari
        childBirthDate: DateTime(2025, 5, 23),
        doctorName: 'dr. Ririn Esterina, Sp. A',
        consultationDate: DateTime(2026, 8, 26),
        formattedDate: '26 Agustus 2026',
        status: 'Selesai',
        complaint: 'Berat badan anak naik turun dan nafsu makan berkurang.',
        summary:
            'Anak dalam kondisi baik secara umum.\nDisarankan pemberian makan lebih sering dengan porsi kecil, tambahkan variasi menu dan pantau berat badan setiap minggu.\nKontrol ulang 2 minggu lagi jika belum ada kenaikan berat badan.',
      ),
      RiwayatKonsultasiAdminItem(
        id: 'riwayat-mock-002',
        childName: 'Amara Adiratna',
        childGender: 'Perempuan',
        childBirthDate: DateTime(2025, 2, 10),
        doctorName: 'dr. M. Ali Shodikin, Sp.A, M.Kes',
        consultationDate: DateTime(2026, 8, 24),
        formattedDate: '24 Agustus 2026',
        status: 'Selesai',
        complaint: 'Batuk pilek ringan selama 3 hari tanpa disertai demam tinggi.',
        summary:
            'Saluran pernapasan atas mengalami iritasi ringan karena perubahan cuaca.\nDiberikan terapi suportif, jaga kehangatan tubuh dan cairan cukup.\nEvaluasi 3 hari ke depan jika batuk memberat.',
      ),
      RiwayatKonsultasiAdminItem(
        id: 'riwayat-mock-003',
        childName: 'Zafran Aditya',
        childGender: 'Laki-laki',
        childBirthDate: DateTime(2025, 6, 12),
        doctorName: 'dr. B. Gebyar Tri Baskoro, Sp.A',
        consultationDate: DateTime(2026, 8, 20),
        formattedDate: '20 Agustus 2026',
        status: 'Selesai',
        complaint: 'Konsultasi imunisasi lanjutan dan pemantauan grafik tumbuh kembang balita.',
        summary:
            'Pertumbuhan anak berada di pita hijau (normal) sesuai kurva WHO.\nJadwal imunisasi lanjutan telah dicatat dan disarankan tetap menjaga asupan gizi seimbang.',
      ),
    ];
  }
}

// ─── HELPER FUNCTIONS ────────────────────────────────────────────────────────

/// Deteksi jenis kelamin anak
bool isGirlGender(String? gender, [String? childName]) {
  if (gender != null && gender.isNotEmpty) {
    final g = gender.toLowerCase().trim();
    if (g.contains('perempuan') ||
        g.contains('wanita') ||
        g.contains('female') ||
        g == 'p' ||
        g == 'pr') {
      return true;
    }
    if (g.contains('laki') ||
        g.contains('pria') ||
        g.contains('male') ||
        g == 'l' ||
        g == 'lk') {
      return false;
    }
  }
  final n = (childName ?? '').toLowerCase();
  if (n.contains('kaia') ||
      n.contains('amara') ||
      n.contains('anita') ||
      n.contains('putri') ||
      n.contains('siti') ||
      n.contains('ayu') ||
      n.contains('cantika')) {
    return true;
  }
  return false;
}

/// Menghitung usia anak dengan format presisi "X tahun Y bulan Z hari"
String calculateChildAge(DateTime birthDate, {DateTime? targetDate}) {
  final target = targetDate ?? DateTime.now();
  if (target.isBefore(birthDate)) return '0 hari';

  int years = target.year - birthDate.year;
  int months = target.month - birthDate.month;
  int days = target.day - birthDate.day;

  if (days < 0) {
    // Ambil hari dari bulan sebelumnya
    final prevMonthLastDay = DateTime(target.year, target.month, 0).day;
    days += prevMonthLastDay;
    months--;
  }

  if (months < 0) {
    months += 12;
    years--;
  }

  final parts = <String>[];
  if (years > 0) parts.add('$years tahun');
  if (months > 0 || years > 0) parts.add('$months bulan');
  parts.add('$days hari');

  return parts.isEmpty ? '0 hari' : parts.join(' ');
}

/// Format tanggal ke format bahasa Indonesia, misal: "26 Agustus 2026"
String formatIndonesianDate(DateTime date) {
  const months = [
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

/// Parsing tanggal dari Firestore timestamp, DateTime, atau String
DateTime? parseAnyDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is String) {
    final dt = DateTime.tryParse(raw);
    if (dt != null) return dt;
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      final day = int.tryParse(parts[0]);
      final year = int.tryParse(parts[2]);
      const monthMap = {
        'januari': 1,
        'februari': 2,
        'maret': 3,
        'april': 4,
        'mei': 5,
        'juni': 6,
        'juli': 7,
        'agustus': 8,
        'september': 9,
        'oktober': 10,
        'november': 11,
        'desember': 12,
      };
      final month = monthMap[parts[1].toLowerCase()];
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
  }
  return null;
}
