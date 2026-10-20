import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modal dialog konfirmasi untuk menghapus notifikasi (satuan maupun keseluruhan).
///
/// Spesifikasi UI:
/// - Background modal melengkung (radius 12), bayangan halus.
/// - Menampilkan judul bold, pesan penjelasan, dan 2 tombol aksi:
///   - Kiri: "Batal" (Outline border #C5C5C5, teks abu/gelap)
///   - Kanan: "Hapus" / "Hapus Semua" (Solid merah #E53E3E, teks putih bold)
class KonfirmasiHapusNotifikasiDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final VoidCallback onConfirm;

  const KonfirmasiHapusNotifikasiDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.onConfirm,
  });

  /// Helper untuk konfirmasi hapus 1 notifikasi
  static Future<bool?> showSingle(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (dialogCtx) => KonfirmasiHapusNotifikasiDialog(
        title: 'Hapus Notifikasi',
        message: 'Apakah Anda yakin ingin menghapus notifikasi ini?',
        confirmText: 'Hapus',
        onConfirm: () {
          Navigator.of(dialogCtx).pop(true);
          onConfirm();
        },
      ),
    );
  }

  /// Helper untuk konfirmasi hapus seluruh notifikasi
  static Future<bool?> showAll(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (dialogCtx) => KonfirmasiHapusNotifikasiDialog(
        title: 'Hapus Semua Notifikasi',
        message: 'Apakah Anda yakin ingin menghapus seluruh notifikasi dari aplikasi?',
        confirmText: 'Hapus Semua',
        onConfirm: () {
          Navigator.of(dialogCtx).pop(true);
          onConfirm();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: isDark ? const Color(0xFF1A2228) : Colors.white,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Judul Dialog
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0B1014),
              ),
            ),
            const SizedBox(height: 14),

            // Pesan Konfirmasi
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF8696A0)
                    : const Color(0xFF7F7F7F),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Dua Tombol Aksi (Batal di kiri, Hapus di kanan)
            Row(
              children: [
                // Tombol "Batal"
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF2C363D)
                            : Colors.white,
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF2C363D)
                              : const Color(0xFFC5C5C5),
                          width: 1.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0B1014),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tombol "Hapus" (Solid Merah #E53E3E)
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53E3E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        confirmText,
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
