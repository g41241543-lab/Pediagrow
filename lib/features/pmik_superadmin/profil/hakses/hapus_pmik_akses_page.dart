import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/staff_auth_service.dart';
import '../../../../models/staff_account_model.dart';

/// Halaman / Dialog Konfirmasi Hapus PMIK untuk Superadmin PediaGrow.
///
/// Mengacu persis pada desain referensi:
/// - Judul: "Hapus Data" (Lato bold 18sp, hitam)
/// - Deskripsi: "Mohon pastikan ulang sebelum menghapus akun PMIK. Apakah anda yakin ingin menghapus?"
/// - Tombol Kiri: Outlined "Ya" (border tipis, teks biru/abu)
/// - Tombol Kanan: Filled "Tidak" (biru #3985E7, teks putih)
class HapusPmikAksesPage extends StatefulWidget {
  final StaffAccount pmik;
  final VoidCallback? onDeleted;

  const HapusPmikAksesPage({
    super.key,
    required this.pmik,
    this.onDeleted,
  });

  /// Helper untuk menampilkan dialog konfirmasi hapus data PMIK
  static Future<bool?> show(
    BuildContext context, {
    required StaffAccount pmik,
    VoidCallback? onDeleted,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => HapusPmikAksesPage(
        pmik: pmik,
        onDeleted: onDeleted,
      ),
    );
  }

  @override
  State<HapusPmikAksesPage> createState() => _HapusPmikAksesPageState();
}

class _HapusPmikAksesPageState extends State<HapusPmikAksesPage> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    try {
      await StaffAuthService().deleteStaffAccount(widget.pmik.id);

      if (!mounted) return;

      widget.onDeleted?.call();

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Akun PMIK ${widget.pmik.name} berhasil dihapus.',
            style: GoogleFonts.lato(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menghapus PMIK: $e',
              style: GoogleFonts.lato(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 10,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22.0, 24.0, 22.0, 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Judul Dialog
            Text(
              'Hapus Data',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 14.0),

            // Teks Konfirmasi
            Text(
              'Mohon pastikan ulang sebelum menghapus akun PMIK. Apakah anda yakin ingin menghapus?',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 14.5,
                color: const Color(0xFF334155),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24.0),

            // Baris Tombol Aksi "Ya" & "Tidak"
            Row(
              children: [
                // Tombol "Ya" (Outlined)
                Expanded(
                  child: SizedBox(
                    height: 44.0,
                    child: OutlinedButton(
                      onPressed: _isDeleting ? null : _handleDelete,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: _isDeleting
                          ? const SizedBox(
                              width: 18.0,
                              height: 18.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: Color(0xFF3985E7),
                              ),
                            )
                          : Text(
                              'Ya',
                              style: GoogleFonts.lato(
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3985E7),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 14.0),

                // Tombol "Tidak" (Filled Biru #3985E7)
                Expanded(
                  child: SizedBox(
                    height: 44.0,
                    child: ElevatedButton(
                      onPressed: _isDeleting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3985E7),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        'Tidak',
                        style: GoogleFonts.lato(
                          fontSize: 15.0,
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
