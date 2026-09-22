import 'package:flutter/material.dart';

/// Widget reusable untuk menampilkan ilustrasi pemandangan lanskap hutan,
/// rumput, gunung, dan tenda sebagai penutup footer halaman (misalnya di Beranda,
/// Grafik Pertumbuhan, Resep MPASI, dan Menu Profil).
///
/// Menggunakan aset terpusat: `assets/images/beranda_landscape_footer.jpg`
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
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Image.asset(
        'assets/images/beranda_landscape_footer.jpg',
        width: double.infinity,
        fit: fit,
        alignment: Alignment.bottomCenter,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height ?? 100,
          color: const Color(0xFFD1FAE5),
          alignment: Alignment.center,
          child: const Icon(
            Icons.park_outlined,
            size: 44,
            color: Color(0xFF34D399),
          ),
        ),
      ),
    );
  }
}
