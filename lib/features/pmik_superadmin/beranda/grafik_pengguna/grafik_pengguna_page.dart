import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
// WARNA KONSTANTA
// ══════════════════════════════════════════════════════════════════════════════
const _kBluePrimary = Color(0xFF2B7AE8);
const _kTealPrimary = Color(0xFF3CC3A6);
const _kBlueLight = Color(0xFFEFF6FF);
const _kTealLight = Color(0xFFE6FAF7);
const _kBorderColor = Color(0xFFC5C5C5);
const _kTextDark = Color(0xFF1E293B);
const _kTextGrey = Color(0xFF7F7F7F);
const _kPink = Color(0xFFEC4899);

/// Halaman Grafik Pengguna untuk Superadmin PediaGrow.
///
/// Menampilkan:
/// - Kartu sambutan hijau mint dengan ilustrasi
/// - Ringkasan total pengguna & anak terdaftar
/// - Grafik batang berkelompok (pengguna & anak per bulan)
/// - Data jenis kelamin anak
/// - Dataset pengguna dengan lazy loading + unduh PDF/Excel
class GrafikPenggunaPage extends StatefulWidget {
  const GrafikPenggunaPage({super.key});

  @override
  State<GrafikPenggunaPage> createState() => _GrafikPenggunaPageState();
}

class _GrafikPenggunaPageState extends State<GrafikPenggunaPage> {
  // ── Firestore ──────────────────────────────────────────────────────────────
  final _firestore = FirebaseFirestore.instance;

  // ── State Data ─────────────────────────────────────────────────────────────
  bool _isLoading = true;
  int _totalPengguna = 0;
  int _totalAnak = 0;
  int _anakLakiLaki = 0;
  int _anakPerempuan = 0;

  // Data per bulan (index 0 = Jan, 11 = Des)
  final List<int> _penggunaBulan = List.filled(12, 0);
  final List<int> _anakBulan = List.filled(12, 0);

  // Dataset pengguna untuk tabel (lazy)
  final List<UserModel> _allUsers = [];
  static const int _pageSize = 20;
  int _loadedCount = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _tableScrollCtrl = ScrollController();

  // ── Download state ─────────────────────────────────────────────────────────
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi MediaStore sekali di awal (diperlukan sebelum saveFile)
    if (Platform.isAndroid) {
      MediaStore.ensureInitialized();
      MediaStore.appFolder = 'PediaGrow';
    }
    _loadData();
    _tableScrollCtrl.addListener(_onTableScroll);
  }

  @override
  void dispose() {
    _tableScrollCtrl.removeListener(_onTableScroll);
    _tableScrollCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOAD DATA
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadUsers(),
        _loadChildren(),
      ]);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

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

      // Filter hanya untuk tahun berjalan dan bulan pendaftaran akun
      if (regDate != null && regDate.year == currentYear) {
        final monthIdx = regDate.month - 1; // 0 = Jan, 11 = Des
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

  Future<void> _loadChildren() async {
    final snap = await _firestore.collection('children').get();
    final now = DateTime.now();
    final currentYear = now.year;
    final counts = List.filled(12, 0);
    int laki = 0, perempuan = 0, total = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      final rawGender = (data['gender'] ?? data['jenis_kelamin'] ?? '').toString().trim().toUpperCase();
      final isLaki = rawGender == 'L' || rawGender == 'LAKI-LAKI';

      final bool deleted = data['deleted'] == true || data['isDeleted'] == true;
      if (deleted) continue;

      total++;
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

      // Filter hanya untuk tahun berjalan dan bulan pendaftaran profil anak
      if (regDate != null && regDate.year == currentYear) {
        final monthIdx = regDate.month - 1; // 0 = Jan, 11 = Des
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

  // ── Lazy loading tabel ─────────────────────────────────────────────────────
  void _onTableScroll() {
    if (_tableScrollCtrl.position.pixels >=
            _tableScrollCtrl.position.maxScrollExtent - 80 &&
        _hasMore &&
        !_isLoadingMore) {
      _loadMoreUsers();
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
  // FORMAT ANGKA DENGAN PEMISAH TITIK
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

  // ══════════════════════════════════════════════════════════════════════════
  // DOWNLOAD
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
      // API ≤28: minta izin runtime; API ≥29: tidak perlu
      if (!await _ensureStoragePermission()) return;

      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      // Build PDF
      final pdf = pw.Document();
      const cols = ['Nama Depan', 'Nama Belakang', 'Email'];

      final users = List<UserModel>.from(_allUsers);
      const rowsPerPage = 30;
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
                  pw.Text('Dataset Pengguna',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Dibuat: ${now.day}/${now.month}/${now.year}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.SizedBox(height: 16),
                ],
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(3),
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
      sheet.getRangeByIndex(1, 3).setText('Email');
      sheet.getRangeByIndex(1, 1, 1, 3).cellStyle.bold = true;

      final users = List<UserModel>.from(_allUsers);
      for (int i = 0; i < users.length; i++) {
        final u = users[i];
        sheet.getRangeByIndex(i + 2, 1).setText(_firstName(u.name));
        sheet.getRangeByIndex(i + 2, 2).setText(_lastName(u.name));
        sheet.getRangeByIndex(i + 2, 3).setText(u.email);
      }

      sheet.autoFitColumn(1);
      sheet.autoFitColumn(2);
      sheet.autoFitColumn(3);

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
      _showSuccessSnackbar(filePath, fileName,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      _showSnackbar('Gagal mengunduh file, coba lagi');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _firstName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.first;
  }

  String _lastName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  /// Memeriksa dan meminta izin penyimpanan HANYA pada Android API ≤ 28.
  /// Android 10 (API 29) ke atas menggunakan MediaStore dan TIDAK memerlukan izin penyimpanan sama sekali.
  /// Mengembalikan [true] jika proses unduh boleh dilanjutkan.
  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      // Android 10 (API 29) ke atas: MediaStore digunakan langsung tanpa meminta izin penyimpanan apapun.
      if (androidInfo.version.sdkInt >= 29) {
        return true;
      }
    } catch (e) {
      debugPrint('Error reading Android SDK version: $e');
      // Jika terjadi kendala membaca info OS, jangan blokir proses unduh
      return true;
    }

    // Hanya untuk Android 9 (API 28) ke bawah:
    final status = await Permission.storage.status;
    if (status.isGranted) return true;

    final result = await Permission.storage.request();
    if (result.isGranted) return true;

    if (!mounted) return false;
    _showSnackbar('Izin penyimpanan diperlukan untuk mengunduh file');
    setState(() => _isDownloading = false);
    return false;
  }

  /// Menyimpan file ke folder Downloads publik menggunakan MediaStore (API ≥ 29)
  /// serta menyimpan salinan lokal agar tombol "Buka" dapat membuka file via [OpenFilex].
  Future<String?> _saveToDownloads({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    // 1. Simpan ke Documents lokal agar selalu dapat diakses oleh FileProvider OpenFilex
    final docsDir = await getApplicationDocumentsDirectory();
    final localFile = File('${docsDir.path}/$fileName');
    await localFile.writeAsBytes(bytes, flush: true);

    // 2. Simpan juga ke folder Downloads publik via MediaStore di Android
    if (Platform.isAndroid) {
      try {
        final mediaStore = MediaStore();
        await mediaStore.saveFile(
          tempFilePath: localFile.path,
          dirType: DirType.download,
          dirName: DirName.download,
        );
      } catch (e) {
        debugPrint('MediaStore saveFile error: $e');
      }
    }

    // Mengembalikan path file lokal yang dapat dibuka oleh OpenFilex
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

  /// Snackbar sukses unduh. Menampilkan tombol aksi "Buka" yang membuka file.
  void _showSuccessSnackbar(String? filePath, String fileName, {String? mimeType}) {
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
                style: GoogleFonts.lato(color: Colors.white),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Buka',
                    style: GoogleFonts.lato(
                      color: const Color(0xFF38BDF8),
                      fontWeight: FontWeight.bold,
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
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── HEADER FIXED ────────────────────────────────────────────
            _buildHeader(),

            // ── KONTEN SCROLLABLE ────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kBluePrimary))
                  : SingleChildScrollView(
                      controller: _tableScrollCtrl,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildWelcomeCard(),
                          const SizedBox(height: 16),
                          _buildTotalCards(),
                          const SizedBox(height: 24),
                          _buildGrafikSection(),
                          const SizedBox(height: 16),
                          _buildGenderSection(),
                          const SizedBox(height: 24),
                          _buildDatasetSection(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.only(left: 12, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.arrow_back, color: _kTextDark, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Grafik Pengguna',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 20,
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
  // KARTU SAMBUTAN HIJAU MINT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWelcomeCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFDFF7F2), // Hijau mint muda sesuai desain Figma
          borderRadius: BorderRadius.circular(17),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Teks di sisi kiri rata kiri dan tersusun vertikal berurutan
            Padding(
              padding: const EdgeInsets.only(
                left: 18.0,
                top: 16.0,
                bottom: 16.0,
                right: 115.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Selamat datang,',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2EA98D),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Super Admin',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola data pengguna dan anak secara keseluruhan',
                    style: GoogleFonts.lato(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7F7F7F),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            // Ilustrasi perempuan memegang tablet di sisi kanan (tidak keluar batas kartu)
            Positioned(
              right: 0,
              bottom: 0,
              child: SizedBox(
                width: 105,
                height: 120,
                child: Image.asset(
                  'assets/images/admin_woman_tablet.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.medical_services_rounded,
                    size: 60,
                    color: Color(0xFF3985E7),
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
  // KARTU TOTAL (dua berdampingan - background mint/teal sangat muda sesuai Figma)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTotalCards() {
    const mintBg = Color(0xFFDFF7F2); // Mint/teal sangat muda sama seperti kartu sambutan

    return Row(
      children: [
        // Total Pengguna (angka biru aksen)
        Expanded(
          child: _buildTotalCard(
            label: 'Total Pengguna',
            value: _totalPengguna,
            satuan: 'Pengguna',
            bgColor: mintBg,
            valueColor: _kBluePrimary,
          ),
        ),
        const SizedBox(width: 12),
        // Total Anak (angka teal aksen)
        Expanded(
          child: _buildTotalCard(
            label: 'Total Anak Terdaftar',
            value: _totalAnak,
            satuan: 'Anak',
            bgColor: mintBg,
            valueColor: _kTealPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard({
    required String label,
    required int value,
    required String satuan,
    required Color bgColor,
    required Color valueColor,
  }) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor, // Mint/teal sangat muda (#DFF7F2)
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label atas: font weight bold
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF7F7F7F),
            ),
          ),
          // Angka besar: font weight bold
          Text(
            _formatNumber(value),
            style: GoogleFonts.lato(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: valueColor,
              height: 1.1,
            ),
          ),
          // Label satuan: font weight bold
          Text(
            satuan,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF7F7F7F),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SEKSI GRAFIK BATANG
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGrafikSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Pengguna & Anak',
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _kTextDark,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _kBorderColor, width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jumlah Pengguna & Anak Terdaftar',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 10),
              // Legend dua warna: Pengguna (biru) dan Anak (teal) dengan kotak legend
              Row(
                children: [
                  _buildLegendBox(_kBluePrimary, 'Pengguna'),
                  const SizedBox(width: 16),
                  _buildLegendBox(_kTealPrimary, 'Anak'),
                ],
              ),
              const SizedBox(height: 16),
              // Container dengan tinggi eksplisit minimal 220dp (di sini 270dp)
              SizedBox(
                height: 270,
                child: _buildBarChart(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendBox(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final now = DateTime.now();
    const bulanNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    // Bulan yang ditampilkan mulai Januari tahun berjalan sampai bulan berjalan (minimal 6 bulan)
    final monthCount = math.max(now.month, 6).clamp(1, 12);

    int peakData = 0;
    for (int i = 0; i < monthCount; i++) {
      if (_penggunaBulan[i] > peakData) peakData = _penggunaBulan[i];
      if (_anakBulan[i] > peakData) peakData = _anakBulan[i];
    }

    final scale = _YAxisScale.calculate(peakData);

    // chartPlotHeight: area bersih untuk batang (tidak termasuk label angka di atas)
    // topPadding    : ruang di atas area batang agar label angka tidak terpotong
    // xLabelHeight  : tinggi label bulan (teks) + gap di bawah batang
    const chartPlotHeight = 220.0;
    const topPadding      = 24.0;  // ruang untuk label nilai di atas batang tertinggi
    const xLabelHeight    = 28.0;  // tinggi area label bulan (teks + gap)
    const barWidth  = 14.0;
    const barGap    = 4.0;
    const groupGap  = 20.0;
    const yAxisWidth = 32.0;

    final plotWidth = monthCount * (barWidth * 2 + barGap + groupGap) + 20.0;
    // Total tinggi widget grafik = padding atas + area batang + area label X
    const totalHeight = topPadding + chartPlotHeight + xLabelHeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sumbu Y tetap di kiri — mulai dari bawah topPadding agar sejajar dengan area batang
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
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Area Diagram Batang (Scrollable horizontal jika tidak muat)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: math.max(plotWidth, 260),
              height: totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Garis bantu horizontal — dimulai dari topPadding ke bawah
                  Positioned(
                    top: topPadding,
                    left: 0,
                    right: 0,
                    height: chartPlotHeight,
                    child: CustomPaint(
                      size: Size(math.max(plotWidth, 260), chartPlotHeight),
                      painter: _GridPainter(
                        yMax: scale.maxVal,
                        lineCount: scale.lineCount,
                      ),
                    ),
                  ),

                  // Batang + label angka + label bulan
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
                        // Tinggi batang dihitung dalam area chartPlotHeight saja
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
                            left: i == 0 ? 8 : 0,
                            right: i < monthCount - 1 ? groupGap : 8,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Area batang — tinggi = chartPlotHeight
                              // topPadding di atas sudah memberi ruang label angka
                              SizedBox(
                                height: chartPlotHeight,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buildBar(
                                      height: penggunaH,
                                      color: _kBluePrimary,
                                      value: valPengguna,
                                      width: barWidth,
                                    ),
                                    const SizedBox(width: barGap),
                                    _buildBar(
                                      height: anakH,
                                      color: _kTealPrimary,
                                      value: valAnak,
                                      width: barWidth,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Label bulan sumbu X
                              Text(
                                bulanNames[i],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
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
    // Jika nilai 0, batang dan label angka tidak muncul sama sekali
    if (value <= 0) {
      return SizedBox(width: width);
    }

    // Column dengan label angka di atas batang
    // Headroom pada chartPlotHeight (margin 18%+) menjamin tidak akan overflow
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
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            width: width,
            height: math.max(height, 4.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GENDER SECTION
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
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _kBorderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Anak Berdasarkan Jenis Kelamin',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Laki-laki
              Expanded(
                child: _buildGenderBlock(
                  icon: Icons.face_rounded,
                  iconColor: _kBluePrimary,
                  label: 'Laki-laki',
                  count: displayLaki,
                  pct: lakiPct,
                  color: _kBluePrimary,
                ),
              ),
              Container(
                width: 1,
                height: 64,
                color: _kBorderColor,
              ),
              // Perempuan
              Expanded(
                child: _buildGenderBlock(
                  icon: Icons.face_3_rounded,
                  iconColor: _kPink,
                  label: 'Perempuan',
                  count: displayPr,
                  pct: prPct,
                  color: _kPink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderBlock({
    required IconData icon,
    required Color iconColor,
    required String label,
    required int count,
    required double pct,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 36, color: iconColor),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.lato(fontSize: 12, color: _kTextGrey),
        ),
        const SizedBox(height: 4),
        Text(
          _formatNumber(count),
          style: GoogleFonts.lato(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '(${pct.toStringAsFixed(1)}%)',
          style: GoogleFonts.lato(fontSize: 12, color: _kTextGrey),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DATASET SECTION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDatasetSection() {
    final visible = _allUsers.take(_loadedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris label + tombol unduh
        Row(
          children: [
            Text(
              'Dataset Pengguna',
              style: GoogleFonts.lato(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _kTextDark,
              ),
            ),
            const Spacer(),
            _isDownloading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _kBluePrimary,
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: _showDownloadSheet,
                    icon: const Icon(
                      Icons.download_rounded,
                      size: 16,
                      color: _kBluePrimary,
                    ),
                    label: Text(
                      'Unduh',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: _kBluePrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _kBluePrimary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
          ],
        ),
        const SizedBox(height: 10),

        // Tabel
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _kBorderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: _buildTable(visible),
          ),
        ),

        // Loading more indicator
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: CircularProgressIndicator(
                  color: _kBluePrimary, strokeWidth: 2.5),
            ),
          ),
      ],
    );
  }

  Widget _buildTable(List<UserModel> users) {
    const colWidths = [130.0, 130.0, 200.0];
    const headers = ['Nama Depan', 'Nama Belakang', 'Email'];

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: colWidths.reduce((a, b) => a + b),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: List.generate(headers.length, (i) {
                return Container(
                  width: colWidths[i],
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: i < headers.length - 1
                      ? const BoxDecoration(
                          border: Border(
                              right: BorderSide(
                                  color: _kBorderColor, width: 0.5)))
                      : null,
                  child: Text(
                    headers[i],
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _kTextDark,
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kBorderColor),

          // Data rows
          ...List.generate(users.length, (idx) {
            final u = users[idx];
            final isLast = idx == users.length - 1;
            final cells = [_firstName(u.name), _lastName(u.name), u.email];
            return Column(
              children: [
                Row(
                  children: List.generate(cells.length, (ci) {
                    return Container(
                      width: colWidths[ci],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: ci < cells.length - 1
                          ? const BoxDecoration(
                              border: Border(
                                  right: BorderSide(
                                      color: _kBorderColor, width: 0.5)))
                          : null,
                      child: Text(
                        cells[ci],
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: const Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ),
                if (!isLast)
                  const Divider(height: 1, thickness: 1, color: _kBorderColor),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildNavBar() {
    final navItems = [
      _NavItem(icon: Icons.home_outlined, label: 'Beranda'),
      _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Konsultasi'),
      _NavItem(
          icon: Icons.find_in_page_outlined,
          label: 'Riwayat Konsultasi'),
      _NavItem(icon: Icons.person_outline_rounded, label: 'Profil'),
    ];

    return Container(
      width: double.infinity,
      height: 68.0,
      decoration: const BoxDecoration(
        color: Color(0xFFF2EDED),
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
              builder: (_) => const KonsultasiSuperadminPage()),
        );
        break;
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) =>
                  const DaftarRiwayatKonsultasiAdminPage()),
        );
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfilSuperadminPage()),
        );
        break;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTER — Garis bantu horizontal grid
// ══════════════════════════════════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  final int yMax;
  final int lineCount;
  const _GridPainter({required this.yMax, required this.lineCount});

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
      old.yMax != yMax || old.lineCount != lineCount;
}

// ══════════════════════════════════════════════════════════════════════════════
// Y-AXIS SCALE CALCULATOR
// ══════════════════════════════════════════════════════════════════════════════
class _YAxisScale {
  final int maxVal;
  final int lineCount;
  final List<int> ticks; // dari atas ke bawah (maxVal → 0)

  const _YAxisScale({
    required this.maxVal,
    required this.lineCount,
    required this.ticks,
  });

  /// Menghitung skala Y-axis yang rapi berdasarkan nilai puncak data.
  /// - Jika peak == 0, tampilkan skala 0..5 dengan 5 garis.
  /// - Jika tidak, bulatkan ke atas ke kelipatan yang rapi (2, 5, 10, 20, 50, dst.)
  ///   lalu bagi menjadi 4–5 interval garis bantu.
  factory _YAxisScale.calculate(int peak) {
    if (peak == 0) {
      return _YAxisScale(
        maxVal: 5,
        lineCount: 5,
        ticks: [5, 4, 3, 2, 1, 0],
      );
    }

    // Tambahkan margin 15% ke atas agar batang tertinggi tidak menyentuh tepi container
    final peakWithMargin = (peak * 1.15).ceil();

    // Tentukan interval yang rapi berdasarkan nilai setelah margin
    int interval;
    if (peakWithMargin <= 4) {
      interval = 1;
    } else if (peakWithMargin <= 10) {
      interval = 2;
    } else if (peakWithMargin <= 20) {
      interval = 5;
    } else if (peakWithMargin <= 50) {
      interval = 10;
    } else if (peakWithMargin <= 100) {
      interval = 20;
    } else if (peakWithMargin <= 200) {
      interval = 50;
    } else {
      interval = 100;
    }

    // Bulatkan maxVal ke atas ke kelipatan interval
    int maxVal = ((peakWithMargin / interval).ceil()) * interval;
    if (maxVal <= peak) {
      maxVal += interval;
    }
    final lineCount = maxVal ~/ interval;

    // Buat daftar tick dari atas (maxVal) ke bawah (0)
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
// BOTTOM SHEET UNDUH
// ══════════════════════════════════════════════════════════════════════════════
class _DownloadBottomSheet extends StatelessWidget {
  final void Function(String format) onSelect;
  const _DownloadBottomSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unduh Dataset',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kTextDark,
                      ),
                    ),
                    Text(
                      'Pilih format file',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: _kTextGrey,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close_rounded,
                      color: _kTextGrey, size: 22),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: _kBorderColor),

          // PDF option
          _buildOption(
            context,
            icon: Icons.picture_as_pdf_rounded,
            iconColor: const Color(0xFFEF4444),
            label: 'PDF',
            format: 'pdf',
          ),

          const Divider(height: 1, thickness: 0.5, color: _kBorderColor),

          // Excel option
          _buildOption(
            context,
            icon: Icons.grid_on_rounded,
            iconColor: const Color(0xFF16A34A),
            label: 'Excel (.xlsx)',
            format: 'excel',
          ),

          const SizedBox(height: 20),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: _kTextDark,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kTextGrey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════════════════════
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
