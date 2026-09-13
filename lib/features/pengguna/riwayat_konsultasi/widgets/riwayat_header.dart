import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom Header terstandarisasi untuk halaman Riwayat Konsultasi dan Detail Konsultasi.
///
/// Spesifikasi Desain:
/// - Tinggi tepat 56dp (tidak termasuk status bar / SafeArea top).
/// - Tombol kembali berada 12dp dari sisi kiri layar.
/// - Judul memiliki jarak 12dp setelah area tombol kembali.
/// - Berada permanen di bagian atas layar dan tidak ikut ter-scroll.
class RiwayatHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;

  const RiwayatHeader({
    super.key,
    required this.title,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Spacing 12dp dari sisi kiri layar
              const SizedBox(width: 12.0),

              // 2. Tombol Kembali
              GestureDetector(
                onTap: () {
                  if (onBackPressed != null) {
                    onBackPressed!();
                  } else {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 36.0,
                  height: 36.0,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back,
                    size: 24.0,
                    color: Color(0xFF000000),
                  ),
                ),
              ),

              // 3. Jarak 12dp setelah area tombol kembali
              const SizedBox(width: 12.0),

              // 4. Judul Halaman
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF000000),
                    letterSpacing: -0.2,
                  ),
                ),
              ),

              // Spacing 16dp di sisi kanan agar seimbang jika teks panjang
              const SizedBox(width: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}
