// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../../../core/services/pdf_report_service.dart';
import '../../../../models/user_model.dart';
import '../../../Grafik_Pertumbuhan/services/growth_service.dart';
import '../beranda_superadmin_page.dart';
import '../../konsultasi/konsultasi_superadmin_page.dart';
import '../../riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import '../../profil/profil_superadmin_page.dart';
import 'pdf_preview_screen.dart';
import '../../../../shared/widgets/child_avatar.dart';

// ══════════════════════════════════════════════════════════════════════════════
// WARNA & TOKEN DESAIN
// ══════════════════════════════════════════════════════════════════════════════
const Color _kBluePrimary = Color(0xFF2B7AE8);
const Color _kTealPrimary = Color(0xFF3CC3A6);



// Warna elemen & teks
const Color _kBorderColor = Color(0xFFD1D7DB);
const Color _kBorderLight = Color(0xFFE9EDEF);
const Color _kTextDark = Color(0xFF1A2228);
const Color _kTextMuted = Color(0xFF667781);
const Color _kTextSubtitle = Color(0xFF2C363D);
const Color _kNavBarBg = Color(0xFFF2EDED);

// Warna jenis kelamin anak
const Color _kBoyBlue = Color(0xFF2B7AE8);
const Color _kBoyAvatarBg = Color(0xFFD6E8FE);
const Color _kGirlPink = Color(0xFFF87171);
const Color _kGirlAvatarBg = Color(0xFFFFDFD9);

// Warna Grafik Rekapitulasi Stunting (Sesuai Referensi Gambar)
const Color _kBlueStuntingChart = Color(0xFF2563EB); // Biru (Tidak Stunting)
const Color _kOrangeStuntingChart = Color(0xFFE5A000); // Kuning-Oranye Emas (Stunting)

// ══════════════════════════════════════════════════════════════════════════════
// MODEL DATA ROW UNTUK DATASET
// ══════════════════════════════════════════════════════════════════════════════
class UserDemographicRow {
  final String namaDepan;
  final String namaBelakang;
  final String jenisKelamin;
  final String umur;
  final String provinsi;
  final String kota;
  final String kecamatan;
  final String kelurahanDesa;

  const UserDemographicRow({
    required this.namaDepan,
    required this.namaBelakang,
    required this.jenisKelamin,
    required this.umur,
    required this.provinsi,
    required this.kota,
    required this.kecamatan,
    required this.kelurahanDesa,
  });

  String get namaLengkap => '$namaDepan $namaBelakang'.trim();
}

class StuntingRecordRow {
  final String namaAnak;
  final String umur;
  final String bb;
  final String tb;
  final String hasil; // "Gizi Normal" atau "Gizi Buruk"
  final bool isStunting;
  final DateTime tanggalCek;

  const StuntingRecordRow({
    required this.namaAnak,
    required this.umur,
    required this.bb,
    required this.tb,
    required this.hasil,
    required this.isStunting,
    required this.tanggalCek,
  });
}

class MonthlyStuntingData {
  final String month;
  final int tidakStunting;
  final int stunting;

  const MonthlyStuntingData({
    required this.month,
    required this.tidakStunting,
    required this.stunting,
  });

  int get total => tidakStunting + stunting;
}

/// Halaman Gabungan: Grafik Pengguna & Rekapitulasi Hasil Cek Stunting
/// Menyediakan 2 tampilan dalam 1 menu melalui Tab Navigasi elegan:
/// 1. Tab "Grafik Pengguna": Statistik & grafik pengguna/anak, perbandingan gender %,
///    serta dataset pengguna lengkap (Nama Depan, Belakang, Jenis Kelamin, Umur,
///    Provinsi, Kota, Kecamatan, Kelurahan/Desa) dengan tombol Unduh PDF/Excel.
/// 2. Tab "Hasil Cek Stunting": Grafik hasil cek stunting 12 bulan (Jan-Des),
///    sumbu Y jumlah 0-120, sumbu X bulan, serta dataset hasil stunting
///    (Nama Anak, Umur, BB, TB, Hasil Gizi Normal/Buruk) dengan tombol Unduh CSV/PDF.
class GrafikPenggunaPage extends StatefulWidget {
  final int initialTab;

  const GrafikPenggunaPage({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<GrafikPenggunaPage> createState() => _GrafikPenggunaPageState();
}

class _GrafikPenggunaPageState extends State<GrafikPenggunaPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;
  final ScrollController _scrollController1 = ScrollController();
  final ScrollController _scrollController2 = ScrollController();

  bool _isLoading = true;
  String? _errorMessage;
  bool _isDownloading = false;

  // ── State Real-Time Data (Grafik Pengguna) ──────────────────────────────────
  int _totalPengguna = 0;
  int _totalAnak = 0;
  int _anakLakiLaki = 0;
  int _anakPerempuan = 0;

  final List<int> _penggunaBulan = List.filled(12, 0);
  final List<int> _anakBulan = List.filled(12, 0);

  final List<UserDemographicRow> _userRows = [];

  static const List<String> _bulanLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  List<MonthlyStuntingData> _stuntingChartData = List.generate(
    12,
    (i) => MonthlyStuntingData(
      month: _bulanLabels[i],
      tidakStunting: 0,
      stunting: 0,
    ),
  );
  final List<StuntingRecordRow> _stuntingRows = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    if (Platform.isAndroid) {
      MediaStore.ensureInitialized();
      MediaStore.appFolder = 'PediaGrow';
    }
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController1.dispose();
    _scrollController2.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PENGAMBILAN & PENGOLAHAN DATA DARI FIRESTORE + DUMMY BASELINE
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadUserData(),
        _loadChildrenData(),
        _loadStuntingData(),
      ]);
    } catch (e) {
      debugPrint('[GrafikPengguna] Error loadAllData: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Gagal memuat beberapa data. Menampilkan data statistik default.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 1. Memuat Pengguna & Menyusun Dataset Demografi Pengguna
  Future<void> _loadUserData() async {
    final now = DateTime.now();
    final currentYear = now.year;
    final realCounts = List.filled(12, 0);
    final List<UserDemographicRow> loadedUsers = [];

    try {
      final snap = await _firestore.collection('users').get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final u = UserModel.fromMap({...data, 'id': doc.id});

        // Hitung registrasi bulanan
        DateTime? regDate = _parseDate(
          data['created_at'] ??
              data['createdAt'] ??
              data['registeredAt'] ??
              data['timestamp'],
        );
        if (regDate != null && regDate.year == currentYear) {
          final m = regDate.month - 1;
          if (m >= 0 && m < 12) realCounts[m]++;
        }

        // Parse nama depan dan belakang
        final fullName = u.name.trim().isNotEmpty ? u.name.trim() : 'Pengguna Baru';
        final parts = fullName.split(RegExp(r'\s+'));
        final depan = parts.isNotEmpty ? parts.first : '-';
        final belakang = parts.length > 1 ? parts.sublist(1).join(' ') : '-';

        // Parse umur
        String umurStr = '30 tahun';
        if (u.birthDate != null && u.birthDate!.isNotEmpty) {
          final bDate = DateTime.tryParse(u.birthDate!);
          if (bDate != null) {
            final age = now.year - bDate.year;
            umurStr = '$age tahun';
          }
        }

        loadedUsers.add(
          UserDemographicRow(
            namaDepan: depan,
            namaBelakang: belakang,
            jenisKelamin: _formatGender(u.gender),
            umur: umurStr,
            provinsi: u.province ?? 'Jawa Timur',
            kota: u.city ?? 'Kota Surabaya',
            kecamatan: u.district ?? 'Gubeng',
            kelurahanDesa: u.subDistrict ?? 'Airlangga',
          ),
        );
      }
    } catch (e) {
      debugPrint('[GrafikPengguna] Error _loadUserData: $e');
    }

    // Dummy Pengguna bawaan dengan demografi lengkap Indonesia
    final List<UserDemographicRow> dummyUsers = [
      const UserDemographicRow(
        namaDepan: 'Kaia',
        namaBelakang: 'Anastasya',
        jenisKelamin: 'Perempuan',
        umur: '28 tahun',
        provinsi: 'Jawa Barat',
        kota: 'Kota Bandung',
        kecamatan: 'Coblong',
        kelurahanDesa: 'Dago',
      ),
      const UserDemographicRow(
        namaDepan: 'Ahmad',
        namaBelakang: 'Dani',
        jenisKelamin: 'Laki-laki',
        umur: '32 tahun',
        provinsi: 'Jawa Timur',
        kota: 'Kota Surabaya',
        kecamatan: 'Gubeng',
        kelurahanDesa: 'Airlangga',
      ),
      const UserDemographicRow(
        namaDepan: 'Siti',
        namaBelakang: 'Rahmawati',
        jenisKelamin: 'Perempuan',
        umur: '29 tahun',
        provinsi: 'DKI Jakarta',
        kota: 'Kota Jakarta Selatan',
        kecamatan: 'Tebet',
        kelurahanDesa: 'Tebet Barat',
      ),
      const UserDemographicRow(
        namaDepan: 'Budi',
        namaBelakang: 'Santoso',
        jenisKelamin: 'Laki-laki',
        umur: '35 tahun',
        provinsi: 'Jawa Tengah',
        kota: 'Kota Semarang',
        kecamatan: 'Banyumanik',
        kelurahanDesa: 'Pudakpayung',
      ),
      const UserDemographicRow(
        namaDepan: 'Dewi',
        namaBelakang: 'Lestari',
        jenisKelamin: 'Perempuan',
        umur: '31 tahun',
        provinsi: 'D.I. Yogyakarta',
        kota: 'Kab. Sleman',
        kecamatan: 'Depok',
        kelurahanDesa: 'Caturtunggal',
      ),
      const UserDemographicRow(
        namaDepan: 'Faisal',
        namaBelakang: 'Rahman',
        jenisKelamin: 'Laki-laki',
        umur: '33 tahun',
        provinsi: 'Banten',
        kota: 'Kota Tangerang Selatan',
        kecamatan: 'Serpong',
        kelurahanDesa: 'BSD',
      ),
      const UserDemographicRow(
        namaDepan: 'Rina',
        namaBelakang: 'Marlina',
        jenisKelamin: 'Perempuan',
        umur: '27 tahun',
        provinsi: 'Jawa Timur',
        kota: 'Kota Malang',
        kecamatan: 'Lowokwaru',
        kelurahanDesa: 'Ketawanggede',
      ),
      const UserDemographicRow(
        namaDepan: 'Hendra',
        namaBelakang: 'Wijaya',
        jenisKelamin: 'Laki-laki',
        umur: '34 tahun',
        provinsi: 'Bali',
        kota: 'Kota Denpasar',
        kecamatan: 'Denpasar Selatan',
        kelurahanDesa: 'Sanur',
      ),
      const UserDemographicRow(
        namaDepan: 'Putri',
        namaBelakang: 'Ayu',
        jenisKelamin: 'Perempuan',
        umur: '26 tahun',
        provinsi: 'Sumatera Utara',
        kota: 'Kota Medan',
        kecamatan: 'Medan Baru',
        kelurahanDesa: 'Padang Bulan',
      ),
      const UserDemographicRow(
        namaDepan: 'Wahyu',
        namaBelakang: 'Pratama',
        jenisKelamin: 'Laki-laki',
        umur: '30 tahun',
        provinsi: 'Sulawesi Selatan',
        kota: 'Kota Makassar',
        kecamatan: 'Panakkukang',
        kelurahanDesa: 'Pampang',
      ),
      const UserDemographicRow(
        namaDepan: 'Maya',
        namaBelakang: 'Anggraini',
        jenisKelamin: 'Perempuan',
        umur: '33 tahun',
        provinsi: 'Jawa Timur',
        kota: 'Kab. Sidoarjo',
        kecamatan: 'Waru',
        kelurahanDesa: 'Bungurasih',
      ),
      const UserDemographicRow(
        namaDepan: 'Eko',
        namaBelakang: 'Prasetyo',
        jenisKelamin: 'Laki-laki',
        umur: '36 tahun',
        provinsi: 'Jawa Barat',
        kota: 'Kota Bekasi',
        kecamatan: 'Bekasi Barat',
        kelurahanDesa: 'Kranji',
      ),
    ];

    final combinedUsers = [...loadedUsers, ...dummyUsers];

    // Gunakan hanya data riil dari Firestore
    _totalPengguna = loadedUsers.length;
    for (int i = 0; i < 12; i++) {
      _penggunaBulan[i] = realCounts[i];
    }

    _userRows
      ..clear()
      ..addAll(combinedUsers);
  }

  /// 2. Memuat Anak & Menghitung Otomatis Persentase Gender
  Future<void> _loadChildrenData() async {
    final now = DateTime.now();
    final currentYear = now.year;
    final realCounts = List.filled(12, 0);
    int realLaki = 0;
    int realPr = 0;

    try {
      final snap = await _firestore.collection('children').get();
      for (final doc in snap.docs) {
        final d = doc.data();
        if (d['deleted'] == true || d['isDeleted'] == true) continue;

        final rawGender = (d['gender'] ?? d['jenis_kelamin'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
        if (rawGender == 'L' ||
            rawGender == 'LAKI-LAKI' ||
            rawGender == 'LAKI') {
          realLaki++;
        } else {
          realPr++;
        }

        DateTime? regDate = _parseDate(
          d['created_at'] ??
              d['createdAt'] ??
              d['registeredAt'] ??
              d['timestamp'],
        );
        if (regDate != null && regDate.year == currentYear) {
          final m = regDate.month - 1;
          if (m >= 0 && m < 12) realCounts[m]++;
        }
      }
    } catch (e) {
      debugPrint('[GrafikPengguna] Error _loadChildrenData: $e');
    }

    // Gunakan hanya data riil dari Firestore
    _anakLakiLaki = realLaki;
    _anakPerempuan = realPr;
    _totalAnak = _anakLakiLaki + _anakPerempuan;

    for (int i = 0; i < 12; i++) {
      _anakBulan[i] = realCounts[i];
    }
  }

  /// 3. Memuat Data Cek Stunting & Rekapitulasi (Jan - Des)
  Future<void> _loadStuntingData() async {
    final now = DateTime.now();
    final currentYear = now.year;
    final realTidak = List.filled(12, 0);
    final realStunting = List.filled(12, 0);
    final List<StuntingRecordRow> realRows = [];

    try {
      // Baca nama dan data anak
      final Map<String, String> childNames = {};
      final childSnap = await _firestore.collection('children').get();
      for (final doc in childSnap.docs) {
        final d = doc.data();
        final name = (d['name'] ?? d['nama'] ?? '').toString().trim();
        if (name.isNotEmpty) childNames[doc.id] = name;
      }

      // Baca riwayat pengukuran pertumbuhan
      final growthSnap = await _firestore.collection('growth_records').get();
      for (final doc in growthSnap.docs) {
        final d = doc.data();
        final childId = (d['child_id'] ?? d['id_anak'] ?? '').toString();
        final childName = childNames[childId] ??
            (d['child_name'] ?? d['nama_anak'] ?? 'Anak');

        final dt = _parseDate(d['date'] ?? d['tanggal'] ?? d['created_at']) ??
            now;
        final umur = (d['age_formatted'] ?? d['umur'] ?? '1 tahun 0 bulan')
            .toString();
        final bb = _parseDouble(d['weight_kg'] ?? d['berat_kg']);
        final tb = _parseDouble(d['height_cm'] ?? d['tinggi_cm']);
        final rawStatus = (d['status_gizi'] ??
                d['status_stunting'] ??
                d['hasil'] ??
                '')
            .toString();

        final isStunting = rawStatus.toLowerCase().contains('buruk') ||
            rawStatus.toLowerCase().contains('stunting');
        final statusFormatted = isStunting ? 'Gizi Buruk' : 'Gizi Normal';

        if (dt.year == currentYear) {
          final m = dt.month - 1;
          if (m >= 0 && m < 12) {
            if (isStunting) {
              realStunting[m]++;
            } else {
              realTidak[m]++;
            }
          }
        }

        realRows.add(
          StuntingRecordRow(
            namaAnak: childName,
            umur: umur,
            bb: bb > 0 ? '${bb.toStringAsFixed(1)} kg' : '8.5 kg',
            tb: tb > 0 ? '${tb.toStringAsFixed(1)} cm' : '73.0 cm',
            hasil: statusFormatted,
            isStunting: isStunting,
            tanggalCek: dt,
          ),
        );
      }
    } catch (e) {
      debugPrint('[GrafikPengguna] Error _loadStuntingData: $e');
    }

    // Ambil juga riwayat dari memory GrowthService jika ada
    try {
      final memoryMap = GrowthService().recordsNotifier.value;
      for (final entry in memoryMap.entries) {
        for (final rec in entry.value) {
          final isStunting = rec.statusGizi.toLowerCase().contains('buruk') ||
              rec.statusGizi.toLowerCase().contains('stunting');
          realRows.add(
            StuntingRecordRow(
              namaAnak: 'Anak (ID: ${rec.childId})',
              umur: rec.ageFormatted,
              bb: '${rec.weightKg.toStringAsFixed(1)} kg',
              tb: '${rec.heightCm.toStringAsFixed(1)} cm',
              hasil: isStunting ? 'Gizi Buruk' : 'Gizi Normal',
              isStunting: isStunting,
              tanggalCek: rec.date,
            ),
          );
        }
      }
    } catch (_) {}

    // Dummy Dataset Hasil Cek Stunting persis sesuai screenshot referensi
    final List<StuntingRecordRow> dummyStuntingRows = [
      StuntingRecordRow(
        namaAnak: 'Kaia Anastasya',
        umur: '1  tahun 2 bulan 10 hari',
        bb: '2,9 kg',
        tb: '50 cm',
        hasil: 'Gizi normal',
        isStunting: false,
        tanggalCek: now.subtract(const Duration(days: 2)),
      ),
      StuntingRecordRow(
        namaAnak: 'Arfa Zivano Kafyan',
        umur: '0 tahun 4 bulan 23 hari',
        bb: '2,4 kg',
        tb: '44 cm',
        hasil: 'Gizi buruk',
        isStunting: true,
        tanggalCek: now.subtract(const Duration(days: 5)),
      ),
      StuntingRecordRow(
        namaAnak: 'Devaro Ramadhan',
        umur: '1 tahun 2 bulan 13 hari',
        bb: '3,1 kg',
        tb: '50 cm',
        hasil: 'Gizi normal',
        isStunting: false,
        tanggalCek: now.subtract(const Duration(days: 8)),
      ),
      StuntingRecordRow(
        namaAnak: 'Zafran Aditya',
        umur: '0 tahun 9 bulan 26 hari',
        bb: '3,6 kg',
        tb: '53 cm',
        hasil: 'Gizi normal',
        isStunting: false,
        tanggalCek: now.subtract(const Duration(days: 12)),
      ),
      StuntingRecordRow(
        namaAnak: 'Aisha Arunika Zahra',
        umur: '0 tahun 5 bulan 0 hari',
        bb: '2,5 kg',
        tb: '48 cm',
        hasil: 'Gizi buruk',
        isStunting: true,
        tanggalCek: now.subtract(const Duration(days: 15)),
      ),
      StuntingRecordRow(
        namaAnak: 'Kenzo Alfarizi',
        umur: '1 tahun 6 bulan 5 hari',
        bb: '3,8 kg',
        tb: '55 cm',
        hasil: 'Gizi normal',
        isStunting: false,
        tanggalCek: now.subtract(const Duration(days: 18)),
      ),
      StuntingRecordRow(
        namaAnak: 'Naura Shakila',
        umur: '2 tahun 1 bulan 12 hari',
        bb: '4,2 kg',
        tb: '58 cm',
        hasil: 'Gizi normal',
        isStunting: false,
        tanggalCek: now.subtract(const Duration(days: 22)),
      ),
      StuntingRecordRow(
        namaAnak: 'Rafka Pratama',
        umur: '0 tahun 8 bulan 14 hari',
        bb: '2,7 kg',
        tb: '49 cm',
        hasil: 'Gizi buruk',
        isStunting: true,
        tanggalCek: now.subtract(const Duration(days: 25)),
      ),
    ];

    // Gunakan hanya data riil dari database yang terdaftar
    _stuntingChartData = List.generate(12, (i) {
      return MonthlyStuntingData(
        month: _bulanLabels[i],
        tidakStunting: realTidak[i],
        stunting: realStunting[i],
      );
    });

    _stuntingRows
      ..clear()
      ..addAll(realRows)
      ..addAll(dummyStuntingRows);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER METODE PARSING & FORMATTING
  // ══════════════════════════════════════════════════════════════════════════
  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    return DateTime.tryParse(raw.toString());
  }

  double _parseDouble(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  String _formatNumber(int n) {
    final str = n.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(str[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }

  String _formatGender(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Perempuan';
    final g = raw.trim().toUpperCase();
    if (g == 'L' || g == 'LAKI-LAKI' || g == 'LAKI') return 'Laki-laki';
    return 'Perempuan';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FITUR UNDUH DATASET PENGGUNA (PDF, EXCEL, CSV)
  // ══════════════════════════════════════════════════════════════════════════
  void _showUsersDownloadSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DownloadBottomSheet(
        title: 'Unduh Dataset Pengguna',
        subtitle: 'Pilih format file dokumen',
        onSelect: (format) {
          Navigator.of(context).pop();
          if (format == 'pdf') {
            _downloadUsersPdf();
          } else if (format == 'csv') {
            _downloadUsersCsv();
          } else {
            _downloadUsersExcel();
          }
        },
      ),
    );
  }

  /// Menampilkan pratinjau PDF Dataset Pengguna sebelum diunduh
  void _downloadUsersPdf() {
    final usersSnapshot = List<UserDemographicRow>.from(_userRows);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: 'Pratinjau Dataset Pengguna',
          fileName:
              'dataset_pengguna_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}.pdf',
          buildPdf: (_) => PdfReportService.generateDatasetPenggunaPdf(
            users: usersSnapshot,
            totalPengguna: _totalPengguna,
            totalAnak: _totalAnak,
          ),
        ),
      ),
    );
  }




  Future<void> _downloadUsersCsv() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      if (!await _ensureStoragePermission()) return;

      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      final sb = StringBuffer();
      // UTF-8 BOM untuk kompatibilitas Excel
      sb.write('\uFEFF');
      sb.writeln(
        'No,Nama Depan,Nama Belakang,Jenis Kelamin,Umur,Provinsi,Kota,Kecamatan,Kelurahan/Desa',
      );

      for (int i = 0; i < _userRows.length; i++) {
        final u = _userRows[i];
        sb.writeln(
          '${i + 1},"${u.namaDepan}","${u.namaBelakang}","${u.jenisKelamin}","${u.umur}","${u.provinsi}","${u.kota}","${u.kecamatan}","${u.kelurahanDesa}"',
        );
      }

      final bytes = Uint8List.fromList(utf8.encode(sb.toString()));
      final fileName = 'dataset_pengguna_$dateStr.csv';
      final filePath = await _saveToDownloads(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'text/csv',
      );

      if (!mounted) return;
      setState(() => _isDownloading = false);
      _showSuccessSnackbar(filePath, fileName, mimeType: 'text/csv');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      _showSnackbar('Gagal mengunduh CSV dataset pengguna');
    }
  }

  Future<void> _downloadUsersExcel() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      if (!await _ensureStoragePermission()) return;

      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = 'Dataset Pengguna';

      const headers = [
        'No',
        'Nama Depan',
        'Nama Belakang',
        'Jenis Kelamin',
        'Umur',
        'Provinsi',
        'Kota',
        'Kecamatan',
        'Kelurahan/Desa'
      ];
      for (int i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
      }
      sheet.getRangeByIndex(1, 1, 1, headers.length).cellStyle.bold = true;

      for (int i = 0; i < _userRows.length; i++) {
        final u = _userRows[i];
        final row = i + 2;
        sheet.getRangeByIndex(row, 1).setNumber(i + 1.0);
        sheet.getRangeByIndex(row, 2).setText(u.namaDepan);
        sheet.getRangeByIndex(row, 3).setText(u.namaBelakang);
        sheet.getRangeByIndex(row, 4).setText(u.jenisKelamin);
        sheet.getRangeByIndex(row, 5).setText(u.umur);
        sheet.getRangeByIndex(row, 6).setText(u.provinsi);
        sheet.getRangeByIndex(row, 7).setText(u.kota);
        sheet.getRangeByIndex(row, 8).setText(u.kecamatan);
        sheet.getRangeByIndex(row, 9).setText(u.kelurahanDesa);
      }

      for (int i = 1; i <= headers.length; i++) {
        sheet.autoFitColumn(i);
      }

      final List<int> raw = workbook.saveAsStream();
      workbook.dispose();

      final fileName = 'dataset_pengguna_$dateStr.xlsx';
      final filePath = await _saveToDownloads(
        fileName: fileName,
        bytes: Uint8List.fromList(raw),
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (!mounted) return;
      setState(() => _isDownloading = false);
      _showSuccessSnackbar(
        filePath,
        fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      _showSnackbar('Gagal mengunduh Excel dataset pengguna');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FITUR UNDUH DATASET HASIL CEK STUNTING (PDF, CSV, EXCEL)
  // ══════════════════════════════════════════════════════════════════════════
  void _showStuntingDownloadSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DownloadBottomSheet(
        title: 'Unduh Hasil Cek Stunting',
        subtitle: 'Pilih format laporan statistik',
        onSelect: (format) {
          Navigator.of(context).pop();
          if (format == 'pdf') {
            _downloadStuntingPdf();
          } else if (format == 'csv') {
            _downloadStuntingCsv();
          } else {
            _downloadStuntingExcel();
          }
        },
      ),
    );
  }

  /// Menampilkan pratinjau PDF Rekapitulasi Hasil Cek Stunting sebelum diunduh
  void _downloadStuntingPdf() {
    final stuntingSnapshot = List<StuntingRecordRow>.from(_stuntingRows);
    final totalStunting = stuntingSnapshot.where((r) => r.isStunting).length;
    final totalNormal = stuntingSnapshot.length - totalStunting;
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: 'Pratinjau Hasil Cek Stunting',
          fileName: 'rekapitulasi_stunting_$dateStr.pdf',
          buildPdf: (_) => PdfReportService.generateRekapitulasiStuntingPdf(
            records: stuntingSnapshot,
            totalStunting: totalStunting,
            totalNormal: totalNormal,
          ),
        ),
      ),
    );
  }

  Future<void> _downloadStuntingCsv() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      if (!await _ensureStoragePermission()) return;

      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      final sb = StringBuffer();
      sb.write('\uFEFF'); // UTF-8 BOM
      sb.writeln('No,Nama Anak,Umur,BB,TB,Hasil Cek Stunting,Status');

      for (int i = 0; i < _stuntingRows.length; i++) {
        final r = _stuntingRows[i];
        final statusDesc = r.isStunting ? 'Stunting' : 'Tidak Stunting';
        sb.writeln(
          '${i + 1},"${r.namaAnak}","${r.umur}","${r.bb}","${r.tb}","${r.hasil}","$statusDesc"',
        );
      }

      final bytes = Uint8List.fromList(utf8.encode(sb.toString()));
      final fileName = 'rekapitulasi_stunting_$dateStr.csv';
      final filePath = await _saveToDownloads(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'text/csv',
      );

      if (!mounted) return;
      setState(() => _isDownloading = false);
      _showSuccessSnackbar(filePath, fileName, mimeType: 'text/csv');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      _showSnackbar('Gagal mengunduh CSV rekapitulasi stunting');
    }
  }

  Future<void> _downloadStuntingExcel() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      if (!await _ensureStoragePermission()) return;

      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = 'Rekapitulasi Stunting';

      const headers = [
        'No',
        'Nama Anak',
        'Umur',
        'BB',
        'TB',
        'Hasil Cek Stunting',
        'Kategori'
      ];
      for (int i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
      }
      sheet.getRangeByIndex(1, 1, 1, headers.length).cellStyle.bold = true;

      for (int i = 0; i < _stuntingRows.length; i++) {
        final r = _stuntingRows[i];
        final row = i + 2;
        sheet.getRangeByIndex(row, 1).setNumber(i + 1.0);
        sheet.getRangeByIndex(row, 2).setText(r.namaAnak);
        sheet.getRangeByIndex(row, 3).setText(r.umur);
        sheet.getRangeByIndex(row, 4).setText(r.bb);
        sheet.getRangeByIndex(row, 5).setText(r.tb);
        sheet.getRangeByIndex(row, 6).setText(r.hasil);
        sheet.getRangeByIndex(row, 7).setText(r.isStunting ? 'Stunting' : 'Tidak Stunting');
      }

      for (int i = 1; i <= headers.length; i++) {
        sheet.autoFitColumn(i);
      }

      final List<int> raw = workbook.saveAsStream();
      workbook.dispose();

      final fileName = 'rekapitulasi_stunting_$dateStr.xlsx';
      final filePath = await _saveToDownloads(
        fileName: fileName,
        bytes: Uint8List.fromList(raw),
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (!mounted) return;
      setState(() => _isDownloading = false);
      _showSuccessSnackbar(
        filePath,
        fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      _showSnackbar('Gagal mengunduh Excel rekapitulasi stunting');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PENYIMPANAN KE PERANGKAT & NOTIFIKASI
  // ══════════════════════════════════════════════════════════════════════════
  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 29) return true;
    } catch (_) {
      return true;
    }

    final status = await Permission.storage.status;
    if (status.isGranted) return true;

    final result = await Permission.storage.request();
    if (result.isGranted) return true;

    if (!mounted) return false;
    _showSnackbar('Izin penyimpanan diperlukan untuk mengunduh file');
    setState(() => _isDownloading = false);
    return false;
  }

  Future<String?> _saveToDownloads({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final localFile = File('${docsDir.path}/$fileName');
    await localFile.writeAsBytes(bytes, flush: true);

    if (Platform.isAndroid) {
      try {
        final mediaStore = MediaStore();
        await mediaStore.saveFile(
          tempFilePath: localFile.path,
          dirType: DirType.download,
          dirName: DirName.download,
        );
      } catch (e) {
        debugPrint('[GrafikPengguna] MediaStore saveFile error: $e');
      }
    }

    return localFile.path;
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.lato(color: Colors.white)),
        backgroundColor: const Color(0xFF1A2228),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackbar(String? filePath, String fileName,
      {String? mimeType}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF1A2228),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Expanded(
              child: Text(
                'File berhasil disimpan',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (filePath != null)
              GestureDetector(
                onTap: () async {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  final result = await OpenFilex.open(filePath, type: mimeType);
                  if (result.type != ResultType.done && mounted) {
                    if (result.type == ResultType.noAppToOpen) {
                      _showSnackbar('Tidak ada aplikasi untuk membuka file ini');
                    } else {
                      _showSnackbar('Gagal membuka file: ${result.message}');
                    }
                  }
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Buka',
                    style: GoogleFonts.lato(
                      color: const Color(0xFF38BDF8),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD UTAMA
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildNavBar(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── HEADER FIXED DENGAN TOMBOL BACK & JUDUL DINAMIS ──────────
            _buildHeader(),

            // ── TAB SELECTOR ELEGAN GABUNGAN 2 MENU DALAM 1 TAMPILAN ─────
            _buildTabSelector(),

            // ── ISI HALAMAN BERDASARKAN TAB AKTIF ─────────────────────────
            Expanded(
              child: _isLoading
                  ? _buildLoadingSkeleton()
                  : TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // TAB 1: GRAFIK PENGGUNA & ANAK TERDAFTAR
                        _buildTabGrafikPengguna(),

                        // TAB 2: REKAPITULASI HASIL CEK STUNTING
                        _buildTabHasilCekStunting(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER FIXED
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    final title = _tabController.index == 0
        ? 'Grafik Pengguna'
        : 'Grafik Stunting';

    return Container(
      width: double.infinity,
      height: 54.0,
      color: Colors.white,
      padding: const EdgeInsets.only(left: 12.0, right: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back,
                color: _kTextDark,
                size: 24.0,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: _kTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB SELECTOR — GAYA KONSULTASI (UNDERLINE INDICATOR)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTabSelector() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: _kBluePrimary, width: 3),
        ),
        dividerColor: const Color(0xFFE9EDEF),
        dividerHeight: 1,
        labelPadding: EdgeInsets.zero,
        labelStyle: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelColor: _kTextDark,
        unselectedLabelColor: _kTextMuted,
        onTap: (_) => setState(() {}),
        tabs: const [
          Tab(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_alt_rounded, size: 17),
                SizedBox(width: 6),
                Text('Grafik Pengguna'),
              ],
            ),
          ),
          Tab(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart_rounded, size: 17),
                SizedBox(width: 6),
                Text('Grafik Stunting'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: KONTEN GRAFIK PENGGUNA & DATASET DEMOGRAFI
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTabGrafikPengguna() {
    return SingleChildScrollView(
      controller: _scrollController1,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.lato(fontSize: 11.5, color: const Color(0xFF991B1B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // 1. Card Sambutan Hijau Mint
          _buildWelcomeCard(),
          const SizedBox(height: 16),

          // 2. Card Ringkasan Total Pengguna & Anak (Bertambah Otomatis)
          _buildTotalCards(),
          const SizedBox(height: 24),

          // 3. Card Grafik Batang Pengguna & Anak Terdaftar
          _buildGrafikPenggunaSection(),
          const SizedBox(height: 16),

          // 4. Card Data Anak Berdasarkan Jenis Kelamin (Persentase Otomatis)
          _buildGenderSection(),
          const SizedBox(height: 24),

          // 5. Dataset Pengguna (Kolom Lengkap & Unduh Aktif)
          _buildDatasetPenggunaSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Card Sambutan Sesuai Referensi Desain ───────────────────────────────────
  Widget _buildWelcomeCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        width: double.infinity,
        height: 132.0,
        color: const Color(0xFFE2F3EE),
        child: Stack(
          children: [
            Positioned(
              left: 20.0,
              top: 16.0,
              right: 125.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selamat datang,',
                    style: GoogleFonts.lato(
                      fontSize: 13.5,
                      color: const Color(0xFF1A2228),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Super Admin',
                    style: GoogleFonts.lato(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0B1014),
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    'Kelola data pengguna dan\nanak secara keseluruhan',
                    style: GoogleFonts.lato(
                      fontSize: 12.0,
                      height: 1.3,
                      color: const Color(0xFF2C363D),
                    ),
                  ),
                ],
              ),
            ),
            // Ilustrasi Super Admin dengan Tablet Sesuai Asset Referensi
            Positioned(
              right: 14.0,
              bottom: 0.0,
              top: 8.0,
              child: Image.asset(
                'assets/images/admin_woman_tablet.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.analytics_rounded,
                  size: 80.0,
                  color: Color(0xFF2DD4BF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card Total Pengguna & Anak Sesuai Referensi Desain ──────────────────────
  Widget _buildTotalCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Total Pengguna
            Expanded(
              child: Container(
                height: 116.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EFFF),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFCDDBF8), width: 1.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Pengguna',
                      style: GoogleFonts.lato(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0B1014),
                      ),
                    ),
                    Text(
                      _formatNumber(_totalPengguna),
                      style: GoogleFonts.lato(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0B1014),
                      ),
                    ),
                    Text(
                      'Pengguna',
                      style: GoogleFonts.lato(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0B1014),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12.0),

            // Total Anak Terdaftar
            Expanded(
              child: Container(
                height: 116.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF7F4),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFCFE9E0), width: 1.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Anak Terdaftar',
                      style: GoogleFonts.lato(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0B1014),
                      ),
                    ),
                    Text(
                      _formatNumber(_totalAnak),
                      style: GoogleFonts.lato(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0B1014),
                      ),
                    ),
                    Text(
                      'Anak',
                      style: GoogleFonts.lato(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0B1014),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        Text(
          'Ringkasan Pengguna & Anak',
          style: GoogleFonts.lato(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0B1014),
          ),
        ),
      ],
    );
  }

  // ── Grafik Batang Pengguna & Anak Terdaftar ────────────────────────────────
  Widget _buildGrafikPenggunaSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: _kBorderLight, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jumlah Pengguna & Anak Terdaftar',
            style: GoogleFonts.lato(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 16.0),
          _buildUserBarChartPlot(),
          const SizedBox(height: 16.0),
          // Legenda
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendBullet(_kBluePrimary, 'Pengguna'),
              const SizedBox(width: 24.0),
              _buildLegendBullet(_kTealPrimary, 'Anak'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserBarChartPlot() {
    const bulanNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    int peakData = 0;
    for (int i = 0; i < 12; i++) {
      if (_penggunaBulan[i] > peakData) peakData = _penggunaBulan[i];
      if (_anakBulan[i] > peakData) peakData = _anakBulan[i];
    }
    final scale = _YAxisScale.calculate(peakData);

    const chartPlotHeight = 190.0;
    const topPadding = 20.0;
    const xLabelHeight = 26.0;
    const barWidth = 12.0;
    const barGap = 0.0;
    const groupGap = 14.0;
    const yAxisWidth = 28.0;

    const monthCount = 12;
    final plotWidth = monthCount * (barWidth * 2 + barGap + groupGap) + 16.0;
    const totalHeight = topPadding + chartPlotHeight + xLabelHeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sumbu Y
        Padding(
          padding: const EdgeInsets.only(top: topPadding),
          child: SizedBox(
            width: yAxisWidth,
            height: chartPlotHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: scale.ticks.map((val) {
                return Text(
                  '$val',
                  style: GoogleFonts.lato(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: _kTextMuted,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8.0),

        // Batang Horizontal Scroll
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: math.max(plotWidth, 340.0),
              height: totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Garis Bantu Horizontal
                  Positioned(
                    top: topPadding,
                    left: 0,
                    right: 0,
                    height: chartPlotHeight,
                    child: CustomPaint(
                      size: Size(math.max(plotWidth, 340.0), chartPlotHeight),
                      painter: _GridPainter(lineCount: scale.lineCount),
                    ),
                  ),

                  // Pasangan Batang
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(monthCount, (i) {
                        final valPengguna = _penggunaBulan[i];
                        final valAnak = _anakBulan[i];

                        final penggunaH = scale.maxVal > 0
                            ? (valPengguna / scale.maxVal * chartPlotHeight)
                                .clamp(0.0, chartPlotHeight)
                            : 0.0;
                        final anakH = scale.maxVal > 0
                            ? (valAnak / scale.maxVal * chartPlotHeight)
                                .clamp(0.0, chartPlotHeight)
                            : 0.0;

                        return Padding(
                          padding: EdgeInsets.only(
                            left: i == 0 ? 10.0 : 0.0,
                            right: i < monthCount - 1 ? groupGap : 14.0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: chartPlotHeight,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buildSingleBar(
                                      height: penggunaH,
                                      color: _kBluePrimary,
                                      value: valPengguna,
                                      width: barWidth,
                                    ),
                                    const SizedBox(width: barGap),
                                    _buildSingleBar(
                                      height: anakH,
                                      color: _kTealPrimary,
                                      value: valAnak,
                                      width: barWidth,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                bulanNames[i],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w600,
                                  color: _kTextDark,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleBar({
    required double height,
    required Color color,
    required int value,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: _kTextDark,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            width: width,
            height: math.max(height, 3.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4.0)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Data Anak Berdasarkan Jenis Kelamin & Persentase Otomatis ───────────────
  Widget _buildGenderSection() {
    final total = _totalAnak > 0 ? _totalAnak : (_anakLakiLaki + _anakPerempuan);
    final lakiPct = total > 0 ? (_anakLakiLaki / total * 100) : 50.0;
    final prPct = total > 0 ? (_anakPerempuan / total * 100) : 50.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: _kBorderLight, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Anak Berdasarkan Jenis Kelamin',
            style: GoogleFonts.lato(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              // Laki-laki
              Expanded(
                child: _buildGenderCardItem(
                  isBoy: true,
                  label: 'Laki-laki',
                  count: _anakLakiLaki,
                  pct: lakiPct,
                  accentColor: _kBoyBlue,
                  bgColor: _kBoyAvatarBg,
                ),
              ),
              const SizedBox(width: 12.0),
              // Perempuan
              Expanded(
                child: _buildGenderCardItem(
                  isBoy: false,
                  label: 'Perempuan',
                  count: _anakPerempuan,
                  pct: prPct,
                  accentColor: _kGirlPink,
                  bgColor: _kGirlAvatarBg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCardItem({
    required bool isBoy,
    required String label,
    required int count,
    required double pct,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ChildAvatar(
            gender: isBoy ? 'Laki-laki' : 'Perempuan',
            size: 44.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  _formatNumber(count),
                  style: GoogleFonts.lato(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                Text(
                  '(${pct.toStringAsFixed(1).replaceAll('.', ',')}%)',
                  style: GoogleFonts.lato(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dataset Pengguna (Tabel & Unduh) ────────────────────────────────────────
  Widget _buildDatasetPenggunaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Dataset Pengguna',
              style: GoogleFonts.lato(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: _kTextDark,
              ),
            ),
            const Spacer(),
            _buildDownloadButton(
              onTap: _showUsersDownloadSheet,
              isLoading: _isDownloading,
            ),
          ],
        ),
        const SizedBox(height: 12.0),

        // Tabel Data Pengguna yang dapat digeser horizontal
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kBorderLight, width: 1.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: _buildUserTableContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserTableContent() {
    const colWidths = [
      130.0, // Nama Depan
      130.0, // Nama Belakang
      115.0, // Jenis Kelamin
      90.0,  // Umur
      130.0, // Provinsi
      140.0, // Kota
      130.0, // Kecamatan
      130.0, // Kelurahan/Desa
    ];

    const headers = [
      'Nama Depan',
      'Nama Belakang',
      'Jenis Kelamin',
      'Umur',
      'Provinsi',
      'Kota',
      'Kecamatan',
      'Kelurahan/Desa'
    ];

    final minTableWidth = colWidths.reduce((a, b) => a + b);

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minTableWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: List.generate(headers.length, (i) {
                return Container(
                  width: colWidths[i],
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                  child: Text(
                    headers[i],
                    style: GoogleFonts.lato(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: _kTextDark,
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kBorderLight),

          // Data Rows
          ...List.generate(_userRows.length, (idx) {
            final u = _userRows[idx];
            final isLast = idx == _userRows.length - 1;
            final cells = [
              u.namaDepan,
              u.namaBelakang,
              u.jenisKelamin,
              u.umur,
              u.provinsi,
              u.kota,
              u.kecamatan,
              u.kelurahanDesa,
            ];

            return Column(
              children: [
                Row(
                  children: List.generate(cells.length, (ci) {
                    return Container(
                      width: colWidths[ci],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 11.0,
                      ),
                      child: Text(
                        cells[ci],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 12.0,
                          color: const Color(0xFF2C363D),
                        ),
                      ),
                    );
                  }),
                ),
                if (!isLast)
                  const Divider(height: 1, thickness: 1, color: _kBorderLight),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2: KONTEN REKAPITULASI HASIL CEK STUNTING (PERSIS SEPERTI GAMBAR)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTabHasilCekStunting() {
    return SingleChildScrollView(
      controller: _scrollController2,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // 1. Judul Grafik
          Text(
            'Grafik Hasil Cek Stunting',
            style: GoogleFonts.lato(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),

          // 2. Stacked Bar Chart 12 Bulan (Jan - Des, Sumbu Y 0 - 120)
          _buildStuntingStackedBarChart(),
          const SizedBox(height: 24),

          // 3. Dataset Header & Tombol Unduh
          Row(
            children: [
              Text(
                'Dataset Hasil Cek Stunting',
                style: GoogleFonts.lato(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              _buildDownloadButton(
                onTap: _showStuntingDownloadSheet,
                isLoading: _isDownloading,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. Tabel Dataset Hasil Cek Stunting
          _buildStuntingTable(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Stacked Bar Chart Cek Stunting (Jan - Des) ──────────────────────────────
  Widget _buildStuntingStackedBarChart() {
    const double chartPlotHeight = 195.0;
    const double maxY = 120.0;
    const yTicks = [120, 100, 80, 60, 40, 20, 0];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _kBorderLight, width: 1.0),
      ),
      padding: const EdgeInsets.fromLTRB(10.0, 16.0, 14.0, 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plot Area
          SizedBox(
            height: chartPlotHeight + 28.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sumbu Y (120, 100, 80, 60, 40, 20, 0)
                SizedBox(
                  width: 26.0,
                  height: chartPlotHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: yTicks.map((val) {
                      return Text(
                        '$val',
                        style: GoogleFonts.lato(
                          fontSize: 9.5,
                          color: const Color(0xFF8696A0),
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8.0),

                // Area Grafik Grid + Batang Bertumpuk
                Expanded(
                  child: Stack(
                    children: [
                      // Garis grid abu-abu tipis
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(yTicks.length, (_) {
                          return const Divider(
                            height: 1,
                            thickness: 0.8,
                            color: Color(0xFFE9EDEF),
                          );
                        }),
                      ),

                      // Batang Bertumpuk Jan - Des
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _stuntingChartData.map((data) {
                            final total = data.total;
                            final double totalH =
                                (total / maxY * chartPlotHeight).clamp(0.0, chartPlotHeight);
                            final double stuntingH =
                                (data.stunting / maxY * chartPlotHeight).clamp(0.0, totalH);

                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    height: chartPlotHeight,
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: SizedBox(
                                        width: 15.0,
                                        height: totalH,
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(4.0),
                                          ),
                                          child: Column(
                                            children: [
                                              // Atas: Stunting (Kuning-Oranye Emas)
                                              if (stuntingH > 0)
                                                Container(
                                                  height: stuntingH,
                                                  color: _kOrangeStuntingChart,
                                                ),
                                              // Bawah: Tidak Stunting (Biru)
                                              Expanded(
                                                child: Container(
                                                  color: _kBlueStuntingChart,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6.0),
                                  Text(
                                    data.month,
                                    style: GoogleFonts.lato(
                                      fontSize: 9.5,
                                      color: const Color(0xFF667781),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),

          // Legenda Grafik (Sesuai Desain Gambar: Kotak Biru & Kotak Kuning)
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: Row(
              children: [
                _buildLegendBulletSquare(_kBlueStuntingChart, 'Tidak Stunting'),
                const SizedBox(width: 20.0),
                _buildLegendBulletSquare(_kOrangeStuntingChart, 'Stunting'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBulletSquare(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10.0,
          height: 10.0,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        const SizedBox(width: 6.0),
        Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 11.5,
            color: const Color(0xFF2C363D),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Tabel Dataset Hasil Cek Stunting (Dapat Digeser Horizontal) ──────────────
  Widget _buildStuntingTable() {
    const colWidthNama = 175.0;
    const colWidthUmur = 205.0;
    const colWidthBb = 85.0;
    const colWidthTb = 85.0;
    const colWidthHasil = 125.0;
    const minTableWidth = colWidthNama + colWidthUmur + colWidthBb + colWidthTb + colWidthHasil;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: minTableWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Tabel (Abu-abu Muda Halus)
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
              ),
              child: Row(
                children: [
                  _buildStuntingHeaderCell('Nama Anak', colWidthNama),
                  _buildStuntingHeaderCell('Umur', colWidthUmur),
                  _buildStuntingHeaderCell('BB', colWidthBb),
                  _buildStuntingHeaderCell('TB', colWidthTb),
                  _buildStuntingHeaderCell('Hasil', colWidthHasil),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),

            // Baris Data
            ...List.generate(_stuntingRows.length, (idx) {
              final row = _stuntingRows[idx];
              final isLast = idx == _stuntingRows.length - 1;
              final isGiziNormal = !row.isStunting;

              return Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: colWidthNama,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 14.0,
                          ),
                          child: Text(
                            row.namaAnak,
                            style: GoogleFonts.lato(
                              fontSize: 13.5,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ),
                        Container(
                          width: colWidthUmur,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 14.0,
                          ),
                          child: Text(
                            row.umur,
                            style: GoogleFonts.lato(
                              fontSize: 13.5,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ),
                        Container(
                          width: colWidthBb,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 14.0,
                          ),
                          child: Text(
                            row.bb,
                            style: GoogleFonts.lato(
                              fontSize: 13.5,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ),
                        Container(
                          width: colWidthTb,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 14.0,
                          ),
                          child: Text(
                            row.tb,
                            style: GoogleFonts.lato(
                              fontSize: 13.5,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ),
                        Container(
                          width: colWidthHasil,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 12.0,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 5.0,
                            ),
                            decoration: BoxDecoration(
                              color: isGiziNormal
                                  ? const Color(0xFFDDF7F0)
                                  : const Color(0xFFFFECE8),
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: Text(
                              isGiziNormal ? 'Gizi normal' : 'Gizi buruk',
                              style: GoogleFonts.lato(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isGiziNormal
                                    ? const Color(0xFF14B8A6)
                                    : const Color(0xFFF87171),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  static Widget _buildStuntingHeaderCell(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      child: Text(
        text,
        style: GoogleFonts.lato(
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WIDGET TOMBOL UNDUH
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDownloadButton({
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    if (isLoading) {
      return const SizedBox(
        width: 22.0,
        height: 22.0,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          color: _kBluePrimary,
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: _kBorderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4.0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.download_rounded,
              size: 16.0,
              color: _kTextSubtitle,
            ),
            const SizedBox(width: 4.0),
            Text(
              'Unduh',
              style: GoogleFonts.lato(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _kTextSubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendBullet(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10.0,
          height: 10.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6.0),
        Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: _kTextSubtitle,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION BAR (Konsisten 4 Menu)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildNavBar() {
    final navItems = [
      _NavItem(icon: Icons.home_outlined, label: 'Beranda'),
      _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Konsultasi'),
      _NavItem(
        icon: Icons.find_in_page_outlined,
        label: 'Riwayat Konsultasi',
      ),
      _NavItem(icon: Icons.person_outline_rounded, label: 'Profil'),
    ];

    return Container(
      width: double.infinity,
      height: 68.0,
      decoration: const BoxDecoration(
        color: _kNavBarBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(navItems.length, (i) {
            final item = navItems[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => _onNavTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 68.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 24.0, color: Colors.black),
                      const SizedBox(height: 3.0),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 11.0,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (ctx, anim, child) => const BerandaSuperadminPage(),
            transitionsBuilder: (ctx, animation, secondaryAnim, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 200),
          ),
          (route) => false,
        );
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const KonsultasiSuperadminPage(),
          ),
        );
        break;
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const DaftarRiwayatKonsultasiAdminPage(),
          ),
        );
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfilSuperadminPage()),
        );
        break;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // KONDISI LOADING & SKELETON
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          Container(
            height: 120.0,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EDEF),
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 100.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EDEF),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Container(
                  height: 100.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EDEF),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          Container(
            height: 240.0,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EDEF),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: _kBluePrimary,
                strokeWidth: 2.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTER: GRIDLINE HORIZONTAL
// ══════════════════════════════════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  final int lineCount;
  const _GridPainter({required this.lineCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE9EDEF)
      ..strokeWidth = 0.8;

    final axisPaint = Paint()
      ..color = const Color(0xFFD1D7DB)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= lineCount; i++) {
      final y = (size.height / lineCount) * i;
      if (i == lineCount) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), axisPaint);
      } else {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.lineCount != lineCount;
}

// ══════════════════════════════════════════════════════════════════════════════
// KALKULATOR SKALA SUMBU Y
// ══════════════════════════════════════════════════════════════════════════════
class _YAxisScale {
  final int maxVal;
  final int lineCount;
  final List<int> ticks;

  const _YAxisScale({
    required this.maxVal,
    required this.lineCount,
    required this.ticks,
  });

  factory _YAxisScale.calculate(int peak) {
    if (peak <= 100) {
      return const _YAxisScale(
        maxVal: 100,
        lineCount: 10,
        ticks: [100, 90, 80, 70, 60, 50, 40, 30, 20, 10, 0],
      );
    }

    final peakWithMargin = (peak * 1.15).ceil();
    int interval = 20;
    if (peakWithMargin > 200) interval = 50;
    if (peakWithMargin > 500) interval = 100;

    int maxVal = ((peakWithMargin / interval).ceil()) * interval;
    final lineCount = maxVal ~/ interval;

    final ticks = <int>[];
    for (int i = lineCount; i >= 0; i--) {
      ticks.add(i * interval);
    }

    return _YAxisScale(
      maxVal: maxVal,
      lineCount: lineCount,
      ticks: ticks,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MODAL BOTTOM SHEET PILIHAN UNDUH (PDF, CSV, EXCEL)
// ══════════════════════════════════════════════════════════════════════════
class _DownloadBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final void Function(String format) onSelect;

  const _DownloadBottomSheet({
    required this.title,
    required this.subtitle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Container(
              width: 40.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D7DB),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lato(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: _kTextDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.lato(
                        fontSize: 13.0,
                        color: _kTextMuted,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close_rounded,
                    color: _kTextMuted,
                    size: 22.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),
          const Divider(height: 1, color: _kBorderLight),

          // Pilihan PDF
          _buildOption(
            context,
            icon: Icons.picture_as_pdf_rounded,
            iconColor: const Color(0xFFEF4444),
            label: 'Dokumen PDF (.pdf)',
            subtitle: 'Cocok untuk laporan resmi siap cetak',
            format: 'pdf',
          ),

          const Divider(height: 1, thickness: 0.5, color: _kBorderLight),

          // Pilihan CSV
          _buildOption(
            context,
            icon: Icons.table_chart_rounded,
            iconColor: const Color(0xFF0284C7),
            label: 'Berkas CSV (.csv)',
            subtitle: 'Cocok untuk analisis data & spreadsheet',
            format: 'csv',
          ),

          const Divider(height: 1, thickness: 0.5, color: _kBorderLight),

          // Pilihan Excel
          _buildOption(
            context,
            icon: Icons.grid_on_rounded,
            iconColor: const Color(0xFF16A34A),
            label: 'Lembar Kerja Excel (.xlsx)',
            subtitle: 'Format tabel Microsoft Excel',
            format: 'excel',
          ),

          const SizedBox(height: 20.0),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required String format,
  }) {
    return InkWell(
      onTap: () => onSelect(format),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 13.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, color: iconColor, size: 22.0),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.lato(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: _kTextDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.lato(
                      fontSize: 11.5,
                      color: _kTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _kTextMuted,
              size: 20.0,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DATA MODEL ITEM NAVIGASI
// ══════════════════════════════════════════════════════════════════════════
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
