import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'konsultasi_selesai_dialog.dart';

/// Menampilkan Bottom Sheet konfirmasi untuk mengakhiri konsultasi dokter.
Future<void> showKonfirmasiSelesaiDialog(
  BuildContext context, {
  VoidCallback? onConfirmed,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => KonfirmasiSelesaiDialog(
      onConfirmed: () {
        Navigator.pop(ctx);
        if (onConfirmed != null) {
          onConfirmed();
        } else {
          // Default: lanjutkan menampilkan dialog konsultasi selesai
          showKonsultasiSelesaiDialog(context);
        }
      },
    ),
  );
}

/// Widget BottomSheet untuk Dialog Konfirmasi Selesai Konsultasi.
class KonfirmasiSelesaiDialog extends StatelessWidget {
  final VoidCallback onConfirmed;
  final VoidCallback? onCancel;

  const KonfirmasiSelesaiDialog({
    super.key,
    required this.onConfirmed,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ikon Peringatan Segitiga Merah dalam Lingkaran Soft Red
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF450A0A)
                    : const Color(0xFFFFECEC),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE53E3E),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Judul "Akhiri Konsultasi ini?"
            Text(
              'Akhiri Konsultasi ini?',
              style: GoogleFonts.lato(
                fontSize: 18.5,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A202C),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Deskripsi Penjelasan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Setelah konsultasi diakhiri, Anda tidak akan bisa mengirimkan pesan lagi dan obrolan akan tertutup otomatis.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF4A5568),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Tombol [Batal] dan [Ya, Akhiri]
            Row(
              children: [
                // Tombol Batal
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onCancel ?? () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF2C363D)
                            : const Color(0xFFE9EDEF),
                        foregroundColor: isDark
                            ? const Color(0xFFD1D7DB)
                            : const Color(0xFF718096),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Tombol Ya, Akhiri
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onConfirmed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53E3E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Ya, Akhiri',
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
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
