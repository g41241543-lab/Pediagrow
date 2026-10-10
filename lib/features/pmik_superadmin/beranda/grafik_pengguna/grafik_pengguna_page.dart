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
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../../../models/user_model.dart';
import '../beranda_superadmin_page.dart';
import '../../konsultasi/konsultasi_superadmin_page.dart';
import '../../riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import '../../profil/profil_superadmin_page.dart';

// ══════════════════════════════════════════════════════════════════════════════
// WARNA & TOKEN DESAIN (Mengikuti Desain Referensi Super Admin)
// ══════════════════════════════════════════════════════════════════════════════
const Color _kBluePrimary = Color(0xFF2B7AE8);
const Color _kTealPrimary = Color(0xFF3CC3A6);

// Background dan border kartu ringkasan
const Color _kBlueCardBg = Color(0xFFE8F0FE);
const Color _kBlueCardBorder = Color(0xFFCDDBF8);
const Color _kMintCardBg = Color(0xFFE6FAF6);
const Color _kMintCardBorder = Color(0xFFBFECE3);
const Color _kWelcomeMintBg = Color(0xFFDFF7F2);

// Warna elemen & teks
const Color _kBorderColor = Color(0xFFCBD5E1);
const Color _kBorderLight = Color(0xFFE2E8F0);
const Color _kTextDark = Color(0xFF1E293B);
const Color _kTextMuted = Color(0xFF64748B);
const Color _kTextSubtitle = Color(0xFF475569);
const Color _kNavBarBg = Color(0xFFF2EDED);

// Warna jenis kelamin anak
const Color _kBoyBlue = Color(0xFF2B7AE8);
const Color _kBoyAvatarBg = Color(0xFFD6E8FE);
const Color _kGirlPink = Color(0xFFF87171);
const Color _kGirlAvatarBg = Color(0xFFFFDFD9);

/// Halaman Grafik Pengguna untuk Super Admin PediaGrow.
///
/// Fitur Tampilan:
/// 1. SafeArea & Header (tinggi 56dp, tombol back 12dp dari kiri, judul 12dp setelahnya).
/// 2. Card Sambutan hijau mint dengan ilustrasi Super Admin perempuan memegang tablet.
/// 3. Dua Card Ringkasan berdampingan: Total Pengguna (biru muda) & Total Anak (mint).
/// 4. Card Grafik Batang "Jumlah Pengguna & Anak Terdaftar" dengan scroll horizontal,
///    sumbu Y tetap (100 - 0), gridline horizontal, legenda, serta nilai di atas batang.
/// 5. Card Data Anak Berdasarkan Jenis Kelamin dengan avatar ilustrasi dan persentase.
/// 6. Bagian Dataset Pengguna dengan tombol "Unduh" (PDF/Excel + notifikasi "File berhasil disimpan")
///    serta tabel data scroll horizontal.
/// 7. Bottom Navigation Bar konsisten 4 menu (Beranda, Konsultasi, Riwayat Konsultasi, Profil).
class GrafikPenggunaPage extends StatefulWidget {
  const GrafikPenggunaPage({super.key});

  @override
  State<GrafikPenggunaPage> createState() => _GrafikPenggunaPageState();
}

class _GrafikPenggunaPageState extends State<GrafikPenggunaPage> {
  // ── Firestore ──────────────────────────────────────────────────────────────
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── State Data ─────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _errorMessage;

  int _totalPengguna = 0;
  int _totalAnak = 0;
  int _anakLakiLaki = 0;
  int _anakPerempuan = 0;

  // Data jumlah pendaftaran per bulan tahun berjalan (Index 0 = Januari, 11 = Desember)
  final List<int> _penggunaBulan = List.filled(12, 0);
  final List<int> _anakBulan = List.filled(12, 0);

  // Dataset pengguna untuk tabel
  final List<UserModel> _allUsers = [];
  static const int _pageSize = 20;
  int _loadedCount = 0;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  final ScrollController _pageScrollCtrl = ScrollController();

  // ── State Unduh ────────────────────────────────────────────────────────────
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      MediaStore.ensureInitialized();
      MediaStore.appFolder = 'PediaGrow';
    }
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PENGAMBILAN DATA (FIRESTORE USERS & CHILDREN)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadUsers(),
        _loadChildren(),
      ]);
    } catch (e) {
      debugPrint('[GrafikPengguna] Error loadData: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Gagal memuat data pengguna dan anak. Silakan periksa koneksi internet Anda.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Memuat data pengguna dari collection 'users' Firestore.
  /// Menghitung total pengguna, dataset tabel, dan pendaftaran per bulan.
  Future<void> _loadUsers() async {
    final snap = await _firestore.collection('users').get();
    final now = DateTime.now();
    final currentYear = now.year;
    final counts = List.filled(12, 0);

    final users = snap.docs.map((doc) {
      final data = doc.data();
      return UserModel.fromMap({...data, 'id': doc.id});
    }).toList();

    for (final doc in snap.docs) {
      final data = doc.data();
      DateTime? regDate;
      final raw = data['created_at'] ??
          data['createdAt'] ??
          data['registeredAt'] ??
          data['joinedAt'] ??
          data['timestamp'] ??
          data['date_created'];

      if (raw is Timestamp) {
        regDate = raw.toDate();
      } else if (raw is String) {
        regDate = DateTime.tryParse(raw);
      } else if (raw is int) {
        regDate = DateTime.fromMillisecondsSinceEpoch(raw);
      }

      // TODO: Hubungkan ke backend aggregation API jika sistem backend khusus telah tersedia
      if (regDate != null && regDate.year == currentYear) {
        final monthIdx = regDate.month - 1;
        if (monthIdx >= 0 && monthIdx < 12) {
          counts[monthIdx]++;
        }
      }
    }

    if (!mounted) return;
    _allUsers
      ..clear()
      ..addAll(users);

    _totalPengguna = users.length;
    _loadedCount = math.min(_pageSize, users.length);
    _hasMore = users.length > _pageSize;

    for (int i = 0; i < 12; i++) {
      _penggunaBulan[i] = counts[i];
    }
  }

  /// Memuat data anak dari collection 'children' Firestore.
  /// Menghitung total anak, perbandingan jenis kelamin, dan pendaftaran per bulan.
  Future<void> _loadChildren() async {
    final snap = await _firestore.collection('children').get();
    final now = DateTime.now();
    final currentYear = now.year;
    final counts = List.filled(12, 0);
    int laki = 0, perempuan = 0, total = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      final bool deleted = data['deleted'] == true || data['isDeleted'] == true;
      if (deleted) continue;

      total++;

      final rawGender = (data['gender'] ?? data['jenis_kelamin'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final isLaki = rawGender == 'L' ||
          rawGender == 'LAKI-LAKI' ||
          rawGender == 'LAKI';
      if (isLaki) {
        laki++;
      } else {
        perempuan++;
      }

      DateTime? regDate;
      final raw = data['created_at'] ??
          data['createdAt'] ??
          data['registeredAt'] ??
          data['timestamp'] ??
          data['date_created'];
      if (raw is Timestamp) {
        regDate = raw.toDate();
      } else if (raw is String) {
        regDate = DateTime.tryParse(raw);
      } else if (raw is int) {
        regDate = DateTime.fromMillisecondsSinceEpoch(raw);
      } else if (data['birth_date'] != null) {
        final bDate = DateTime.tryParse(data['birth_date'].toString());
        if (bDate != null && bDate.year == currentYear) {
          regDate = bDate;
        }
      }

      // TODO: Hubungkan ke API pelaporan bulanan bila data anak diarsipkan per periode
      if (regDate != null && regDate.year == currentYear) {
        final monthIdx = regDate.month - 1;
        if (monthIdx >= 0 && monthIdx < 12) {
          counts[monthIdx]++;
        }
      }
    }

    if (!mounted) return;
    _totalAnak = total;
    _anakLakiLaki = laki;
    _anakPerempuan = perempuan;

    for (int i = 0; i < 12; i++) {
      _anakBulan[i] = counts[i];
    }
  }

  void _loadMoreUsers() {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    final next = math.min(_loadedCount + _pageSize, _allUsers.length);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _loadedCount = next;
        _hasMore = next < _allUsers.length;
        _isLoadingMore = false;
      });
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FORMAT ANGKA & TEKS
  // ══════════════════════════════════════════════════════════════════════════
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

  /// Memecah nama menjadi Nama Depan dan Nama Belakang sesuai tampilan desain referensi
  String _firstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '-';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length <= 1) return parts.first;
    return parts.sublist(0, parts.length - 1).join(' ');
  }

  String _lastName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '-';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length <= 1) return '-';
    return parts.last;
  }

  String _formatGender(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Perempuan';
    final g = raw.trim().toUpperCase();
    if (g == 'L' || g == 'LAKI-LAKI' || g == 'LAKI') return 'Laki-laki';
    if (g == 'P' || g == 'PEREMPUAN') return 'Perempuan';
    return raw;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FITUR UNDUH DATASET (PDF & EXCEL + NOTIFIKASI SUKSES)
  // ══════════════════════════════════════════════════════════════════════════
  void _showDownloadSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DownloadBottomSheet(
        onSelect: (format) {
          Navigator.of(context).pop();
          if (format == 'pdf') {
            _downloadPdf();
          } else {
            _downloadExcel();
          }
        },
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      if (!await _ensureStoragePermission()) return;

      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      final pdf = pw.Document();
      const cols = ['Nama Depan', 'Nama Belakang', 'Jenis Kelamin', 'Email'];
      final users = List<UserModel>.from(_allUsers);
      const rowsPerPage = 28;
      final totalPages = (users.length / rowsPerPage).ceil().clamp(1, 9999);

      for (int pageIdx = 0; pageIdx < totalPages; pageIdx++) {
        final start = pageIdx * rowsPerPage;
        final end = math.min(start + rowsPerPage, users.length);
        final pageUsers = users.sublist(start, end);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (pageIdx == 0) ...[
                  pw.Text('Dataset Pengguna PediaGrow',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Dibuat: ${now.day}/${now.month}/${now.year}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 14),
                ],
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(3),
                  },
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: cols
                          .map(
                            (c) => pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              child: pw.Text(c,
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold)),
                            ),
                          )
                          .toList(),
                    ),
                    for (final u in pageUsers)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: pw.Text(_firstName(u.name),
                                style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: pw.Text(_lastName(u.name),
                                style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: pw.Text(_formatGender(u.gender),
                                style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: pw.Text(u.email,
                                style: const pw.TextStyle(fontSize: 9)),
                          ),
                        ],
                      ),
                  ],
                ),
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Halaman ${pageIdx + 1} / $totalPages',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final bytes = await pdf.save();
      final fileName = 'dataset_pengguna_$dateStr.pdf';
      final filePath = await _saveToDownloads(
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
        mimeType: 'application/pdf',
      );

      if (!mounted) return;
      setState(() => _isDownloading = false);
      _showSuccessSnackbar(filePath, fileName, mimeType: 'application/pdf');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      _showSnackbar('Gagal mengunduh file, coba lagi');
    }
  }

  Future<void> _downloadExcel() async {
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

      sheet.getRangeByIndex(1, 1).setText('Nama Depan');
      sheet.getRangeByIndex(1, 2).setText('Nama Belakang');
      sheet.getRangeByIndex(1, 3).setText('Jenis Kelamin');
      sheet.getRangeByIndex(1, 4).setText('Email');
      sheet.getRangeByIndex(1, 5).setText('No. Telepon');
      sheet.getRangeByIndex(1, 1, 1, 5).cellStyle.bold = true;

      final users = List<UserModel>.from(_allUsers);
      for (int i = 0; i < users.length; i++) {
        final u = users[i];
        sheet.getRangeByIndex(i + 2, 1).setText(_firstName(u.name));
        sheet.getRangeByIndex(i + 2, 2).setText(_lastName(u.name));
        sheet.getRangeByIndex(i + 2, 3).setText(_formatGender(u.gender));
        sheet.getRangeByIndex(i + 2, 4).setText(u.email);
        sheet.getRangeByIndex(i + 2, 5).setText(u.phone ?? '-');
      }

      sheet.autoFitColumn(1);
      sheet.autoFitColumn(2);
      sheet.autoFitColumn(3);
      sheet.autoFitColumn(4);
      sheet.autoFitColumn(5);

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
      _showSnackbar('Gagal mengunduh file, coba lagi');
    }
  }

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
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Menampilkan notifikasi persis seperti pada Gambar 2 desain referensi:
  /// Bar hitam floating bertuliskan "File berhasil disimpan" dan tombol aksi "Buka".
  void _showSuccessSnackbar(String? filePath, String fileName,
      {String? mimeType}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF1E293B),
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
            // ── HEADER FIXED (56dp dari atas layar) ──────────────────────
            _buildHeader(),

            // ── KONTEN UTAMA VERTICAL SCROLLING ──────────────────────────
            Expanded(
              child: _isLoading
                  ? _buildLoadingSkeleton()
                  : _errorMessage != null
                      ? _buildErrorView()
                      : SingleChildScrollView(
                          controller: _pageScrollCtrl,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              // 1. Card Sambutan Hijau Mint
                              _buildWelcomeCard(),
                              const SizedBox(height: 16),

                              // 2. Card Ringkasan Total Pengguna & Anak
                              _buildTotalCards(),
                              const SizedBox(height: 24),

                              // 3. Card Grafik Batang
                              _buildGrafikSection(),
                              const SizedBox(height: 16),

                              // 4. Card Data Anak Berdasarkan Jenis Kelamin
                              _buildGenderSection(),
                              const SizedBox(height: 24),

                              // 5. Dataset Pengguna (Tabel & Unduh)
                              _buildDatasetSection(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 1. HEADER (Tinggi 56dp, Back 12dp dari kiri, Judul 12dp setelahnya)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 56.0,
      color: Colors.white,
      padding: const EdgeInsets.only(left: 12.0, right: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Kembali berjarak 12dp dari tepi kiri layar
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const Icon(
              Icons.arrow_back,
              color: _kTextDark,
              size: 24.0,
            ),
          ),
          // Jarak 12dp antara tombol kembali dan judul
          const SizedBox(width: 12.0),
          // Judul "Grafik Pengguna" sejajar secara vertikal
          Expanded(
            child: Text(
              'Grafik Pengguna',
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
  // 2. CARD SAMBUTAN HIJAU MINT DENGAN ILUSTRASI SUPER ADMIN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWelcomeCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        width: double.infinity,
        height: 124.0,
        decoration: BoxDecoration(
          color: _kWelcomeMintBg,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Teks Sapaan di sisi kiri
            Padding(
              padding: const EdgeInsets.only(
                left: 18.0,
                top: 16.0,
                bottom: 16.0,
                right: 120.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Selamat datang,',
                    style: GoogleFonts.lato(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: _kTextDark,
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    'Super Admin',
                    style: GoogleFonts.lato(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: _kTextDark,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Kelola data pengguna dan anak secara keseluruhan',
                    style: GoogleFonts.lato(
                      fontSize: 11.5,
                      fontWeight: FontWeight.normal,
                      color: _kTextMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            // Ilustrasi Super Admin perempuan memegang tablet di sisi kanan
            Positioned(
              right: 8.0,
              bottom: 0.0,
              child: SizedBox(
                width: 110.0,
                height: 124.0,
                child: Image.asset(
                  'assets/images/admin_woman_tablet.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 64.0,
                    color: _kBluePrimary,
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
  // 3. CARD RINGKASAN TOTAL PENGGUNA & ANAK (Berdampingan Sesuai Desain)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTotalCards() {
    return Row(
      children: [
        // Total Pengguna (Nuansa Biru Muda)
        Expanded(
          child: _buildSummaryCard(
            label: 'Total Pengguna',
            value: _totalPengguna,
            unit: 'Pengguna',
            bgColor: _kBlueCardBg,
            borderColor: _kBlueCardBorder,
          ),
        ),
        const SizedBox(width: 12.0),
        // Total Anak Terdaftar (Nuansa Hijau Muda/Mint)
        Expanded(
          child: _buildSummaryCard(
            label: 'Total Anak Terdaftar',
            value: _totalAnak,
            unit: 'Anak',
            bgColor: _kMintCardBg,
            borderColor: _kMintCardBorder,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required int value,
    required String unit,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      height: 112.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: _kTextSubtitle,
            ),
          ),
          Text(
            _formatNumber(value),
            style: GoogleFonts.lato(
              fontSize: 26.0,
              fontWeight: FontWeight.bold,
              color: _kTextDark,
              height: 1.1,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.lato(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: _kTextSubtitle,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 4. SEKSI GRAFIK BATANG (Jumlah Pengguna & Anak Terdaftar)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGrafikSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Pengguna & Anak',
          style: GoogleFonts.lato(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: _kTextDark,
          ),
        ),
        const SizedBox(height: 12.0),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: _kBorderLight, width: 1.0),
          ),
          padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jumlah Pengguna & Anak Terdaftar',
                style: GoogleFonts.lato(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 12.0),

              // Legenda: Pengguna (Biru Muda/Biru) dan Anak (Toska/Hijau)
              Row(
                children: [
                  _buildLegendPill(
                    color: const Color(0xFFDCEBFE),
                    label: 'Pengguna',
                  ),
                  const SizedBox(width: 20.0),
                  _buildLegendPill(
                    color: const Color(0xFF52C4B1),
                    label: 'Anak',
                  ),
                ],
              ),
              const SizedBox(height: 18.0),

              // Area Diagram Batang dengan Sumbu Y Fixed & Plot Scroll Horizontal
              SizedBox(
                height: 280.0,
                child: _buildBarChartArea(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendPill({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18.0,
          height: 14.0,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
        const SizedBox(width: 8.0),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: _kTextDark,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChartArea() {
    const bulanNames = [
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

    // Mengambil nilai puncak data untuk menentukan skala sumbu Y
    int peakData = 0;
    for (int i = 0; i < 12; i++) {
      if (_penggunaBulan[i] > peakData) peakData = _penggunaBulan[i];
      if (_anakBulan[i] > peakData) peakData = _anakBulan[i];
    }

    final scale = _YAxisScale.calculate(peakData);

    const chartPlotHeight = 220.0;
    const topPadding = 22.0;
    const xLabelHeight = 28.0;
    const barWidth = 14.0;
    const barGap = 4.0;
    const groupGap = 32.0;
    const yAxisWidth = 30.0;

    const monthCount = 12;
    final plotWidth = monthCount * (barWidth * 2 + barGap + groupGap) + 16.0;
    const totalHeight = topPadding + chartPlotHeight + xLabelHeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── SUMBU Y TETAP DI KIRI (100 - 0) ──────────────────────────
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
                    fontSize: 10.0,
                    fontWeight: FontWeight.w500,
                    color: _kTextMuted,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8.0),

        // ── AREA BATANG HORIZONTAL SCROLLING ─────────────────────────
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: math.max(plotWidth, 320.0),
              height: totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Garis Bantu Horizontal (Gridline)
                  Positioned(
                    top: topPadding,
                    left: 0,
                    right: 0,
                    height: chartPlotHeight,
                    child: CustomPaint(
                      size: Size(math.max(plotWidth, 320.0), chartPlotHeight),
                      painter: _GridPainter(
                        lineCount: scale.lineCount,
                      ),
                    ),
                  ),

                  // Pasangan Batang Per Bulan + Label Nilai + Label Bulan
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
                            left: i == 0 ? 12.0 : 0.0,
                            right: i < monthCount - 1 ? groupGap : 16.0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: chartPlotHeight,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Batang Pengguna (Biru)
                                    _buildBar(
                                      height: penggunaH,
                                      color: _kBluePrimary,
                                      value: valPengguna,
                                      width: barWidth,
                                    ),
                                    const SizedBox(width: barGap),
                                    // Batang Anak (Toska)
                                    _buildBar(
                                      height: anakH,
                                      color: _kTealPrimary,
                                      value: valAnak,
                                      width: barWidth,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              // Nama Bulan di Bawah Batang
                              Text(
                                bulanNames[i],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: _kTextDark,
                                ),
                              ),
                              const SizedBox(height: 4.0),
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

  Widget _buildBar({
    required double height,
    required Color color,
    required int value,
    required double width,
  }) {
    if (value <= 0) {
      return SizedBox(width: width);
    }

    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 3.0),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 9.0,
                fontWeight: FontWeight.bold,
                color: _kTextDark,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            width: width,
            height: math.max(height, 4.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(3.0)),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 5. CARD DATA ANAK BERDASARKAN JENIS KELAMIN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGenderSection() {
    final total = _anakLakiLaki + _anakPerempuan;
    final displayTotal = total > 0 ? total : (_totalAnak > 0 ? _totalAnak : 0);
    final displayLaki = _anakLakiLaki;
    final displayPr = _anakPerempuan;
    final lakiPct = displayTotal > 0 ? (displayLaki / displayTotal * 100) : 0.0;
    final prPct = displayTotal > 0 ? (displayPr / displayTotal * 100) : 0.0;

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
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              // Kolom Laki-laki
              Expanded(
                child: _buildGenderItem(
                  isBoy: true,
                  label: 'Laki-laki',
                  count: displayLaki,
                  pct: lakiPct,
                  accentColor: _kBoyBlue,
                  bgColor: _kBoyAvatarBg,
                ),
              ),
              const SizedBox(width: 8.0),
              // Kolom Perempuan
              Expanded(
                child: _buildGenderItem(
                  isBoy: false,
                  label: 'Perempuan',
                  count: displayPr,
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

  Widget _buildGenderItem({
    required bool isBoy,
    required String label,
    required int count,
    required double pct,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar Ilustrasi Wajah Anak
        Container(
          width: 44.0,
          height: 44.0,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: CustomPaint(
            painter: isBoy ? _BoyAvatarPainter() : _GirlAvatarPainter(),
          ),
        ),
        const SizedBox(width: 10.0),

        // Info Jumlah & Persentase
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 13.0,
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
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 6. DATASET PENGGUNA (Tabel Horizontal Scroll & Tombol Unduh)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDatasetSection() {
    final visible = _allUsers.take(_loadedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris Judul & Tombol Unduh Pill
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
            _isDownloading
                ? const SizedBox(
                    width: 22.0,
                    height: 22.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: _kBluePrimary,
                    ),
                  )
                : InkWell(
                    onTap: _showDownloadSheet,
                    borderRadius: BorderRadius.circular(20.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: _kBorderColor, width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.download_rounded,
                            size: 15.0,
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
                  ),
          ],
        ),
        const SizedBox(height: 12.0),

        // Tabel Dataset Pengguna yang Dapat Digeser Horizontal
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
              child: _buildTable(visible),
            ),
          ),
        ),

        // Indikator lazy load atau tombol muat data lebih
        if (_hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Center(
              child: _isLoadingMore
                  ? const SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: _kBluePrimary,
                      ),
                    )
                  : TextButton(
                      onPressed: _loadMoreUsers,
                      child: Text(
                        'Muat lebih banyak data',
                        style: GoogleFonts.lato(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _kBluePrimary,
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildTable(List<UserModel> users) {
    const colWidths = [140.0, 140.0, 130.0, 200.0, 140.0];
    const headers = [
      'Nama Depan',
      'Nama Belakang',
      'Jenis Kelamin',
      'Email',
      'No. Telepon'
    ];

    if (users.isEmpty) {
      return Container(
        width: 380.0,
        padding: const EdgeInsets.symmetric(vertical: 36.0),
        alignment: Alignment.center,
        child: Text(
          'Belum ada dataset pengguna terdaftar',
          style: GoogleFonts.lato(
            fontSize: 13.0,
            color: _kTextMuted,
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: colWidths.reduce((a, b) => a + b),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Header
          Container(
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: List.generate(headers.length, (i) {
                return Container(
                  width: colWidths[i],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                  child: Text(
                    headers[i],
                    style: GoogleFonts.lato(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: _kTextDark,
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kBorderLight),

          // Baris Data Pengguna
          ...List.generate(users.length, (idx) {
            final u = users[idx];
            final isLast = idx == users.length - 1;
            final cells = [
              _firstName(u.name),
              _lastName(u.name),
              _formatGender(u.gender),
              u.email,
              u.phone ?? '-',
            ];

            return Column(
              children: [
                Row(
                  children: List.generate(cells.length, (ci) {
                    return Container(
                      width: colWidths[ci],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 12.0,
                      ),
                      child: Text(
                        cells[ci],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 12.0,
                          color: const Color(0xFF334155),
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
  // 7. BOTTOM NAVIGATION BAR (Konsisten 4 Menu Super Admin)
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
  // KONDISI LOADING & ERROR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          Container(
            height: 124.0,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 112.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Container(
                  height: 112.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          Container(
            height: 260.0,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48.0,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 12.0),
            Text(
              _errorMessage ?? 'Terjadi kesalahan memuat data',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 14.0,
                color: _kTextDark,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBluePrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
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
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.8;

    final axisPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
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
// ══════════════════════════════════════════════════════════════════════════
class _YAxisScale {
  final int maxVal;
  final int lineCount;
  final List<int> ticks; // Dari maxVal ke 0

  const _YAxisScale({
    required this.maxVal,
    required this.lineCount,
    required this.ticks,
  });

  /// Mengikuti skala pada gambar desain: default 100 dengan step 10
  /// [100, 90, 80, 70, 60, 50, 40, 30, 20, 10, 0].
  /// Jika data puncak melebihi 100, skala membesar secara proporsional.
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
// CUSTOM PAINTER: AVATAR WAJAH ANAK LAKI-LAKI & PEREMPUAN
// Menggambar ilustrasi wajah anak yang lucu dan jernih persis seperti desain referensi
// ══════════════════════════════════════════════════════════════════════════
class _BoyAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.34;

    final linePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final eyePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    // Lingkaran Kepala
    canvas.drawCircle(center, radius, linePaint);

    // Telinga Kiri & Kanan
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(center.dx - radius, center.dy), radius: 3.5),
      -math.pi / 2,
      math.pi,
      false,
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(center.dx + radius, center.dy), radius: 3.5),
      math.pi / 2,
      math.pi,
      false,
      linePaint,
    );

    // Rambut Poni Anak Laki-laki
    final hairPath = Path();
    hairPath.moveTo(center.dx - radius * 0.85, center.dy - radius * 0.3);
    hairPath.quadraticBezierTo(
      center.dx - radius * 0.4,
      center.dy - radius * 0.85,
      center.dx,
      center.dy - radius * 0.35,
    );
    hairPath.quadraticBezierTo(
      center.dx + radius * 0.4,
      center.dy - radius * 0.85,
      center.dx + radius * 0.85,
      center.dy - radius * 0.3,
    );
    canvas.drawPath(hairPath, linePaint);

    // Mata (Dua Titik)
    canvas.drawCircle(
      Offset(center.dx - radius * 0.35, center.dy - radius * 0.05),
      1.5,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.35, center.dy - radius * 0.05),
      1.5,
      eyePaint,
    );

    // Senyum Lengkung
    final smilePath = Path();
    smilePath.moveTo(center.dx - radius * 0.3, center.dy + radius * 0.35);
    smilePath.quadraticBezierTo(
      center.dx,
      center.dy + radius * 0.65,
      center.dx + radius * 0.3,
      center.dy + radius * 0.35,
    );
    canvas.drawPath(smilePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GirlAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.34;

    final linePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final eyePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    // Lingkaran Kepala
    canvas.drawCircle(center, radius, linePaint);

    // Kuncir Rambut Kiri & Kanan (Pigtails)
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(center.dx - radius * 0.95, center.dy - radius * 0.35),
          radius: 4.5),
      0,
      2 * math.pi,
      false,
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(center.dx + radius * 0.95, center.dy - radius * 0.35),
          radius: 4.5),
      0,
      2 * math.pi,
      false,
      linePaint,
    );

    // Rambut Poni Anak Perempuan
    final hairPath = Path();
    hairPath.moveTo(center.dx - radius * 0.8, center.dy - radius * 0.2);
    hairPath.quadraticBezierTo(
      center.dx,
      center.dy - radius * 0.6,
      center.dx + radius * 0.8,
      center.dy - radius * 0.2,
    );
    canvas.drawPath(hairPath, linePaint);

    // Mata (Dua Titik)
    canvas.drawCircle(
      Offset(center.dx - radius * 0.35, center.dy - radius * 0.05),
      1.5,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.35, center.dy - radius * 0.05),
      1.5,
      eyePaint,
    );

    // Senyum Lengkung
    final smilePath = Path();
    smilePath.moveTo(center.dx - radius * 0.3, center.dy + radius * 0.35);
    smilePath.quadraticBezierTo(
      center.dx,
      center.dy + radius * 0.65,
      center.dx + radius * 0.3,
      center.dy + radius * 0.35,
    );
    canvas.drawPath(smilePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// MODAL BOTTOM SHEET PILIHAN FORMAT UNDUH
// ══════════════════════════════════════════════════════════════════════════
class _DownloadBottomSheet extends StatelessWidget {
  final void Function(String format) onSelect;
  const _DownloadBottomSheet({required this.onSelect});

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
          // Handle Bar
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Container(
              width: 40.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unduh Dataset',
                      style: GoogleFonts.lato(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: _kTextDark,
                      ),
                    ),
                    Text(
                      'Pilih format file dokumen',
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
            label: 'PDF (.pdf)',
            format: 'pdf',
          ),

          const Divider(height: 1, thickness: 0.5, color: _kBorderLight),

          // Pilihan Excel
          _buildOption(
            context,
            icon: Icons.grid_on_rounded,
            iconColor: const Color(0xFF16A34A),
            label: 'Excel (.xlsx)',
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
    required String format,
  }) {
    return InkWell(
      onTap: () => onSelect(format),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24.0),
            const SizedBox(width: 14.0),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 14.0,
                  color: _kTextDark,
                ),
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
