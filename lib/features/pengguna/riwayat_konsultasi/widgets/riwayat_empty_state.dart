import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget tampilan ketika pengguna belum memiliki riwayat konsultasi (Empty State).
///
/// Mengikuti desain referensi PediaGrow:
/// - Ilustrasi folder 3D biru di tengah konten.
/// - Teks "Belum ada riwayat konsultasi" tepat di bawah ilustrasi (jarak 10dp).
/// - Font Lato 16sp, warna #C5C5C5, weight normal.
/// - Layout responsif tanpa absolut positioning, aman dari overflow pada berbagai ukuran layar.
class RiwayatEmptyState extends StatelessWidget {
  const RiwayatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    // Tentukan ukuran ilustrasi secara responsif berdasarkan lebar/tinggi layar
    final screenWidth = MediaQuery.sizeOf(context).width;
    final illustrationSize = (screenWidth * 0.55).clamp(160.0, 240.0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ilustrasi Folder 3D Biru
            SizedBox(
              width: illustrationSize,
              height: illustrationSize,
              child: Image.asset(
                'assets/images/riwayat_empty_folder.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback visual jika file gambar tidak ditemukan
                  return Container(
                    width: illustrationSize,
                    height: illustrationSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEBF5FF).withValues(alpha: 0.6),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.folder_open_rounded,
                        size: 80,
                        color: Color(0xFF72A9F4),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Spacing 10dp antara ilustrasi dan teks
            const SizedBox(height: 10.0),

            // Teks "Belum ada riwayat konsultasi"
            Text(
              'Belum ada riwayat konsultasi',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 16.0,
                fontWeight: FontWeight.normal,
                color: const Color(0xFFC5C5C5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
