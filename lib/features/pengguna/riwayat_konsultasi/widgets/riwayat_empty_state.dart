import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget tampilan ketika pengguna belum memiliki riwayat konsultasi (Empty State).
///
/// Desain modern & bernuansa elegan:
/// - Badge ikon konsultasi medis bernuansa glow berlatar lingkaran halus
/// - Teks judul & deskripsi kontras tinggi pada light maupun dark mode
/// - Tombol aksi opsional untuk memulai konsultasi ke daftar dokter
/// - Selaras dengan footer ilustrasi pemandangan hutan di bawahnya
class RiwayatEmptyState extends StatelessWidget {
  final VoidCallback? onAction;

  const RiwayatEmptyState({super.key, this.onAction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Ikon Konsultasi Glowing (Pengganti folder berat)
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                    : const Color(0xFFEFF6FF),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.35)
                      : const Color(0xFFBFDBFE),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF3B82F6))
                        .withValues(alpha: isDark ? 0.12 : 0.08),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF1E3A8A).withValues(alpha: 0.5),
                              const Color(0xFF0F172A),
                            ]
                          : [
                              const Color(0xFFDBEAFE),
                              const Color(0xFFEFF6FF),
                            ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 34,
                      color: isDark
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18.0),

            // Teks Judul
            Text(
              'Belum Ada Riwayat Konsultasi',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 17.0,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 8.0),

            // Deskripsi Penjelas
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 290),
              child: Text(
                'Catatan resume medis dan riwayat konsultasi dokter anak Anda akan tersimpan rapi di sini.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 13.5,
                  fontWeight: FontWeight.normal,
                  height: 1.45,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),

            // Tombol Aksi Opsional
            if (onAction != null) ...[
              const SizedBox(height: 20.0),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.chat_rounded, size: 16),
                label: Text(
                  'Mulai Konsultasi',
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3985E7),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor:
                      const Color(0xFF3985E7).withValues(alpha: 0.35),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
