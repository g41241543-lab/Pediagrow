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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topFadeColor =
        isDark ? const Color(0xFF1A2228) : const Color(0xFF6FA8E8);

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
                color: isDark ? const Color(0xFF0B1014) : const Color(0xFFD1FAE5),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.park_outlined,
                  size: 44,
                  color: Color(0xFF34D399),
                ),
              ),
            ),
          ),

          // ── Gradasi overlay multi-stop ultra halus menyatu ke background ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    topFadeColor,
                    topFadeColor.withValues(alpha: 0.94),
                    topFadeColor.withValues(alpha: 0.80),
                    topFadeColor.withValues(alpha: 0.60),
                    topFadeColor.withValues(alpha: 0.37),
                    topFadeColor.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.10, 0.22, 0.36, 0.50, 0.65, 0.82],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
