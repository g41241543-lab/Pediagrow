import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/doctor_service.dart';
import '../../../../models/doctor_model.dart';

/// Halaman / Dialog Konfirmasi Hapus Dokter untuk Superadmin PediaGrow.
///
/// Mengacu persis pada desain referensi:
/// - Judul: "Hapus Data" (Lato bold 18sp, hitam)
/// - Deskripsi: "Mohon pastikan ulang sebelum menghapus akun Dokter. Apakah anda yakin ingin menghapus?"
/// - Tombol Kiri: Outlined "Ya" (putih dengan border tipis, teks biru)
/// - Tombol Kanan: Filled "Tidak" (biru #3985E7, teks putih)
class HapusDokterAksesPage extends StatefulWidget {
  final DoctorModel doctor;
  final VoidCallback? onDeleted;

  const HapusDokterAksesPage({
    super.key,
    required this.doctor,
    this.onDeleted,
  });

  /// Helper untuk menampilkan dialog konfirmasi hapus data
  static Future<bool?> show(
    BuildContext context, {
    required DoctorModel doctor,
    VoidCallback? onDeleted,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => HapusDokterAksesPage(
        doctor: doctor,
        onDeleted: onDeleted,
      ),
    );
  }

  @override
  State<HapusDokterAksesPage> createState() => _HapusDokterAksesPageState();
}

class _HapusDokterAksesPageState extends State<HapusDokterAksesPage> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    try {
      await DoctorService().deleteDoctor(widget.doctor.id);

      if (!mounted) return;

      widget.onDeleted?.call();

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dokter ${widget.doctor.name} berhasil dihapus.',
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
              'Gagal menghapus dokter: $e',
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
            // Judul Modal: "Hapus Data"
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

            // Teks Deskripsi Konfirmasi
            Text(
              'Mohon pastikan ulang sebelum menghapus akun Dokter. Apakah anda yakin ingin menghapus?',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24.0),

            // Baris Tombol Aksi: "Ya" (Outlined) & "Tidak" (Solid Biru)
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
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                      child: _isDeleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
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
                        padding: EdgeInsets.zero,
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
