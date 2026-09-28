/// Model data terpadu untuk Riwayat Konsultasi dan Detail Konsultasi PediaGrow.
///
/// Menyediakan informasi dokter, pasien (anak), jadwal konsultasi,
/// keluhan, status penyelesaian, serta ringkasan konsultasi dokter.
class RiwayatKonsultasiModel {
  final String id;
  final String doctorName;
  final String doctorSpecialization;
  final String? doctorPhoto;
  final String childName;
  final DateTime consultationDate;
  final String formattedDate;
  final String status;
  final String complaint;
  final String fullComplaint;
  final String summary;

  final String childAge;
  final String childGender;

  const RiwayatKonsultasiModel({
    required this.id,
    required this.doctorName,
    this.doctorSpecialization = 'Dokter Spesialis Anak',
    this.doctorPhoto,
    required this.childName,
    this.childAge = '1 tahun 3 bulan 3 hari',
    this.childGender = 'female',
    required this.consultationDate,
    required this.formattedDate,
    this.status = 'Selesai',
    required this.complaint,
    required this.fullComplaint,
    required this.summary,
  });

  /// Salin objek dengan nilai atribut baru jika diperlukan
  RiwayatKonsultasiModel copyWith({
    String? id,
    String? doctorName,
    String? doctorSpecialization,
    String? doctorPhoto,
    String? childName,
    String? childAge,
    String? childGender,
    DateTime? consultationDate,
    String? formattedDate,
    String? status,
    String? complaint,
    String? fullComplaint,
    String? summary,
  }) {
    return RiwayatKonsultasiModel(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialization: doctorSpecialization ?? this.doctorSpecialization,
      doctorPhoto: doctorPhoto ?? this.doctorPhoto,
      childName: childName ?? this.childName,
      childAge: childAge ?? this.childAge,
      childGender: childGender ?? this.childGender,
      consultationDate: consultationDate ?? this.consultationDate,
      formattedDate: formattedDate ?? this.formattedDate,
      status: status ?? this.status,
      complaint: complaint ?? this.complaint,
      fullComplaint: fullComplaint ?? this.fullComplaint,
      summary: summary ?? this.summary,
    );
  }

  /// Membuat model dari Map / data JSON
  factory RiwayatKonsultasiModel.fromMap(Map<String, dynamic> map) {
    return RiwayatKonsultasiModel(
      id: map['id']?.toString() ?? '',
      doctorName: map['doctor_name'] ?? 'dr. Ririn Esterina, Sp. A',
      doctorSpecialization:
          map['doctor_specialization'] ?? 'Dokter Spesialis Anak',
      doctorPhoto: map['doctor_photo'] ?? 'assets/images/doctor_ririn.png',
      childName: map['child_name'] ?? 'Kaia Anastasya',
      childAge: map['child_age'] ?? '1 tahun 3 bulan 3 hari',
      childGender: map['child_gender'] ?? 'female',
      consultationDate: map['consultation_date'] != null
          ? DateTime.tryParse(map['consultation_date'].toString()) ??
              DateTime(2026, 8, 26)
          : DateTime(2026, 8, 26),
      formattedDate: map['formatted_date'] ?? '26 Agustus 2026',
      status: map['status'] ?? 'Selesai',
      complaint: map['complaint'] ??
          'BB anak naik turun dan nafsu makan berkurang',
      fullComplaint: map['full_complaint'] ??
          'Berat badan anak naik turun dan nafsu makan berkurang.',
      summary: map['summary'] ??
          'Anak dalam kondisi baik secara umum.\nDisarankan pemberian makan lebih sering dengan porsi kecil, tambahkan variasi menu dan pantau berat badan setiap minggu.\nKontrol ulang 2 minggu lagi jika belum ada kenaikan berat badan.',
    );
  }

  /// Konversi ke format Map untuk penyimpanan lokal atau backend
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctor_name': doctorName,
      'doctor_specialization': doctorSpecialization,
      'doctor_photo': doctorPhoto,
      'child_name': childName,
      'child_age': childAge,
      'child_gender': childGender,
      'consultation_date': consultationDate.toIso8601String(),
      'formatted_date': formattedDate,
      'status': status,
      'complaint': complaint,
      'full_complaint': fullComplaint,
      'summary': summary,
    };
  }

  /// Data mock Amara Adiratna (Card 1 pada referensi desain)
  static final RiwayatKonsultasiModel sampleRiwayatAmara = RiwayatKonsultasiModel(
    id: 'riwayat-001',
    doctorName: 'dr. M. Ali Shodikin, Sp.A, M.Kes',
    doctorSpecialization: 'Dokter Spesialis Anak',
    childName: 'Amara Adiratna',
    childAge: '1 tahun 2 bulan 10 hari',
    childGender: 'female',
    consultationDate: DateTime(2026, 8, 26),
    formattedDate: '26 Agustus 2026',
    status: 'Dijadwalkan',
    complaint: 'Pemeriksaan rutin dan pemantauan nafsu makan anak',
    fullComplaint: 'Pemeriksaan rutin dan pemantauan nafsu makan anak.',
    summary: 'Jadwal konsultasi telah dikonfirmasi. Dokter akan melakukan evaluasi tumbuh kembang anak sesuai jadwal.',
  );

  /// Data mock utama (Kaia Anastasya - Card 2 pada referensi desain & Detail)
  static final RiwayatKonsultasiModel sampleRiwayat1 = RiwayatKonsultasiModel(
    id: 'riwayat-002',
    doctorName: 'dr. Ririn Esterina, Sp. A',
    doctorSpecialization: 'Dokter Spesialis Anak',
    doctorPhoto: 'assets/images/doctor_ririn.png',
    childName: 'Kaia Anastasya',
    childAge: '1 tahun 3 bulan 3 hari',
    childGender: 'female',
    consultationDate: DateTime(2026, 8, 26),
    formattedDate: '26 Agustus 2026',
    status: 'Selesai',
    complaint: 'BB anak naik turun dan nafsu makan berkurang',
    fullComplaint: 'Berat badan anak naik turun dan nafsu makan berkurang.',
    summary:
        'Anak dalam kondisi baik secara umum.\nDisarankan pemberian makan lebih sering dengan porsi kecil, tambahkan variasi menu dan pantau berat badan setiap minggu.\nKontrol ulang 2 minggu lagi jika belum ada kenaikan berat badan.',
  );

  /// Data mock Zafran Aditya (Card 3 pada referensi desain)
  static final RiwayatKonsultasiModel sampleRiwayatZafran = RiwayatKonsultasiModel(
    id: 'riwayat-003',
    doctorName: 'dr. B. Gebyar Tri Baskoro, Sp.A',
    doctorSpecialization: 'Dokter Spesialis Anak',
    childName: 'Zafran Aditya',
    childAge: '2 tahun 1 bulan 5 hari',
    childGender: 'male',
    consultationDate: DateTime(2026, 8, 26),
    formattedDate: '26 Agustus 2026',
    status: 'Dijadwalkan',
    complaint: 'Pemeriksaan alergi ruam kulit pada anak',
    fullComplaint: 'Pemeriksaan ruam kulit setelah pengenalan menu makanan baru.',
    summary: 'Jadwal konsultasi telah dikonfirmasi untuk evaluasi alergi makanan.',
  );

  /// Data mock Devaro Ramadhan (Card 4 pada referensi desain)
  static final RiwayatKonsultasiModel sampleRiwayatDevaro = RiwayatKonsultasiModel(
    id: 'riwayat-004',
    doctorName: 'dr. Ahmad Nuri, Sp. A',
    doctorSpecialization: 'Dokter Spesialis Anak',
    doctorPhoto: 'assets/images/doctor_ahmad_nuri.png',
    childName: 'Devaro Ramadhan',
    childAge: '1 tahun 8 bulan 12 hari',
    childGender: 'male',
    consultationDate: DateTime(2026, 8, 26),
    formattedDate: '26 Agustus 2026',
    status: 'Dijadwalkan',
    complaint: 'Jadwal imunisasi PCV lanjutan',
    fullComplaint: 'Konsultasi kelanjutan jadwal vaksinasi PCV booster anak.',
    summary: 'Jadwal konsultasi telah dikonfirmasi untuk pemeriksaan jadwal imunisasi.',
  );

  /// Data mock kedua sebelumnya untuk kompatibilitas
  static final RiwayatKonsultasiModel sampleRiwayat2 = RiwayatKonsultasiModel(
    id: 'riwayat-legacy',
    doctorName: 'dr. Ahmad Nuri, Sp. A',
    doctorSpecialization: 'Dokter Spesialis Anak',
    doctorPhoto: 'assets/images/doctor_ahmad_nuri.png',
    childName: 'Kaia Anastasya',
    childAge: '1 tahun 3 bulan',
    childGender: 'female',
    consultationDate: DateTime(2026, 8, 12),
    formattedDate: '12 Agustus 2026',
    status: 'Selesai',
    complaint: 'Konsultasi imunisasi PCV lanjutan dan pemantauan alergi makanan',
    fullComplaint:
        'Anak sudah siap menerima vaksinasi PCV dosis ke-3. Orang tua menanyakan pencegahan ruam ringan saat pengenalan MPASI telur.',
    summary:
        'Kondisi fisik anak fit untuk vaksinasi lanjutan. Dosis PCV berhasil diberikan tanpa kontraindikasi.\nUntuk alergi telur, kenalkan bertahap dari bagian kuning telur matang.',
  );

  /// List mock data default (digunakan pengguna)
  static List<RiwayatKonsultasiModel> get mockList => [
        sampleRiwayat1,
      ];

  /// List mock data untuk superadmin (persis urutan screenshot referensi)
  static List<RiwayatKonsultasiModel> get mockMultiList => [
        sampleRiwayatAmara,
        sampleRiwayat1,
        sampleRiwayatZafran,
        sampleRiwayatDevaro,
      ];
}
