import 'package:flutter/material.dart';

/// Widget ilustrasi footer khusus untuk Halaman Permainan (Start Kuis & Skor Akhir).
///
/// Menggunakan gambar lanskap pemandangan yang SAMA PERSIS dengan Halaman Beranda
/// (`assets/images/beranda_landscape_footer_fiks.png`), diposisikan tetap (fixed) di bagian bawah,
/// dengan gradasi warna atas yang disesuaikan secara ultra-halus dengan warna background biru
/// kuis (#5B9BF5 & #6FA8E8) agar transisinya menyatu sempurna tanpa batas kasar.
class GameForestSilhouetteFooter extends StatelessWidget {
  /// Tinggi ilustrasi footer. Default 160dp.
  final double height;

  const GameForestSilhouetteFooter({super.key, this.height = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // ── Gambar lanskap dengan ShaderMask fade lembut di bagian atas ──
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x80FFFFFF), Colors.white],
                stops: [0.0, 0.18, 0.40],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: Image.asset(
              'assets/images/beranda_landscape_footer_fiks.png',
              width: double.infinity,
              height: height,
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
              errorBuilder: (context, error, stackTrace) => Container(
                height: height,
                color: const Color(0xFFD1FAE5),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.park_outlined,
                  size: 44,
                  color: Color(0xFF34D399),
                ),
              ),
            ),
          ),

          // ── Gradasi overlay multi-stop ultra halus menyatu ke background #6FA8E8 ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF6FA8E8), // 100% menyatu dengan background kuis
                    Color(0xF06FA8E8),
                    Color(0xCC6FA8E8),
                    Color(0x996FA8E8),
                    Color(0x5E6FA8E8),
                    Color(0x296FA8E8),
                    Colors.transparent, // Bawah jernih menampilkan pepohonan & bukit
                  ],
                  stops: [0.0, 0.10, 0.22, 0.36, 0.50, 0.65, 0.82],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
