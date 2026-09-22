import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Halaman kelola hak akses PMIK oleh Superadmin.
class DaftarPmikAksesPage extends StatelessWidget {
  const DaftarPmikAksesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          width: double.infinity,
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56.0,
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 36.0,
                        height: 36.0,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back,
                          size: 24.0,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        'Kelola Akses PMIK',
                        style: GoogleFonts.lato(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.badge_outlined,
                  size: 64.0,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Daftar Hak Akses PMIK',
                  style: GoogleFonts.lato(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Daftar dan pengaturan hak akses staf PMIK aktif dalam sistem.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 14.0,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
