import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_page.dart';
import 'register_page.dart';

/// Halaman pilihan autentikasi (Masuk / Daftar Akun Baru).
///
/// Memenuhi tata letak resmi PediaGrow (Tahap 8):
/// 1. Judul "PediaGrow" (Baloo 2 Bold 50, "Pedia" #4B83D6, "Grow" #3CC3A6).
/// 2. Tagline (Lato regular 18, color #1E293B).
/// 3. Tombol "Masuk" (350x52, #3985E7, Lato bold 20 putih) -> membuka LoginPage.
/// 4. Tombol "Daftar Akun Baru" (350x52, border #3985E7, Lato bold 20 biru) -> membuka RegisterPage.
/// 5. Ilustrasi keluarga di bagian bawah layar tanpa scroll.
class AuthChoicePage extends StatelessWidget {
  /// Callback opsional jika tombol "Masuk" ditekan (default: membuka LoginPage).
  final VoidCallback? onLoginPressed;

  /// Callback opsional jika tombol "Daftar Akun Baru" ditekan (default: membuka RegisterPage).
  final VoidCallback? onRegisterPressed;

  const AuthChoicePage({
    super.key,
    this.onLoginPressed,
    this.onRegisterPressed,
  });

  // Palet Warna Resmi PediaGrow
  static const Color colorPediaBlue = Color(0xFF4B83D6); // Pedia
  static const Color colorGrowGreen = Color(0xFF3CC3A6); // Grow
  static const Color colorButtonPrimary = Color(0xFF3985E7); // Tombol Masuk
  static const Color colorTextDark = Color(0xFF1E293B); // Tagline text

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final topPadding = mediaQuery.padding.top;

    final screenW = size.width;
    final screenH = size.height;

    // Skala vertikal adaptif agar compact pada HP Android berlayar pendek (< 780dp)
    // dan pas tepat pada acuan penempatan dp di layar standar (~840dp - 915dp)
    final bool isCompact = screenH < 780;
    final double vScale = isCompact ? (screenH / 840.0) : 1.0;

    // Posisi vertikal elemen
    final double titleY = math.max(topPadding + 20.0, 135.0 * vScale);
    final double taglineY = titleY + (90.0 * vScale); // +- 225 dp
    final double masukY = titleY + (200.0 * vScale); // +- 335 dp
    final double daftarY = titleY + (271.0 * vScale); // +- 406 dp

    // Lebar tombol responsif (target 350 dp, aman di layar kecil)
    final double buttonWidth = math.min(350.0, screenW - 32.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // -------------------------------------------------------------------
          // 1. ILUSTRASI KELUARGA DI BAGIAN BAWAH
          // -------------------------------------------------------------------
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFamilyIllustration(size, vScale),
          ),

          // -------------------------------------------------------------------
          // 2. JUDUL PEDIA GROW (Baloo 2 Bold 50, "Pedia" #4B83D6, "Grow" #3CC3A6)
          // -------------------------------------------------------------------
          Positioned(
            top: titleY,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: math.min(screenW - 32, 260.0),
                child: _buildPediaGrowTitle(isCompact ? 44.0 : 50.0),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // 3. TAGLINE DI BAWAH JUDUL (Lato Regular 18)
          // -------------------------------------------------------------------
          Positioned(
            top: taglineY,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: math.min(screenW - 32, 280.0),
                child: Text(
                  'Pantau Pertumbuhan, Cegah Stunting\nUntuk Masa Depan',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: isCompact ? 15.5 : 18.0,
                    fontWeight: FontWeight.normal,
                    height: 1.35,
                    color: colorTextDark,
                  ),
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // 4. TOMBOL MASUK (350x52, #3985E7, Lato Bold 20 Putih)
          // -------------------------------------------------------------------
          Positioned(
            top: masukY,
            left: 0,
            right: 0,
            child: Center(
              child: _buildPrimaryButton(
                text: 'Masuk',
                width: buttonWidth,
                height: 52.0,
                backgroundColor: colorButtonPrimary,
                textColor: Colors.white,
                onPressed: () {
                  if (onLoginPressed != null) {
                    onLoginPressed!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  }
                },
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // 5. TOMBOL DAFTAR AKUN BARU (350x52, Putih border #3985E7, Lato Bold 20)
          // -------------------------------------------------------------------
          Positioned(
            top: daftarY,
            left: 0,
            right: 0,
            child: Center(
              child: _buildSecondaryButton(
                text: 'Daftar Akun Baru',
                width: buttonWidth,
                height: 52.0,
                borderColor: colorButtonPrimary,
                textColor: colorButtonPrimary,
                backgroundColor: Colors.white,
                onPressed: () {
                  if (onRegisterPressed != null) {
                    onRegisterPressed!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Teks "PediaGrow" menggunakan font Baloo 2 Bold 50 dengan 2 warna resmi.
  Widget _buildPediaGrowTitle(double fontSize) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Pedia',
            style: GoogleFonts.baloo2(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: colorPediaBlue, // #4B83D6
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: 'Grow',
            style: GoogleFonts.baloo2(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: colorGrowGreen, // #3CC3A6
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Tombol Masuk (dimensi 350x52, font Lato bold 20, warna #3985E7).
  Widget _buildPrimaryButton({
    required String text,
    required double width,
    required double height,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shadowColor: backgroundColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  /// Tombol Daftar Akun Baru (dimensi 350x52, font Lato bold 20, stroke #3985E7).
  Widget _buildSecondaryButton({
    required String text,
    required double width,
    required double height,
    required Color borderColor,
    required Color textColor,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 1.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  /// Ilustrasi Keluarga di bagian bawah layar (lebar 412, tinggi +- 292 dp).
  Widget _buildFamilyIllustration(Size size, double vScale) {
    final double illustH = math.min(292.0 * vScale, size.height * 0.35);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Image.asset(
        'assets/images/family_illustration.png',
        width: size.width,
        height: illustH,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/design_reference/splash_screen/8.png',
            width: size.width,
            height: illustH,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          );
        },
      ),
    );
  }
}
