// ignore_for_file: use_build_context_synchronously
import 'dart:io';
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

import '../../../../shared/widgets/pedia_banner.dart';
import '../../../Grafik_Pertumbuhan/services/growth_service.dart';
import '../beranda_superadmin_page.dart';
import '../../konsultasi/konsultasi_superadmin_page.dart';
import '../../riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import '../../profil/profil_superadmin_page.dart';

const _kBlueChart = Color(0xFF2563EB); // Biru Tidak Stunting
const _kOrangeChart = Color(0xFFF59E0B); // Kuning-Orange Stunting
const _kTextDark = Color(0xFF1E293B);
const _kTextGrey = Color(0xFF64748B);
const _kGreenOk = Color(0xFF16A34A);
const _kRedDanger = Color(0xFFEF4444);

class _RekapRow {
  final String namaAnak;
  final String umur;
  final String bb;
  final String tb;
  final String hasilCekStunting;
  final DateTime tanggalCek; // dipakai untuk grafik

  const _RekapRow({
    required this.namaAnak,
    required this.umur,
    required this.bb,
    required this.tb,
    required this.hasilCekStunting,
    required this.tanggalCek,
  });
}

class _MonthlyStuntingData {
  final String month;
  final int tidakStunting;
  final int stunting;

  const _MonthlyStuntingData({
    required this.month,
    required this.tidakStunting,
    required this.stunting,
  });

  int get total => tidakStunting + stunting;
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

/// Halaman Rekapitulasi Stunting untuk POV Superadmin & PMIK.
///
/// 1. Header: Back button + Judul "Rekapitulasi"
/// 2. Grafik Hasil Cek Stunting: Stacked Bar Chart 12 bulan (Jan - Des),
///    dihitung dari data yang sama dengan tabel (sumbu Y otomatis).
/// 3. Dataset Hasil Cek Stunting: Judul + tombol "Unduh" di atas tabel data.
/// 4. Tabel Data: HANYA anak yang sudah pernah cek stunting.
/// 5. Unduh PDF atau Excel (.xlsx) dengan snackbar (tombol "Buka").
class RekapitulasiStuntingPage extends StatefulWidget {
  const RekapitulasiStuntingPage({super.key});

  @override
  State<RekapitulasiStuntingPage> createState() =>
      _RekapitulasiStuntingPageState();
}

class _RekapitulasiStuntingPageState extends State<RekapitulasiStuntingPage> {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _isDownloading = false;

  List<_RekapRow> _rows = [];
  List<_MonthlyStuntingData> _chartData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ═══════════════════════════════════════════════════
  // DATA LOADING
  // ═══════════════════════════════════════════════════
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Profil anak
      final Map<String, String> childNames = {};
      final Map<String, DateTime?> childBirthDates = {};
      try {
        final childSnap = await _firestore.collection('children').get();
        for (final doc in childSnap.docs) {
          final d = doc.data();
          final name = (d['name'] ?? d['nama'] ?? '').toString().trim();
          if (name.isNotEmpty) {
            childNames[doc.id] = name;
            final rawBirth = d['birth_date'] ?? d['tanggal_lahir'];
            childBirthDates[doc.id] = rawBirth != null
                ? DateTime.tryParse(rawBirth.toString())
                : null;
          }
        }
      } catch (e) {
        debugPrint('[Rekapitulasi] Error fetching children: $e');
      }

      // 2. Riwayat cek stunting (Firestore)
      final Map<String, List<Map<String, dynamic>>> recordsByChild = {};
      try {
        final growthSnap = await _firestore.collection('growth_records').get();
        for (final doc in growthSnap.docs) {
          final d = {...doc.data(), 'id': doc.id};
          final childId = (d['child_id'] ?? d['id_anak'] ?? '').toString();
          if (childId.isNotEmpty) {
            recordsByChild.putIfAbsent(childId, () => []).add(d);
          }
        }
      } catch (e) {
        debugPrint('[Rekapitulasi] Error fetching growth records: $e');
      }

      // 3. Riwayat dari memory GrowthService
      final memoryMap = GrowthService().recordsNotifier.value;
      for (final entry in memoryMap.entries) {
        for (final rec in entry.value) {
          recordsByChild.putIfAbsent(entry.key, () => []).add({
            'child_id': rec.childId,
            'date': rec.date,
            'age_formatted': rec.ageFormatted,
            'weight_kg': rec.weightKg,
            'height_cm': rec.heightCm,
            'status_gizi': rec.statusGizi,
          });
        }
      }

      // 4. Tabel: hanya anak yang sudah pernah cek stunting
      final rows = <_RekapRow>[];
      for (final entry in childNames.entries) {
        final childId = entry.key;
        final records = recordsByChild[childId] ?? [];
        if (records.isEmpty) continue;

        records.sort((a, b) {
          final da = _parseDate(a['date'] ?? a['tanggal']);
          final db = _parseDate(b['date'] ?? b['tanggal']);
          return db.compareTo(da);
        });
        final latest = records.first;
        final tanggalCek = _parseDate(latest['date'] ?? latest['tanggal']);
        final umur = (latest['age_formatted'] ?? latest['ageFormatted'] ?? '')
            .toString();
        final bb = _parseDouble(latest['weight_kg'] ?? latest['berat_kg']);
        final tb = _parseDouble(latest['height_cm'] ?? latest['tinggi_cm']);
        final status =
            (latest['status_gizi'] ??
                    latest['status_stunting'] ??
                    'Tidak Stunting')
                .toString();

        rows.add(
          _RekapRow(
            namaAnak: entry.value,
            umur: umur.isNotEmpty
                ? umur
                : _calcUmurFromBirth(childBirthDates[childId]),
            bb: bb > 0 ? '${bb.toStringAsFixed(1)} kg' : '-',
            tb: tb > 0 ? '${tb.toStringAsFixed(1)} cm' : '-',
            hasilCekStunting: _formatStatus(status),
            tanggalCek: tanggalCek,
          ),
        );
      }
      rows.sort((a, b) => b.tanggalCek.compareTo(a.tanggalCek));

      // 5. Grafik: dihitung dari rows yang sama dengan tabel
      const monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      final year = DateTime.now().year;
      final tidak = List<int>.filled(12, 0);
      final stunting = List<int>.filled(12, 0);
      for (final r in rows) {
        if (r.tanggalCek.year != year) continue;
        final i = r.tanggalCek.month - 1;
        if (r.hasilCekStunting == 'Tidak Stunting') {
          tidak[i]++;
        } else {
          stunting[i]++;
        }
      }
      final chartList = List.generate(
        12,
        (i) => _MonthlyStuntingData(
          month: monthNames[i],
          tidakStunting: tidak[i],
          stunting: stunting[i],
        ),
      );

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _chartData = chartList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[RekapitulasiStunting] load error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatStatus(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('tidak') ||
        lower.contains('normal') ||
        lower.contains('baik')) {
      return 'Tidak Stunting';
    }
    return 'Stunting';
  }

  DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString()) ?? DateTime.now();
  }

  double _parseDouble(dynamic raw) {
    if (raw == null) return 0.0;
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  String _calcUmurFromBirth(DateTime? birthDate) {
    if (birthDate == null) return '-';
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;
    if (days < 0) {
      final prevMonth = DateTime(now.year, now.month, 0);
      days += prevMonth.day;
      months -= 1;
    }
    if (months < 0) {
      months += 12;
      years -= 1;
    }
    return '$years tahun $months bulan $days hari';
  }

  // ═══════════════════════════════════════════════════
  // FITUR UNDUH (PDF & EXCEL)
  // ═══════════════════════════════════════════════════
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
      await _ensureStoragePermission();

      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final pdf = pw.Document();

      const cols = ['Nama Anak', 'Umur', 'BB', 'TB', 'Hasil Cek Stunting'];
      final rows = List<_RekapRow>.from(_rows);

      pw.Widget cell(String t, {bool bold = false, double size = 9}) =>
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: pw.Text(
              t,
              style: pw.TextStyle(
                fontSize: size,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: PdfColors.grey800,
              ),
            ),
          );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          footer: (ctx) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
          build: (ctx) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Rekapitulasi Hasil Cek Stunting',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'PediaGrow - Sistem Pemantauan Tumbuh Kembang Anak',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Tanggal Unduh: ${now.day}/${now.month}/${now.year}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(2.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF1F5F9),
                  ),
                  children: cols
                      .map((c) => cell(c, bold: true, size: 10))
                      .toList(),
                ),
                for (final r in rows)
                  pw.TableRow(
                    children: [
                      cell(r.namaAnak),
                      cell(r.umur),
                      cell(r.bb),
                      cell(r.tb),
                      cell(r.hasilCekStunting),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'rekapitulasi_stunting_$dateStr.pdf';
      final filePath = await _saveToDownloads(
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
        mimeType: 'application/pdf',
      );

      if (!mounted) return;
      setState(() => _isDownloading = false);
      _showSuccessSnackbar(filePath, fileName, mimeType: 'application/pdf');
    } catch (e, st) {
      debugPrint('[Download PDF] error: $e\n$st');
      if (!mounted) return;
      setState(() => _isDownloading = false);
      PediaBanner.show(context, message: 'Gagal mengunduh PDF', isError: true);
    }
  }

  Future<void> _downloadExcel() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      await _ensureStoragePermission();

      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = 'Rekapitulasi Stunting';

      final headers = [
        'No',
        'Nama Anak',
        'Umur',
        'Berat Badan (BB)',
        'Tinggi Badan (TB)',
        'Hasil Cek Stunting',
      ];
      for (int c = 0; c < headers.length; c++) {
        final cell = sheet.getRangeByIndex(1, c + 1);
        cell.setText(headers[c]);
        cell.cellStyle.bold = true;
        cell.cellStyle.backColor = '#D9E8FF';
      }

      for (int i = 0; i < _rows.length; i++) {
        final r = _rows[i];
        sheet.getRangeByIndex(i + 2, 1).setNumber((i + 1).toDouble());
        sheet.getRangeByIndex(i + 2, 2).setText(r.namaAnak);
        sheet.getRangeByIndex(i + 2, 3).setText(r.umur);
        sheet.getRangeByIndex(i + 2, 4).setText(r.bb);
        sheet.getRangeByIndex(i + 2, 5).setText(r.tb);
        sheet.getRangeByIndex(i + 2, 6).setText(r.hasilCekStunting);
      }
      for (int c = 1; c <= headers.length; c++) {
        sheet.autoFitColumn(c);
      }

      final List<int> raw = workbook.saveAsStream();
      workbook.dispose();

      const mime =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      final fileName = 'rekapitulasi_stunting_$dateStr.xlsx';
      final filePath = await _saveToDownloads(
        fileName: fileName,
        bytes: Uint8List.fromList(raw),
        mimeType: mime,
      );

      if (!mounted) return;
      setState(() => _isDownloading = false);
      _showSuccessSnackbar(filePath, fileName, mimeType: mime);
    } catch (e, st) {
      debugPrint('[Download Excel] error: $e\n$st');
      if (!mounted) return;
      setState(() => _isDownloading = false);
      PediaBanner.show(
        context,
        message: 'Gagal mengunduh Excel',
        isError: true,
      );
    }
  }

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 29) return true;
      final status = await Permission.storage.status;
      if (status.isGranted) return true;
      final result = await Permission.storage.request();
      return result.isGranted;
    } catch (e) {
      return true;
    }
  }

  Future<String?> _saveToDownloads({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    // 1. Salinan lokal (dipakai tombol "Buka")
    final docsDir = await getApplicationDocumentsDirectory();
    final localFile = File('${docsDir.path}/$fileName');
    await localFile.writeAsBytes(bytes, flush: true);

    // 2. Salin ke folder Download publik
    if (Platform.isAndroid) {
      var saved = false;
      try {
        await MediaStore.ensureInitialized();
        MediaStore.appFolder = 'PediaGrow';

        // File sementara terpisah, karena MediaStore bisa memindahkan file sumber
        final tmpDir = await getTemporaryDirectory();
        final tmpFile = File('${tmpDir.path}/$fileName');
        await tmpFile.writeAsBytes(bytes, flush: true);

        await MediaStore().saveFile(
          tempFilePath: tmpFile.path,
          dirType: DirType.download,
          dirName: DirName.download,
        );
        saved = true;
      } catch (e) {
        debugPrint('[MediaStore] saveFile error: $e');
      }

      // Cadangan untuk Android lama
      if (!saved) {
        try {
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            await File('${downloadDir.path}/$fileName')
                .writeAsBytes(bytes, flush: true);
          }
        } catch (e) {
          debugPrint('[Direct Download Write] error: $e');
        }
      }
    }

    return localFile.path;
  }

  void _showSuccessSnackbar(
    String? filePath,
    String fileName, {
    String? mimeType,
  }) {
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
                      PediaBanner.show(
                        context,
                        message: 'Tidak ada aplikasi untuk membuka file ini',
                        isError: true,
                      );
                    } else {
                      PediaBanner.show(
                        context,
                        message: 'Gagal membuka file: ${result.message}',
                        isError: true,
                      );
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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

  // ═══════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kBlueChart),
                    )
                  : SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // 1. GRAFIK HASIL CEK STUNTING
                          Text(
                            'Grafik Hasil Cek Stunting',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildStackedBarChart(),

                          const SizedBox(height: 24),

                          // 2. DATASET HEADER & TOMBOL UNDUH
                          _buildDatasetHeaderWithDownloadButton(),

                          const SizedBox(height: 12),

                          // 3. TABEL DATA ANAK (SCROLL HORIZONTAL)
                          _buildHorizontalTable(),

                          const SizedBox(height: 32),
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

  // ───────────────────────────────────────────────────
  // 1. HEADER
  // ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.arrow_back, color: Colors.black, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Rekapitulasi',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────
  // 2. GRAFIK STACKED BAR CHART (Jan - Des, sumbu Y otomatis)
  // ───────────────────────────────────────────────────
  Widget _buildStackedBarChart() {
    const double chartPlotHeight = 180.0;
    final int maxTotal = _chartData.fold<int>(
      0,
      (m, d) => d.total > m ? d.total : m,
    );
    final int step = maxTotal <= 4
        ? 1
        : maxTotal <= 10
        ? 2
        : maxTotal <= 20
        ? 5
        : maxTotal <= 50
        ? 10
        : maxTotal <= 100
        ? 20
        : 50;
    final int maxY = ((maxTotal <= 4 ? 4 : maxTotal) / step).ceil() * step;
    final List<int> yTicks = [for (int v = maxY; v >= 0; v -= step) v];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8, bottom: 8, right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plot Area + Y Axis Labels
          SizedBox(
            height: chartPlotHeight + 24, // 180 plot + 24 untuk label bulan
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Y Axis Labels
                SizedBox(
                  width: 28,
                  height: chartPlotHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: yTicks.map((val) {
                      return Text(
                        val.toString(),
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          color: _kTextGrey,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 6),

                // Plot Area: Grid Lines & Stacked Bars
                Expanded(
                  child: Stack(
                    children: [
                      // Horizontal Grid Lines
                      Positioned.fill(
                        bottom: 24,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(yTicks.length, (index) {
                            return Container(
                              height: 1,
                              color: const Color(0xFFE2E8F0),
                            );
                          }),
                        ),
                      ),

                      // Stacked Bars (12 Bulan)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _chartData.map((data) {
                            final total = data.total;
                            final double totalBarHeight =
                                (total / maxY) * chartPlotHeight;
                            final double stuntingHeight =
                                (data.stunting / maxY) * chartPlotHeight;

                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    height: chartPlotHeight,
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: SizedBox(
                                        width: 17,
                                        height: totalBarHeight.clamp(
                                          0.0,
                                          chartPlotHeight,
                                        ),
                                        child: Column(
                                          children: [
                                            // Atas: Stunting (Kuning-Oranye)
                                            Container(
                                              height: stuntingHeight.clamp(
                                                0.0,
                                                chartPlotHeight,
                                              ),
                                              color: _kOrangeChart,
                                            ),
                                            // Bawah: Tidak Stunting (Biru)
                                            Expanded(
                                              child: Container(
                                                color: _kBlueChart,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    data.month,
                                    style: GoogleFonts.lato(
                                      fontSize: 10,
                                      color: const Color(0xFF64748B),
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

          const SizedBox(height: 12),

          // Legend
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Row(
              children: [
                _buildLegendItem(_kBlueChart, 'Tidak Stunting'),
                const SizedBox(width: 18),
                _buildLegendItem(_kOrangeChart, 'Stunting'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.lato(fontSize: 11, color: const Color(0xFF475569)),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────
  // 3. DATASET HEADER & TOMBOL UNDUH
  // ───────────────────────────────────────────────────
  Widget _buildDatasetHeaderWithDownloadButton() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Dataset Hasil Cek Stunting',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        _isDownloading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: _kBlueChart,
                  strokeWidth: 2.2,
                ),
              )
            : InkWell(
                onTap: _showDownloadSheet,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.download_rounded,
                        size: 17,
                        color: Color(0xFF334155),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Unduh',
                        style: GoogleFonts.lato(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  // ───────────────────────────────────────────────────
  // 4. TABEL DATA (HORIZONTAL SCROLLABLE)
  // ───────────────────────────────────────────────────
  Widget _buildHorizontalTable() {
    if (_rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Text(
          'Belum ada data hasil cek stunting',
          style: GoogleFonts.lato(fontSize: 14, color: _kTextGrey),
        ),
      );
    }

    const colWidthNama = 185.0;
    const colWidthUmur = 180.0;
    const colWidthBb = 85.0;
    const colWidthTb = 85.0;
    const colWidthStatus = 160.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Tabel
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              ),
              child: Row(
                children: [
                  _buildHeaderCell('Nama Anak', colWidthNama),
                  _buildHeaderCell('Umur', colWidthUmur),
                  _buildHeaderCell('BB', colWidthBb),
                  _buildHeaderCell('TB', colWidthTb),
                  _buildHeaderCell('Hasil Cek Stunting', colWidthStatus),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Data Rows
            ..._rows.map((row) {
              final status = row.hasilCekStunting.toLowerCase();
              final isNormal =
                  status.contains('tidak') ||
                  status.contains('normal') ||
                  status.contains('baik');
              final statusColor = isNormal ? _kGreenOk : _kRedDanger;

              return Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: colWidthNama,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              row.namaAnak,
                              style: GoogleFonts.lato(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: colWidthUmur,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              row.umur,
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: colWidthBb,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              row.bb,
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: colWidthTb,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              row.tb,
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: colWidthStatus,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: statusColor.withAlpha(80),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                row.hasilCekStunting,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 0.8,
                    color: Color(0xFFF1F5F9),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────
  // 5. BOTTOM NAVIGATION BAR — disamakan dengan Beranda Superadmin
  //    Warna #F2EDED, tinggi 68dp, tab aktif = lingkaran putih + ikon biru muda
  // ───────────────────────────────────────────────────
  Widget _buildNavBar() {
    const navItems = [
      _NavItem(icon: Icons.home_rounded, label: 'Beranda'),
      _NavItem(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
      _NavItem(icon: Icons.manage_search_rounded, label: 'Riwayat Konsultasi'),
      _NavItem(icon: Icons.person_rounded, label: 'Profil'),
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
            // Beranda aktif karena Rekapitulasi berada dalam modul Beranda
            final isSelected = i == 0;
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
                      if (isSelected) ...[
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4.0,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            item.icon,
                            size: 22.0,
                            color: const Color(0xFF72A9F4),
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 11.0,
                                fontWeight: FontWeight.normal,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Icon(
                          item.icon,
                          size: 24.0,
                          color: const Color(0xFF9E9E9E),
                        ),
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
                                fontWeight: FontWeight.normal,
                                color: const Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                        ),
                      ],
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
          MaterialPageRoute(builder: (_) => const BerandaSuperadminPage()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const KonsultasiSuperadminPage()),
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
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProfilSuperadminPage()));
        break;
    }
  }
}

// ════════════════════════════════════════════════════════
// MODAL BOTTOM SHEET PILIHAN FORMAT UNDUH (PDF / EXCEL)
// ════════════════════════════════════════════════════════
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
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unduh Rekapitulasi',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kTextDark,
                      ),
                    ),
                    Text(
                      'Pilih format file',
                      style: GoogleFonts.lato(fontSize: 13, color: _kTextGrey),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close_rounded,
                    color: _kTextGrey,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildOption(
            context,
            'pdf',
            icon: Icons.picture_as_pdf_rounded,
            iconColor: const Color(0xFFEF4444),
            label: 'PDF',
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE2E8F0)),
          _buildOption(
            context,
            'excel',
            icon: Icons.grid_on_rounded,
            iconColor: _kGreenOk,
            label: 'Excel (.xlsx)',
          ),
          const SizedBox(height: 20),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String format, {
    required IconData icon,
    required Color iconColor,
    required String label,
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
                style: GoogleFonts.lato(fontSize: 14, color: _kTextDark),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _kTextGrey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
