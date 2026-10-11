import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Halaman Pratinjau Dokumen PDF sebelum diunduh / dicetak
/// Memanfaatkan fitur bawaan `PdfPreview` dari package `printing`
class PdfPreviewScreen extends StatelessWidget {
  final String title;
  final String fileName;
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;

  const PdfPreviewScreen({
    super.key,
    required this.title,
    required this.fileName,
    required this.buildPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A202C)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A202C),
          ),
        ),
      ),
      body: PdfPreview(
        build: buildPdf,
        pdfFileName: fileName,
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        previewPageMargin: const EdgeInsets.all(12),
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A85FF)),
              ),
              SizedBox(height: 12),
              Text('Menyiapkan pratinjau dokumen...'),
            ],
          ),
        ),
      ),
    );
  }
}
