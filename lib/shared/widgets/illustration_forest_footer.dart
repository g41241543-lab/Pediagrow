import 'package:flutter/material.dart';

/// Widget reusable untuk menampilkan ilustrasi pemandangan lanskap hutan,
/// rumput, gunung, dan tenda sebagai penutup footer halaman (misalnya di Beranda,
/// Grafik Pertumbuhan, Resep MPASI, dan Menu Profil).
///
/// Menggunakan aset terpusat: `assets/images/beranda_landscape_footer_fiks.png`
/// persis sama seperti yang digunakan pada halaman Beranda.
class IllustrationForestFooter extends StatelessWidget {
  /// Tinggi kustom opsional, jika null akan mengikuti rasio lebar layar (fitWidth)
  final double? height;

  /// Penyesuaian box fit gambar
  final BoxFit fit;

  const IllustrationForestFooter({
    super.key,
    this.height,
    this.fit = BoxFit.fitWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Image.asset(
        'assets/images/beranda_landscape_footer_fiks.png',
        width: double.infinity,
        fit: fit,
        alignment: Alignment.bottomCenter,
        color: isDark ? const Color(0xFF0B1014).withValues(alpha: 0.35) : null,
        colorBlendMode: isDark ? BlendMode.srcATop : null,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height ?? 100,
          color: isDark ? const Color(0xFF1A2228) : const Color(0xFFD1FAE5),
          alignment: Alignment.center,
          child: Icon(
            Icons.park_outlined,
            size: 44,
            color: isDark ? const Color(0xFF10B981) : const Color(0xFF34D399),
          ),
        ),
      ),
    );
  }
}
