// Entitas data untuk sistem penjadwalan konsultasi dokter di PediaGrow.

/// 1. JadwalPraktik (mingguan berulang)
class JadwalPraktikModel {
  final String id;
  final String dokterId;
  final int hari; // 1: Senin, 2: Selasa, ..., 7: Minggu
  final String jamMulai; // Format 'HH:mm', misal '08:30'
  final String jamSelesai; // Format 'HH:mm', misal '11:30'
  final int durasiSlotMenit; // Default 30 menit
  final bool aktif;
  final String dibuatOleh; // 'superadmin' atau 'dokter'

  const JadwalPraktikModel({
    required this.id,
    required this.dokterId,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    this.durasiSlotMenit = 30,
    this.aktif = true,
    this.dibuatOleh = 'dokter',
  });

  static String getNamaHari(int hari) {
    switch (hari) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return 'Senin';
    }
  }

  String get labelHari => getNamaHari(hari);

  /// Getter yang mengubah angka hari 1-7 menjadi nama hari (Senin sampai Minggu).
  String get namaHari => getNamaHari(hari);

  JadwalPraktikModel copyWith({
    String? id,
    String? dokterId,
    int? hari,
    String? jamMulai,
    String? jamSelesai,
    int? durasiSlotMenit,
    bool? aktif,
    String? dibuatOleh,
  }) {
    return JadwalPraktikModel(
      id: id ?? this.id,
      dokterId: dokterId ?? this.dokterId,
      hari: hari ?? this.hari,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      durasiSlotMenit: durasiSlotMenit ?? this.durasiSlotMenit,
      aktif: aktif ?? this.aktif,
      dibuatOleh: dibuatOleh ?? this.dibuatOleh,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dokter_id': dokterId,
      'hari': hari,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'durasi_slot_menit': durasiSlotMenit,
      'aktif': aktif,
      'dibuat_oleh': dibuatOleh,
    };
  }

  factory JadwalPraktikModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return JadwalPraktikModel(
      id: (id != null && id.isNotEmpty) ? id : (map['id']?.toString() ?? ''),
      dokterId: map['dokter_id']?.toString() ?? map['dokterId']?.toString() ?? '',
      hari: (map['hari'] as num?)?.toInt() ?? 1,
      jamMulai: map['jam_mulai']?.toString() ?? map['jamMulai']?.toString() ?? '08:00',
      jamSelesai: map['jam_selesai']?.toString() ?? map['jamSelesai']?.toString() ?? '11:00',
      durasiSlotMenit: (map['durasi_slot_menit'] as num?)?.toInt() ??
          (map['durasiSlotMenit'] as num?)?.toInt() ??
          30,
      aktif: map['aktif'] == true || map['aktif'] == 1,
      dibuatOleh: map['dibuat_oleh']?.toString() ??
          map['dibuatOleh']?.toString() ??
          'dokter',
    );
  }
}

/// 2. Cuti / Hari Libur Dokter
class CutiDokterModel {
  final String id;
  final String dokterId;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String? jamMulai; // Format 'HH:mm', null / kosong berarti libur seharian
  final String? jamSelesai;
  final String alasan;
  final String dibuatOleh; // 'dokter' atau 'superadmin'

  const CutiDokterModel({
    required this.id,
    required this.dokterId,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.jamMulai,
    this.jamSelesai,
    required this.alasan,
    this.dibuatOleh = 'dokter',
  });

  bool get isSeharian =>
      jamMulai == null ||
      jamMulai!.trim().isEmpty ||
      jamSelesai == null ||
      jamSelesai!.trim().isEmpty;

  String get rentangTanggalStr {
    final startStr = '${tanggalMulai.day}/${tanggalMulai.month}/${tanggalMulai.year}';
    final endStr = '${tanggalSelesai.day}/${tanggalSelesai.month}/${tanggalSelesai.year}';
    if (startStr == endStr) {
      return startStr;
    }
    return '$startStr - $endStr';
  }

  String get formattedRentangTanggal => rentangTanggalStr;

  String get rentangWaktuStr {
    if (isSeharian) return 'Seharian Penuh';
    return '$jamMulai - $jamSelesai WIB';
  }

  bool berlakuPada(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      tanggalMulai.year,
      tanggalMulai.month,
      tanggalMulai.day,
    );
    final end = DateTime(
      tanggalSelesai.year,
      tanggalSelesai.month,
      tanggalSelesai.day,
    );
    return (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
        (d.isAtSameMomentAs(end) || d.isBefore(end));
  }

  CutiDokterModel copyWith({
    String? id,
    String? dokterId,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
    String? jamMulai,
    String? jamSelesai,
    String? alasan,
    String? dibuatOleh,
  }) {
    return CutiDokterModel(
      id: id ?? this.id,
      dokterId: dokterId ?? this.dokterId,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      alasan: alasan ?? this.alasan,
      dibuatOleh: dibuatOleh ?? this.dibuatOleh,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dokter_id': dokterId,
      'tanggal_mulai': tanggalMulai.toIso8601String(),
      'tanggal_selesai': tanggalSelesai.toIso8601String(),
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'alasan': alasan,
      'dibuat_oleh': dibuatOleh,
    };
  }

  factory CutiDokterModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return CutiDokterModel(
      id: (id != null && id.isNotEmpty) ? id : (map['id']?.toString() ?? ''),
      dokterId: map['dokter_id']?.toString() ?? map['dokterId']?.toString() ?? '',
      tanggalMulai: map['tanggal_mulai'] != null
          ? DateTime.parse(map['tanggal_mulai'].toString())
          : DateTime.now(),
      tanggalSelesai: map['tanggal_selesai'] != null
          ? DateTime.parse(map['tanggal_selesai'].toString())
          : DateTime.now(),
      jamMulai: map['jam_mulai']?.toString(),
      jamSelesai: map['jam_selesai']?.toString(),
      alasan: map['alasan']?.toString() ?? '',
      dibuatOleh: map['dibuat_oleh']?.toString() ??
          map['dibuatOleh']?.toString() ??
          'dokter',
    );
  }
}

/// Slot waktu dinamis hasil kalkulasi JadwalPraktik dikurangi Cuti dan Booking
class SlotWaktuDokter {
  final String jamMulai; // 'HH:mm'
  final String jamSelesai; // 'HH:mm'
  final String timeLabel; // '08:30 - 09:00'
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isAvailable;
  final String? unavailableReason;

  const SlotWaktuDokter({
    required this.jamMulai,
    required this.jamSelesai,
    required this.timeLabel,
    required this.startDateTime,
    required this.endDateTime,
    this.isAvailable = true,
    this.unavailableReason,
  });
}

/// Badge ketersediaan dokter
enum DoctorBadgeType {
  tersediaHariIni,
  tersediaBesok,
  jadwalTerdekat,
  belumAdaJadwal,
}

class DoctorBadgeInfo {
  final DoctorBadgeType type;
  final String label;
  final DateTime? tanggalTersedia;

  const DoctorBadgeInfo({
    required this.type,
    required this.label,
    this.tanggalTersedia,
  });
}
