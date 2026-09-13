import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Halaman Daftar Riwayat Konsultasi PediaGrow
class DaftarRiwayatPage extends StatelessWidget {
  const DaftarRiwayatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A202C)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Riwayat Konsultasi',
          style: GoogleFonts.lato(
            color: const Color(0xFF1A202C),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Text(
          'Belum ada riwayat konsultasi.',
          style: GoogleFonts.lato(
            color: const Color(0xFF718096),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
