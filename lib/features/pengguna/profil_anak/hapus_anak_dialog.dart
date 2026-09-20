import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dialog konfirmasi modal untuk menghapus profil anak.
///
/// Spesifikasi UI:
/// - Berada di tengah layar dengan backdrop gelap semi-transparan
/// - Kartu putih dengan corner radius 12
/// - Judul: "Hapus Data" (teks gelap, bold, fontSize 18)
/// - Pesan: "Mohon pastikan ulang sebelum menghapus profil anak. Apakah anda yakin ingin menghapus?" (teks abu tua #7F7F7F, fontSize 14)
/// - Dua tombol berdampingan dengan tinggi 40dp dan corner radius 8:
///   - Kiri: "Ya" (outline, border abu muda #C5C5C5, teks gelap, latar putih)
///   - Kanan: "Tidak" (solid biru #3985E7, teks putih, bold)
class HapusAnakDialog extends StatelessWidget {
  final VoidCallback onConfirmDelete;

  const HapusAnakDialog({
    super.key,
    required this.onConfirmDelete,
  });

  /// Helper untuk menampilkan dialog konfirmasi hapus
  static Future<bool?> show(
    BuildContext context, {
    required VoidCallback onConfirmDelete,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (dialogCtx) => HapusAnakDialog(
        onConfirmDelete: () {
          Navigator.of(dialogCtx).pop(true);
          onConfirmDelete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.white,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Judul Modal
            Text(
              'Hapus Data',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),

            // Pesan Konfirmasi
            Text(
              'Mohon pastikan ulang sebelum menghapus profil anak. Apakah anda yakin ingin menghapus?',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: const Color(0xFF7F7F7F),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Baris Tombol Aksi (Ya di kiri, Tidak di kanan, tinggi 40dp, radius 8)
            Row(
              children: [
                // Tombol "Ya" (Outline, border #C5C5C5, teks gelap, latar putih)
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: onConfirmDelete,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFC5C5C5), width: 1.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'Ya',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tombol "Tidak" (Solid biru #3985E7, teks putih)
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3985E7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'Tidak',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
