import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../riwayat_konsultasi/daftar_riwayat_page.dart';

/// Menampilkan Bottom Sheet bahwa konsultasi dokter telah selesai.
Future<void> showKonsultasiSelesaiDialog(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    builder: (ctx) => const KonsultasiSelesaiDialog(),
  );
}

/// Widget BottomSheet untuk Konsultasi Selesai (Dialog 2).
class KonsultasiSelesaiDialog extends StatelessWidget {
  const KonsultasiSelesaiDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ikon Dokumen Biru dalam Lingkaran Soft Blue
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFEBF5FF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.description_outlined,
                  color: Color(0xFF2A85FF),
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Judul "Konsultasi telah selesai!"
            Text(
              'Konsultasi telah selesai!',
              style: GoogleFonts.lato(
                fontSize: 18.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A202C),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Deskripsi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Selanjutnya chat ini akan tertutup dan terhapus.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: const Color(0xFF4A5568),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Garis Pembatas Halus
            const Divider(color: Color(0xFFE2E8F0), thickness: 1),
            const SizedBox(height: 16),

            // Tombol [Kembali ke beranda] dan [Buka Riwayat Konsultasi]
            Row(
              children: [
                // Tombol Kembali ke beranda
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A85FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Kembali ke beranda',
                        style: GoogleFonts.lato(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tombol Buka Riwayat Konsultasi
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Tutup dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DaftarRiwayatPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A85FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Buka Riwayat Konsultasi',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
