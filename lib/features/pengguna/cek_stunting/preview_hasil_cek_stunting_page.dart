import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'form_cek_stunting_page.dart';

/// Halaman Pratinjau & Download/Cetak Dokumen Hasil Cek Stunting PediaGrow.
///
/// Menyajikan dokumen hasil analisis stunting dalam format PDF resmi yang rapi,
/// serta menyediakan fungsionalitas cetak (Print) dan simpan/bagikan (Save/Share)
/// ke perangkat Android.
class PreviewHasilCekStuntingPage extends StatelessWidget {
  final StuntingAnalysisResult result;
  final String namaAnak;
  final String jenisKelamin;
  final String tanggalLahir;
  final String tanggalPemeriksaan;
  final String beratBadanLahir;
  final String tinggiBadanLahir;
  final double beratBadanSekarang;
  final double tinggiBadanSekarang;
  final bool isAsiEksklusif;
  final String usiaDeskripsi;

  static const Color colorPrimaryBlue = Color(0xFF4B83D6);
  static const Color colorTealGreen = Color(0xFF3CC3A6);
  static const Color colorTextBlack = Color(0xFF000000);

  const PreviewHasilCekStuntingPage({
    super.key,
    required this.result,
    required this.namaAnak,
    required this.jenisKelamin,
    required this.tanggalLahir,
    required this.tanggalPemeriksaan,
    required this.beratBadanLahir,
    required this.tinggiBadanLahir,
    required this.beratBadanSekarang,
    required this.tinggiBadanSekarang,
    required this.isAsiEksklusif,
    required this.usiaDeskripsi,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNormal = result.status == StuntingStatus.normal;
    final String statusText = isNormal ? 'TIDAK STUNTING' : 'STUNTING';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header 56 dp
            _buildFixedHeader(context),

            // Area PDF Preview interaktif
            Expanded(
              child: PdfPreview(
                maxPageWidth: 700,
                build: (format) =>
                    _generatePdfDocument(format, statusText, isNormal),
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                useActions: true,
                scrollViewDecoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                ),
                loadingWidget: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colorPrimaryBlue),
                  ),
                ),
                pdfFileName:
                    'Hasil_Cek_Stunting_${namaAnak.replaceAll(' ', '_')}.pdf',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedHeader(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
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
                  child: Icon(Icons.arrow_back, color: colorTextBlack, size: 24),
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
                    color: colorPrimaryBlue,
                  ),
                ),
                TextSpan(
                  text: 'Grow',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorTealGreen,
                  ),
                ),
                TextSpan(
                  text: ' - Cetak Hasil',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorTextBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membuat dokumen PDF resmi berdesain medis yang profesional
  Future<Uint8List> _generatePdfDocument(
    PdfPageFormat format,
    String statusText,
    bool isNormal,
  ) async {
    final pdf = pw.Document();

    // Palet Warna Resmi PediaGrow
    final PdfColor pediaBlue = PdfColor.fromHex('4B83D6');
    final PdfColor growGreen = PdfColor.fromHex('3CC3A6');
    final PdfColor dangerRed = PdfColor.fromHex('B13535');
    final PdfColor statusColor = isNormal ? growGreen : dangerRed;
    final PdfColor textBlack = PdfColor.fromHex('1A1A1A');
    final PdfColor greyBorder = PdfColor.fromHex('E0E0E0');
    final PdfColor lightBg = PdfColor.fromHex('F8FAFC');

    // Memuat font Lato resmi Google Fonts untuk PDF dengan fallback Helvetica
    pw.Font fontRegular;
    pw.Font fontBold;
    try {
      fontRegular = await PdfGoogleFonts.latoRegular();
      fontBold = await PdfGoogleFonts.latoBold();
    } catch (_) {
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Header Surat Medis / PediaGrow
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // "Pedia" (#4B83D6) & "Grow" (#3CC3A6) Font Lato Bold
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: 'Pedia',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: pediaBlue,
                              ),
                            ),
                            pw.TextSpan(
                              text: 'Grow',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: growGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      // Slogan: "Pantau Pertumbuhan, Cegah Stunting untuk Masa Depan"
                      pw.Text(
                        'Pantau Pertumbuhan, Cegah Stunting untuk Masa Depan',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 9.5,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Tanggal Pemeriksaan:',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        tanggalPemeriksaan,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: textBlack,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(color: pediaBlue, thickness: 2),
              pw.SizedBox(height: 12),

              // 2. Judul Laporan
              pw.Center(
                child: pw.Text(
                  'LAPORAN HASIL ANALISIS STUNTING',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: textBlack,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Metode: Random Forest Classifier dengan Hyperparameter Optimization (GridSearchCV)',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 8.5,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
              ),

              pw.SizedBox(height: 16),

              // 3. Tabel Data Pasien Si Kecil
              pw.Text(
                'A. INFORMASI DATA PEMERIKSAAN',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: pediaBlue,
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Container(
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: greyBorder, width: 0.8),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  children: [
                    _buildPdfRow('Nama Lengkap', namaAnak, fontRegular, fontBold),
                    _buildPdfDivider(),
                    _buildPdfRow('Jenis Kelamin', jenisKelamin, fontRegular, fontBold),
                    _buildPdfDivider(),
                    _buildPdfRow('Tanggal Lahir', tanggalLahir, fontRegular, fontBold),
                    _buildPdfDivider(),
                    _buildPdfRow('Umur Saat Cek', usiaDeskripsi, fontRegular, fontBold),
                    _buildPdfDivider(),
                    _buildPdfRow(
                      'Berat / Tinggi Saat Lahir',
                      '$beratBadanLahir kg / $tinggiBadanLahir cm',
                      fontRegular,
                      fontBold,
                    ),
                    _buildPdfDivider(),
                    _buildPdfRow(
                      'Berat / Tinggi Saat Ini',
                      '${beratBadanSekarang.toStringAsFixed(1)} kg / ${tinggiBadanSekarang.toStringAsFixed(1)} cm',
                      fontRegular,
                      fontBold,
                    ),
                    _buildPdfDivider(),
                    _buildPdfRow(
                      'Pemberian ASI Penuh',
                      isAsiEksklusif ? 'Ya (Eksklusif)' : 'Tidak',
                      fontRegular,
                      fontBold,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // 4. Hasil Prediksi Klasifikasi Data Mining
              pw.Text(
                'B. HASIL ANALISIS DATA MINING (RANDOM FOREST & GRIDSEARCHCV)',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: pediaBlue,
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: pw.BoxDecoration(
                  color: statusColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'HASIL PREDIKSI: $statusText',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Model: Random Forest Classifier (GridSearchCV Tuned)',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 9,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Tingkat Kepercayaan (Confidence): ${(result.confidenceProbability * 100).toStringAsFixed(1)}% | Z-Score (TB/U): ${result.zScoreHeightForAge.toStringAsFixed(2)} SD',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 8.5,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // 5. Rekomendasi Pencegahan & Tindak Lanjut
              pw.Text(
                'C. REKOMENDASI PENCEGAHAN & PERAWATAN STUNTING',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: pediaBlue,
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Container(
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: greyBorder, width: 0.8),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Upaya yang bisa dilakukan untuk pencegahan stunting yaitu:',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: textBlack,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    _buildPdfBullet('Pemberian pola asuh yang tepat.', fontRegular),
                    _buildPdfBullet('Memberikan MPASI yang optimal.', fontRegular),
                    _buildPdfBullet('Mengobati penyakit yang dialami anak.', fontRegular),
                    _buildPdfBullet('Perbaikan kebersihan lingkungan.', fontRegular),
                    _buildPdfBullet('Menerapkan hidup bersih keluarga.', fontRegular),
                  ],
                ),
              ),

              pw.Spacer(),

              // 6. CATATAN DI BAWAH DIPERBESAR DENGAN BORDER KUNING
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('FEFCE8'),
                  border: pw.Border.all(color: PdfColor.fromHex('EAB308'), width: 1.8),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CATATAN PENTING:',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('854D0E'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Hasil cek stunting ini merupakan hasil analisis Data Mining menggunakan algoritma Random Forest Classifier yang dioptimalkan dengan GridSearchCV berdasarkan data antropometri anak. Hasil ini berfungsi sebagai skrining deteksi dini dan tidak menggantikan diagnosis medis klinis oleh dokter spesialis anak. Segera hubungi fasilitas pelayanan kesehatan atau posyandu terdekat untuk konsultasi dan pemantauan berkala.',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 9.0,
                        height: 1.35,
                        color: PdfColor.fromHex('1F2937'),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 8),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Dokumen dibuat otomatis oleh Aplikasi PediaGrow',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 8,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfRow(
    String label,
    String value,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: 8.5,
              color: PdfColors.grey800,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfDivider() {
    return pw.Divider(color: PdfColors.grey300, thickness: 0.5, height: 4);
  }

  pw.Widget _buildPdfBullet(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 3.5,
            height: 3.5,
            margin: const pw.EdgeInsets.only(top: 3.5, right: 5),
            decoration: const pw.BoxDecoration(
              color: PdfColors.black,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                font: font,
                fontSize: 8.5,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
