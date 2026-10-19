import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/pmik_superadmin/beranda/grafik_pengguna/grafik_pengguna_page.dart';

/// Service untuk menghasilkan dokumen PDF resmi PediaGrow dengan Kop Standar:
/// - Kop Logo Pedia (Biru) + Grow (Toska)
/// - Slogan "Pantau Pertumbuhan, Cegah Stunting untuk Masa Depan"
/// - Tanggal Unduh / Pemeriksaan di kanan atas
/// - Garis pemisah kop warna biru
/// - Judul Dokumen resmi
/// - Footer "Dokumen dibuat otomatis oleh Aplikasi PediaGrow"
class PdfReportService {
  static final PdfColor pediaBlue = PdfColor.fromHex('2A85FF');
  static final PdfColor growTeal = PdfColor.fromHex('3CC3A6');
  static final PdfColor textDark = PdfColor.fromHex('1A202C');
  static final PdfColor textMuted = PdfColor.fromHex('718096');
  static final PdfColor borderGrey = PdfColor.fromHex('E2E8F0');

  /// Kop Dokumen Resmi PediaGrow (Sesuai Lampiran Referensi)
  static pw.Widget buildKopHeader({
    required pw.Font fontBold,
    required pw.Font fontRegular,
    required String title,
    String? subtitle,
    String? dateLabel,
    String? formattedDate,
  }) {
    final now = DateTime.now();
    final dateStr = formattedDate ??
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Sisi Kiri: Logo PediaGrow & Slogan
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
                          color: pediaBlue,
                        ),
                      ),
                      pw.TextSpan(
                        text: 'Grow',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: growTeal,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Pantau Pertumbuhan, Cegah Stunting untuk Masa Depan',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 9.5,
                    color: textMuted,
                  ),
                ),
              ],
            ),

            // Sisi Kanan: Tanggal Pemeriksaan / Unduh
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  dateLabel ?? 'Tanggal Unduh:',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 9.0,
                    color: textMuted,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  dateStr,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 11.0,
                    fontWeight: pw.FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 8),

        // Garis Pembatas Kop Warna Biru Tebal
        pw.Container(
          width: double.infinity,
          height: 2.2,
          color: pediaBlue,
        ),

        pw.SizedBox(height: 12),

        // Judul Dokumen di Tengah
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                title,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 13.5,
                  fontWeight: pw.FontWeight.bold,
                  color: textDark,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  subtitle,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 9.0,
                    color: textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),

        pw.SizedBox(height: 14),
      ],
    );
  }

  /// Footer Resmi Dokumen
  static pw.Widget buildKopFooter({
    required pw.Font fontRegular,
    required pw.Context context,
  }) {
    return pw.Column(
      children: [
        pw.Divider(color: borderGrey, thickness: 0.8),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Dokumen dibuat otomatis oleh Aplikasi PediaGrow',
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 8.5,
                color: textMuted,
              ),
            ),
            pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 8.5,
                color: textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Menghasilkan PDF Dataset Pengguna lengkap dengan Kop Resmi
  static Future<Uint8List> generateDatasetPenggunaPdf({
    required List<UserDemographicRow> users,
    int totalPengguna = 0,
    int totalAnak = 0,
  }) async {
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

    const headers = [
      'No',
      'Nama Lengkap',
      'Jenis Kelamin',
      'Umur',
      'Provinsi',
      'Kota/Kabupaten',
      'Kecamatan',
      'Kelurahan/Desa',
    ];

    final tableData = users.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final u = entry.value;
      return [
        '$i',
        u.namaLengkap,
        u.jenisKelamin,
        u.umur,
        u.provinsi,
        u.kota,
        u.kecamatan,
        u.kelurahanDesa,
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        header: (context) {
          if (context.pageNumber == 1) {
            return buildKopHeader(
              fontBold: fontBold,
              fontRegular: fontRegular,
              title: 'LAPORAN REKAPITULASI DATASET PENGGUNA',
              subtitle:
                  'Sistem Pemantauan Tumbuh Kembang & Demografi Pengguna PediaGrow (Total Pengguna: ${users.length})',
              dateLabel: 'Tanggal Unduh:',
            );
          }
          return pw.SizedBox(height: 8);
        },
        footer: (context) => buildKopFooter(
          fontRegular: fontRegular,
          context: context,
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: tableData,
            border: pw.TableBorder.all(color: borderGrey, width: 0.5),
            headerStyle: pw.TextStyle(
              font: fontBold,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: pediaBlue),
            cellStyle: pw.TextStyle(font: fontRegular, fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
            rowDecoration: const pw.BoxDecoration(),
            oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('F8FAFC')),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Menghasilkan PDF Rekapitulasi Hasil Cek Stunting dengan Kop Resmi
  static Future<Uint8List> generateRekapitulasiStuntingPdf({
    required List<StuntingRecordRow> records,
    int totalStunting = 0,
    int totalNormal = 0,
  }) async {
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

    const headers = [
      'No',
      'Nama Anak',
      'Umur',
      'BB (kg)',
      'TB (cm)',
      'Hasil Analisis Gizi / Stunting',
      'Tanggal Cek',
    ];

    final tableData = records.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final r = entry.value;
      final tc = r.tanggalCek;
      final dateStr = '${tc.day.toString().padLeft(2, '0')}/${tc.month.toString().padLeft(2, '0')}/${tc.year}';
      return [
        '$i',
        r.namaAnak,
        r.umur,
        r.bb,
        r.tb,
        r.hasil,
        dateStr,
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        header: (context) {
          if (context.pageNumber == 1) {
            return buildKopHeader(
              fontBold: fontBold,
              fontRegular: fontRegular,
              title: 'LAPORAN REKAPITULASI HASIL CEK STUNTING',
              subtitle:
                  'Metode: Random Forest Classifier dengan Hyperparameter Optimization (GridSearchCV)',
              dateLabel: 'Tanggal Pemeriksaan:',
            );
          }
          return pw.SizedBox(height: 8);
        },
        footer: (context) => buildKopFooter(
          fontRegular: fontRegular,
          context: context,
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: tableData,
            border: pw.TableBorder.all(color: borderGrey, width: 0.5),
            headerStyle: pw.TextStyle(
              font: fontBold,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: pediaBlue),
            cellStyle: pw.TextStyle(font: fontRegular, fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
            },
            oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('F8FAFC')),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          ),
          pw.SizedBox(height: 16),
          // Catatan Penting
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('FFFBEB'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColor.fromHex('FDE68A'), width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CATATAN PENTING:',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('92400E'),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Hasil cek stunting ini merupakan hasil analisis Data Mining menggunakan algoritma Random Forest Classifier yang dioptimalkan dengan GridSearchCV berdasarkan data antropometri anak. Hasil ini berfungsi sebagai skrining deteksi dini dan tidak menggantikan diagnosis medis klinis oleh dokter spesialis anak. Segera hubungi fasilitas pelayanan kesehatan atau posyandu terdekat untuk konsultasi dan pemantauan berkala.',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 7.5,
                    color: PdfColor.fromHex('78350F'),
                    lineSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
