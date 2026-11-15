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
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Color(0x33000000),
              Color(0x88000000),
              Colors.black,
            ],
            stops: [0.0, 0.05, 0.12, 0.22],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: Image.asset(
          isDark
              ? 'assets/images/beranda_landscape_footer_dark.png'
              : 'assets/images/beranda_landscape_footer_fiks.png',
          width: double.infinity,
          fit: fit,
          alignment: Alignment.bottomCenter,
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
      ),
    );
  }
}
