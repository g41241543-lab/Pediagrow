import 'package:flutter/material.dart';

/// Widget reusable untuk menampilkan ilustrasi pemandangan lanskap hutan,
/// rumput, gunung, dan tenda sebagai penutup footer halaman (misalnya di Beranda dan Profil Ibu).
///
/// Menggunakan aset terpusat: `assets/images/beranda_landscape_footer.jpg`.
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
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height ?? 110,
          color: const Color(0xFFD1FAE5),
          child: const Center(
            child: Icon(
              Icons.park_outlined,
              size: 48,
              color: Color(0xFF3985E7),
            ),
          ),
        ),
      ),
    );
  }
}
