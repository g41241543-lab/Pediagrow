import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data untuk Resume Medis Pasien Anak di PediaGrow.
/// Digunakan pada halaman Daftar Resume Medis dan Detail Resume Medis.
class ResumeMedisModel {
  final String id;
  final String childId;
  final String userId;
  final String doctorName;
  final String doctorSpecialization;
  final String? doctorPhoto;
  final String childName;
  final String childAgeAtConsultation;
  final String consultationDate;
  final String consultationTime;
  final double bbLahir;
  final double bbSaatIni;
  final double tbLahir;
  final double tbSaatIni;
  final String complaint;
  final String complaintShort;
  final String doctorAssessment;
  final String summary;
  final List<String> recommendations;
  final String prescription;
  final String status;
  final DateTime? createdAt;

  const ResumeMedisModel({
    required this.id,
    this.childId = '',
    this.userId = '',
    required this.doctorName,
    this.doctorSpecialization = 'Spesialis Anak',
    this.doctorPhoto,
    required this.childName,
    this.childAgeAtConsultation = '0 tahun 2 bulan 11 hari',
    required this.consultationDate,
    this.consultationTime = '13.20- 13.44 WIB',
    this.bbLahir = 2.4,
    this.bbSaatIni = 3.4,
    this.tbLahir = 44.0,
    this.tbSaatIni = 51.0,
    required this.complaint,
    required this.complaintShort,
    this.doctorAssessment = '',
    this.summary = '',
    this.recommendations = const [],
    this.prescription = '-',
    this.status = 'Selesai',
    this.createdAt,
  });

  /// Factory untuk membuat ResumeMedisModel dari Map / JSON Firestore
  factory ResumeMedisModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    List<String> parseRecommendations(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      } else if (raw is String && raw.isNotEmpty) {
        return raw.split('\n').where((s) => s.trim().isNotEmpty).toList();
      }
      return [];
    }

    DateTime? parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    double parseDouble(dynamic raw, double fallback) {
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw) ?? fallback;
      return fallback;
    }

    return ResumeMedisModel(
      id: docId ?? map['id']?.toString() ?? '',
      childId: map['child_id']?.toString() ?? map['childId']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? map['userId']?.toString() ?? '',
      doctorName:
          map['doctor_name'] ?? map['doctorName'] ?? 'dr. Ririn Esterina, Sp.A',
      doctorSpecialization:
          map['doctor_specialization'] ??
          map['doctorSpecialization'] ??
          'Spesialis Anak',
      doctorPhoto: map['doctor_photo'] ?? map['doctorPhoto'],
      childName: map['child_name'] ?? map['childName'] ?? 'Anak',
      childAgeAtConsultation:
          map['child_age_at_consultation'] ??
          map['childAgeAtConsultation'] ??
          '0 tahun 2 bulan 11 hari',
      consultationDate:
          map['consultation_date'] ?? map['consultationDate'] ?? '13 Juni 2026',
      consultationTime:
          map['consultation_time'] ??
          map['consultationTime'] ??
          '13.20- 13.44 WIB',
      bbLahir: parseDouble(map['bb_lahir'] ?? map['bbLahir'], 2.4),
      bbSaatIni: parseDouble(map['bb_saat_ini'] ?? map['bbSaatIni'], 3.4),
      tbLahir: parseDouble(map['tb_lahir'] ?? map['tbLahir'], 44.0),
      tbSaatIni: parseDouble(map['tb_saat_ini'] ?? map['tbSaatIni'], 51.0),
      complaint: map['complaint'] ?? '',
      complaintShort:
          map['complaint_short'] ??
          map['complaintShort'] ??
          map['complaint'] ??
          '',
      doctorAssessment:
          map['doctor_assessment'] ?? map['doctorAssessment'] ?? '',
      summary: map['summary'] ?? '',
      recommendations: parseRecommendations(map['recommendations']),
      prescription: map['prescription'] ?? '-',
      status: map['status'] ?? 'Selesai',
      createdAt: parseDate(map['created_at'] ?? map['createdAt']),
    );
  }

  /// Factory dari DocumentSnapshot Firestore
  factory ResumeMedisModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ResumeMedisModel.fromMap(data, docId: doc.id);
  }

  /// Konversi ke format Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'child_id': childId,
      'user_id': userId,
      'doctor_name': doctorName,
      'doctor_specialization': doctorSpecialization,
      'doctor_photo': doctorPhoto,
      'child_name': childName,
      'child_age_at_consultation': childAgeAtConsultation,
      'consultation_date': consultationDate,
      'consultation_time': consultationTime,
      'bb_lahir': bbLahir,
      'bb_saat_ini': bbSaatIni,
      'tb_lahir': tbLahir,
      'tb_saat_ini': tbSaatIni,
      'complaint': complaint,
      'complaint_short': complaintShort,
      'doctor_assessment': doctorAssessment,
      'summary': summary,
      'recommendations': recommendations,
      'prescription': prescription,
      'status': status,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Data contoh / fallback sesuai dengan mockup desain
  static List<ResumeMedisModel> getSampleData({
    String childName = 'Arfa Zivano Kayfan',
    String childId = '',
    String userId = '',
    double bbLahir = 2.4,
    double tbLahir = 44.0,
  }) {
    return [
      ResumeMedisModel(
        id: 'resume-001',
        childId: childId,
        userId: userId,
        doctorName: 'dr. Ririn Esterina, Sp.A',
        doctorSpecialization: 'Spesialis Anak',
        doctorPhoto: 'assets/images/doctor_ririn.png',
        childName: childName,
        childAgeAtConsultation: '0 tahun 2 bulan 11 hari',
        consultationDate: '13 Juni 2026',
        consultationTime: '13.20- 13.44 WIB',
        bbLahir: bbLahir > 0 ? bbLahir : 2.4,
        bbSaatIni: 3.4,
        tbLahir: tbLahir > 0 ? tbLahir : 44.0,
        tbSaatIni: 51.0,
        complaint: 'Anak lahir dengan BB 2.4 kg, tergolong BB rendah. Anak sudah diberi ASI eksklusif, namun pada usia 2 bulan kenaikan BB masih belum signifikan.',
        complaintShort:
            'Diusia 2 bulan an BB anak belum naik secara signifikan',
        doctorAssessment: 'Kenaikan BB hingga 1 kg masih berada dibawah target ideal gizi normal (tidak stunting). Riwayat dan frekuensi menyusu perlu dikonfirmasi lebih lanjut',
        summary: 'Perlu pemantauan terkait frekuensi menyusu. Anak dalam kondisi baik secara umum. namun apabila BB tidak mencapai nilai normal sesuai umur maka berisiko stunting. Kontrol ulang 2 minggu lagi jika belum ada kenaikan berat badan.',
        recommendations: [
          'Terus menjaga frekuensi menyusu 8-12 kali',
          'Pantau tanda anak cukup konsumsi ASI',
          'Kontrol ulang 2 minggu lagi apabila belum ada kenaikan berat badan',
        ],
        prescription: '-',
        status: 'Selesai',
      ),
      ResumeMedisModel(
        id: 'resume-002',
        childId: childId,
        userId: userId,
        doctorName: 'dr. B. Gebyar Tri Baskoro, Sp.A',
        doctorSpecialization: 'Spesialis Anak',
        doctorPhoto: 'assets/images/doctor_ahmad_nuri.png',
        childName: childName,
        childAgeAtConsultation: '0 tahun 1 bulan 25 hari',
        consultationDate: '28 Mei 2026',
        consultationTime: '10.15- 10.38 WIB',
        bbLahir: bbLahir > 0 ? bbLahir : 2.4,
        bbSaatIni: 3.1,
        tbLahir: tbLahir > 0 ? tbLahir : 44.0,
        tbSaatIni: 49.5,
        complaint: 'Anak susah menyusu dan sering tertidur saat disusui, sehingga berat badan tidak kunjung mengalami kenaikan yang optimal.',
        complaintShort: 'Anak susah menyusu dan BB tidak kunjung naik',
        doctorAssessment: 'Pelekatan saat menyusui perlu diperbaiki agar transfer ASI optimal. Refleks hisap baik.',
        summary: 'Ibu diedukasi teknik pelekatan yang benar dan memastikan payudara dikosongkan bergantian.',
        recommendations: [
          'Perbaiki posisi dan pelekatan menyusui',
          'Susui sesering mungkin minimal 2-3 jam sekali',
          'Catat frekuensi buang air kecil (minimal 6 kali sehari)',
        ],
        prescription: 'Zink Drop 10mg 1x1',
        status: 'Selesai',
      ),
      ResumeMedisModel(
        id: 'resume-003',
        childId: childId,
        userId: userId,
        doctorName: 'dr. B. Gebyar Tri Baskoro, Sp.A',
        doctorSpecialization: 'Spesialis Anak',
        doctorPhoto: 'assets/images/doctor_ahmad_nuri.png',
        childName: childName,
        childAgeAtConsultation: '0 tahun 1 bulan 4 hari',
        consultationDate: '7 Mei 2026',
        consultationTime: '15.00- 15.30 WIB',
        bbLahir: bbLahir > 0 ? bbLahir : 2.4,
        bbSaatIni: 2.8,
        tbLahir: tbLahir > 0 ? tbLahir : 44.0,
        tbSaatIni: 47.0,
        complaint: 'Hasil cek stunting mandiri di aplikasi menunjukkan kurva pertumbuhan berada di garis merah / indikasi stunting.',
        complaintShort: 'Hasil cek stunting menunjukkan status stunting',
        doctorAssessment: 'Status gizi kurang dengan riwayat BBLR. Pertumbuhan linier masih butuh pemantauan ketat.',
        summary: 'Keluarga diberikan motivasi gizi keluarga dan jadwal kunjungan berkala ke fasilitas kesehatan terdekat.',
        recommendations: [
          'Tingkatkan asupan nutrisi ibu menyusui',
          'Pemberian ASI on demand',
          'Pantau KMS di posyandu atau fasyankes terdekat',
        ],
        prescription: 'Vitamin D3 drop 400 IU 1x sehari',
        status: 'Selesai',
      ),
      ResumeMedisModel(
        id: 'resume-004',
        childId: childId,
        userId: userId,
        doctorName: 'dr. Ahmad Nuri, Sp. A',
        doctorSpecialization: 'Spesialis Anak',
        doctorPhoto: 'assets/images/doctor_ahmad_nuri.png',
        childName: childName,
        childAgeAtConsultation: '0 tahun 0 bulan 15 hari',
        consultationDate: '18 April 2026',
        consultationTime: '09.30- 10.00 WIB',
        bbLahir: bbLahir > 0 ? bbLahir : 2.4,
        bbSaatIni: 2.5,
        tbLahir: tbLahir > 0 ? tbLahir : 44.0,
        tbSaatIni: 45.0,
        complaint: 'Anak lahir prematur pada usia gestasi 35 minggu dengan BB 2.4 kg, tidak memenuhi berat badan lahir normal.',
        complaintShort: 'Anak lahir prematur dan tidak memenuhi BBL normal',
        doctorAssessment: 'Bayi prematur late-preterm dengan BBLR kondisi stabil tanpa tanda distress pernapasan.',
        summary: 'Pemeriksaan skrining neonatal awal baik. Terapi perawatan metode kanguru (KMC) dianjurkan.',
        recommendations: [
          'Terapkan metode kanguru di rumah untuk menjaga suhu tubuh hangat',
          'Jaga higienitas peralatan menyusui',
          'Kontrol bilirubin dan berat badan setiap minggu',
        ],
        prescription: 'Suplemen zat besi profilaksis',
        status: 'Selesai',
      ),
    ];
  }
}
