import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../../../models/user_model.dart';

/// Halaman Pratinjau Dokumen Dataset Pengguna sebelum diunduh / dicetak / dibagikan.
/// Sesuai [REVISI S-5] dan [REVISI S-6].
class PreviewDatasetPage extends StatefulWidget {
  final List<UserModel> users;
  final String format; // 'pdf' atau 'excel'

  const PreviewDatasetPage({
    super.key,
    required this.users,
    required this.format,
  });

  @override
  State<PreviewDatasetPage> createState() => _PreviewDatasetPageState();
}

class _PreviewDatasetPageState extends State<PreviewDatasetPage> {
  static const Color _colorPrimaryBlue = Color(0xFF2B7AE8);
  static const Color _colorTealGreen = Color(0xFF3CC3A6);
  static const Color _colorTextBlack = Color(0xFF1E293B);
  static const Color _colorBorderGrey = Color(0xFFE2E8F0);

  bool _isProcessing = false;
  Uint8List? _cachedPdfBytes;
  Uint8List? _cachedExcelBytes;

  String get _formattedDate {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  String get _dateStr {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  String get _fileName =>
      'dataset_pengguna_$_dateStr.${widget.format == 'pdf' ? 'pdf' : 'xlsx'}';

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      MediaStore.ensureInitialized();
      MediaStore.appFolder = 'PediaGrow';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GENERATE PDF
  // ══════════════════════════════════════════════════════════════════════════
  Future<Uint8List> _generatePdfBytes() async {
    if (_cachedPdfBytes != null) return _cachedPdfBytes!;

    final pdf = pw.Document();

    pw.Font fontRegular;
    pw.Font fontBold;
    try {
      fontRegular = await PdfGoogleFonts.latoRegular();
      fontBold = await PdfGoogleFonts.latoBold();
    } catch (_) {
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final PdfColor pediaTeal = PdfColor.fromHex('3CC3A6');
    final PdfColor growBlue = PdfColor.fromHex('2B7AE8');
    final PdfColor textBlack = PdfColor.fromHex('1E293B');

    const headers = [
      'Nama Lengkap',
      'Email',
      'Jenis Kelamin',
      'Tanggal Lahir',
      'Provinsi',
      'Kota/Kabupaten',
      'Kecamatan',
      'Kelurahan/Desa',
    ];

    final tableData = widget.users.map((u) {
      return [
        u.name.isNotEmpty ? u.name : '-',
        u.email.isNotEmpty ? u.email : '-',
        u.gender?.isNotEmpty == true ? u.gender! : '-',
        u.birthDate?.isNotEmpty == true ? u.birthDate! : '-',
        u.province?.isNotEmpty == true ? u.province! : '-',
        u.city?.isNotEmpty == true ? u.city! : '-',
        u.district?.isNotEmpty == true ? u.district! : '-',
        u.subDistrict?.isNotEmpty == true ? u.subDistrict! : '-',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Kop Dokumen Resmi Sesuai Revisi S-6
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: 'Pedia',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold,
                                  color: pediaTeal,
                                ),
                              ),
                              pw.TextSpan(
                                text: 'Grow',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold,
                                  color: growBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Pantau Pertumbuhan, Cegah Stunting untuk Masa Depan',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      _formattedDate,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(color: pediaTeal, thickness: 1.5),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'LAPORAN DATASET PENGGUNA',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: textBlack,
                    ),
                  ),
                ),
                pw.SizedBox(height: 12),
              ],
            );
          }
          return pw.SizedBox(height: 10);
        },
        footer: (pw.Context context) {
          return pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'Dokumen dibuat otomatis oleh Aplikasi PediaGrow',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 7.5,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 7.5,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: tableData,
            headerStyle: pw.TextStyle(
              font: fontBold,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: textBlack,
            ),
            cellStyle: pw.TextStyle(
              font: fontRegular,
              fontSize: 7.5,
              color: textBlack,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('F1F5F9'),
            ),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            headerAlignment: pw.Alignment.centerLeft,
            cellAlignment: pw.Alignment.centerLeft,
            headerPadding:
                const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          ),
        ],
      ),
    );

    _cachedPdfBytes = await pdf.save();
    return _cachedPdfBytes!;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GENERATE EXCEL
  // ══════════════════════════════════════════════════════════════════════════
  Uint8List _generateExcelBytes() {
    if (_cachedExcelBytes != null) return _cachedExcelBytes!;

    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Dataset Pengguna';

    // 1. Kop Dokumen
    final logoCell = sheet.getRangeByIndex(1, 1);
    logoCell.setText('PediaGrow');
    logoCell.cellStyle.fontSize = 16;
    logoCell.cellStyle.bold = true;
    logoCell.cellStyle.fontColor = '#3CC3A6';

    final dateCell = sheet.getRangeByIndex(1, 8);
    dateCell.setText(_formattedDate);
    dateCell.cellStyle.bold = true;
    dateCell.cellStyle.hAlign = xlsio.HAlignType.right;

    final taglineCell = sheet.getRangeByIndex(2, 1);
    taglineCell.setText('Pantau Pertumbuhan, Cegah Stunting untuk Masa Depan');
    taglineCell.cellStyle.fontSize = 9;
    taglineCell.cellStyle.fontColor = '#64748B';

    // 2. Judul Laporan
    sheet.getRangeByIndex(4, 1, 4, 8).merge();
    final titleCell = sheet.getRangeByIndex(4, 1);
    titleCell.setText('LAPORAN DATASET PENGGUNA');
    titleCell.cellStyle.fontSize = 13;
    titleCell.cellStyle.bold = true;
    titleCell.cellStyle.hAlign = xlsio.HAlignType.center;

    // 3. Header Tabel (Row 6)
    const headers = [
      'Nama Lengkap',
      'Email',
      'Jenis Kelamin',
      'Tanggal Lahir',
      'Provinsi',
      'Kota/Kabupaten',
      'Kecamatan',
      'Kelurahan/Desa',
    ];

    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.getRangeByIndex(6, col + 1);
      cell.setText(headers[col]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#F1F5F9';
      cell.cellStyle.hAlign = xlsio.HAlignType.center;
    }

    // 4. Data baris (mulai baris 7)
    for (int i = 0; i < widget.users.length; i++) {
      final u = widget.users[i];
      final row = 7 + i;
      sheet.getRangeByIndex(row, 1).setText(u.name.isNotEmpty ? u.name : '-');
      sheet.getRangeByIndex(row, 2).setText(u.email.isNotEmpty ? u.email : '-');
      sheet.getRangeByIndex(row, 3).setText(
          u.gender?.isNotEmpty == true ? u.gender! : '-');
      sheet.getRangeByIndex(row, 4).setText(
          u.birthDate?.isNotEmpty == true ? u.birthDate! : '-');
      sheet.getRangeByIndex(row, 5).setText(
          u.province?.isNotEmpty == true ? u.province! : '-');
      sheet.getRangeByIndex(row, 6).setText(
          u.city?.isNotEmpty == true ? u.city! : '-');
      sheet.getRangeByIndex(row, 7).setText(
          u.district?.isNotEmpty == true ? u.district! : '-');
      sheet.getRangeByIndex(row, 8).setText(
          u.subDistrict?.isNotEmpty == true ? u.subDistrict! : '-');
    }

    // 5. Footer Dokumen
    final footerRow = 7 + widget.users.length + 1;
    sheet.getRangeByIndex(footerRow, 1, footerRow, 8).merge();
    final footerCell = sheet.getRangeByIndex(footerRow, 1);
    footerCell.setText('Dokumen dibuat otomatis oleh Aplikasi PediaGrow');
    footerCell.cellStyle.fontSize = 9;
    footerCell.cellStyle.fontColor = '#94A3B8';
    footerCell.cellStyle.hAlign = xlsio.HAlignType.right;

    // Lebar kolom menyesuaikan isi
    for (int col = 1; col <= 8; col++) {
      sheet.autoFitColumn(col);
    }

    final List<int> raw = workbook.saveAsStream();
    workbook.dispose();

    _cachedExcelBytes = Uint8List.fromList(raw);
    return _cachedExcelBytes!;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STORAGE & ACTIONS
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
    final res = await Permission.storage.request();
    return res.isGranted;
  }

  Future<String?> _saveFile(Uint8List bytes, String fileName) async {
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
        debugPrint('MediaStore saveFile error: $e');
      }
    }
    return localFile.path;
  }

  Future<void> _onPrintOrSave() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      if (widget.format == 'pdf') {
        final bytes = await _generatePdfBytes();
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: _fileName,
        );
      } else {
        if (!await _ensureStoragePermission()) {
          _showSnackbar('Izin penyimpanan diperlukan');
          setState(() => _isProcessing = false);
          return;
        }
        final bytes = _generateExcelBytes();
        final path = await _saveFile(bytes, _fileName);
        _showSuccessSnackbar(path, _fileName,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      }
    } catch (e) {
      _showSnackbar('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _onShare() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      if (widget.format == 'pdf') {
        final bytes = await _generatePdfBytes();
        await Printing.sharePdf(bytes: bytes, filename: _fileName);
      } else {
        final bytes = _generateExcelBytes();
        final path = await _saveFile(bytes, _fileName);
        if (path != null) {
          final res = await OpenFilex.open(
            path,
            type:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          );
          if (res.type != ResultType.done && mounted) {
            _showSnackbar('File disimpan di $path');
          }
        }
      }
    } catch (e) {
      _showSnackbar('Gagal membagikan file: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnackbar(String msg) {
    if (!mounted) return;
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

  void _showSuccessSnackbar(String? filePath, String fileName, {String? mimeType}) {
    if (!mounted) return;
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
                    _showSnackbar('Gagal membuka file: ${result.message}');
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
  // UI BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isPdf = widget.format == 'pdf';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Fixed 56dp
            _buildFixedHeader(),

            // 2. Konten Preview Scrollable
            Expanded(
              child: isPdf ? _buildPdfPreviewArea() : _buildExcelPreviewArea(),
            ),

            // 3. Tombol Aksi di Bagian Bawah: Ikon Printer (Cetak/Simpan) & Ikon Share (Bagikan)
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedHeader() {
    return Container(
      height: 56,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _colorBorderGrey, width: 1.0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Icon(Icons.arrow_back, color: _colorTextBlack, size: 24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Pedia',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _colorTealGreen,
                  ),
                ),
                TextSpan(
                  text: 'Grow',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _colorPrimaryBlue,
                  ),
                ),
                TextSpan(
                  text: ' - Unduh Dataset',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _colorTextBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPreviewArea() {
    return PdfPreview(
      maxPageWidth: 700,
      build: (format) => _generatePdfBytes(),
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      useActions: false, // Digantikan dengan bottom action bar sesuai instruksi
      scrollViewDecoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
      ),
      loadingWidget: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_colorPrimaryBlue),
        ),
      ),
      pdfFileName: _fileName,
    );
  }

  Widget _buildExcelPreviewArea() {
    const colWidths = [150.0, 180.0, 110.0, 110.0, 130.0, 130.0, 120.0, 120.0];
    const headers = [
      'Nama Lengkap',
      'Email',
      'Jenis Kelamin',
      'Tanggal Lahir',
      'Provinsi',
      'Kota/Kabupaten',
      'Kecamatan',
      'Kelurahan/Desa',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kop Dokumen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Pedia',
                              style: GoogleFonts.lato(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _colorTealGreen,
                              ),
                            ),
                            TextSpan(
                              text: 'Grow',
                              style: GoogleFonts.lato(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _colorPrimaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pantau Pertumbuhan, Cegah Stunting untuk Masa Depan',
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formattedDate,
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: _colorTealGreen, thickness: 1.5),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'LAPORAN DATASET PENGGUNA',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _colorTextBlack,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tabel Dataset Excel Scrollable Horizontal
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _colorBorderGrey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: colWidths.reduce((a, b) => a + b),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header baris (Frozen row)
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(7)),
                          ),
                          child: Row(
                            children: List.generate(headers.length, (i) {
                              return Container(
                                width: colWidths[i],
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: i < headers.length - 1
                                    ? const BoxDecoration(
                                        border: Border(
                                            right: BorderSide(
                                                color: _colorBorderGrey,
                                                width: 0.8)))
                                    : null,
                                child: Text(
                                  headers[i],
                                  style: GoogleFonts.lato(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const Divider(
                            height: 1, thickness: 1, color: _colorBorderGrey),

                        // Baris Data Pengguna
                        ...List.generate(widget.users.length, (idx) {
                          final u = widget.users[idx];
                          final isLast = idx == widget.users.length - 1;
                          final cells = [
                            u.name.isNotEmpty ? u.name : '-',
                            u.email.isNotEmpty ? u.email : '-',
                            u.gender?.isNotEmpty == true ? u.gender! : '-',
                            u.birthDate?.isNotEmpty == true
                                ? u.birthDate!
                                : '-',
                            u.province?.isNotEmpty == true
                                ? u.province!
                                : '-',
                            u.city?.isNotEmpty == true ? u.city! : '-',
                            u.district?.isNotEmpty == true
                                ? u.district!
                                : '-',
                            u.subDistrict?.isNotEmpty == true
                                ? u.subDistrict!
                                : '-',
                          ];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(cells.length, (ci) {
                                  return Container(
                                    width: colWidths[ci],
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: ci < cells.length - 1
                                        ? const BoxDecoration(
                                            border: Border(
                                                right: BorderSide(
                                                    color: _colorBorderGrey,
                                                    width: 0.8)))
                                        : null,
                                    child: Text(
                                      cells[ci],
                                      style: GoogleFonts.lato(
                                        fontSize: 11,
                                        color: const Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ),
                              if (!isLast)
                                const Divider(
                                    height: 1,
                                    thickness: 0.8,
                                    color: _colorBorderGrey),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Dokumen dibuat otomatis oleh Aplikasi PediaGrow',
                  style: GoogleFonts.lato(
                    fontSize: 9.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      width: double.infinity,
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _colorBorderGrey, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Tombol 1: Ikon Printer (Cetak / Simpan)
          _buildActionButton(
            icon: Icons.print_rounded,
            label: widget.format == 'pdf' ? 'Cetak / Simpan' : 'Simpan Excel',
            onTap: _onPrintOrSave,
          ),

          // Divider vertikal tipis
          Container(
            height: 32,
            width: 1,
            color: _colorBorderGrey,
          ),

          // Tombol 2: Ikon Share (Bagikan)
          _buildActionButton(
            icon: Icons.share_rounded,
            label: 'Bagikan',
            onTap: _onShare,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _isProcessing ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: _colorPrimaryBlue,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _colorPrimaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
