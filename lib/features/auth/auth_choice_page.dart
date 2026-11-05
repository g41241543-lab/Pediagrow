import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_page.dart';
import 'register_page.dart';

/// Halaman pilihan autentikasi (Masuk / Daftar Akun Baru).
///
/// Memenuhi tata letak resmi PediaGrow dengan estetika modern, elegan, dan luxury:
/// 1. Judul "PediaGrow" (Baloo 2 Bold, "Pedia" #4B83D6, "Grow" #3CC3A6).
/// 2. Tagline edukatif (Lato regular 18 / 15.5 pada layar pendek).
/// 3. Tombol "Masuk" (350x52, #3985E7, Lato bold 20 putih, dengan luxury soft shadow).
/// 4. Tombol "Daftar Akun Baru" (350x52, border #3985E7, Lato bold 20 biru).
/// 5. Ilustrasi keluarga PNG Ultra-HD adaptif Light Mode & Dark Mode:
///    - Light Mode: `family_illustration.png` (cerah, awan lembut, bukit rumput segar).
///    - Dark Mode: `family_illustration_dark.png` (nuansa malam teduh, bukit rumput malam, dan langit berbintang).
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
  static const Color colorTextDark = Color(0xFF1A2228); // Tagline text

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B1014) : Colors.white;
    final taglineColor = isDark ? const Color(0xFFD1D7DB) : colorTextDark;
    final secondaryBtnBg = isDark ? const Color(0xFF1A2228) : Colors.white;

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

    final double daftarBottom = daftarY + 52.0;
    final double availableIllustHeight =
        screenH - daftarBottom - 16.0 - mediaQuery.padding.bottom;

    final systemOverlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: bgColor,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlay,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // -------------------------------------------------------------------
            // 1. ILUSTRASI KELUARGA (PNG Ultra-HD Adaptif Light/Dark Mode)
            // -------------------------------------------------------------------
            Positioned(
              left: 0,
              right: 0,
              bottom: -6.0 * vScale,
              child: _buildFamilyIllustration(
                size,
                vScale,
                isDark,
                availableIllustHeight,
              ),
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
                    color: taglineColor,
                  ),
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // 4. TOMBOL MASUK (350x52, #3985E7, Lato Bold 20 Putih dengan Shadow Halus)
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
                isDark: isDark,
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
          // 5. TOMBOL DAFTAR AKUN BARU (350x52, Border #3985E7, Lato Bold 20)
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
                backgroundColor: secondaryBtnBg,
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
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: isDark ? 0.35 : 0.28),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
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

  /// Ilustrasi Keluarga di bagian bawah layar (PNG Ultra-HD adaptif Light & Dark Mode).
  ///
  /// - Light Mode: Memakai `family_illustration.png` (HD, cerah, rumput segar, awan lembut).
  /// - Dark Mode: Memakai `family_illustration_dark.png` (HD, nuansa malam, rumput malam, dan langit berbintang).
  /// - ShaderMask: Memastikan bagian atas ilustrasi memudar secara lembut (feathered fade)
  ///   sehingga menyatu 100% mulus dengan warna latar belakang tanpa ada garis potong kotak.
  Widget _buildFamilyIllustration(
    Size size,
    double vScale,
    bool isDark,
    double availableHeight,
  ) {
    final double maxH = math.max(280.0, availableHeight + 6.0 * vScale);
    final double illustH = math.min(360.0 * vScale, maxH);

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Color(0x0D000000), // 5%
            Color(0x2B000000), // 17%
            Color(0x66000000), // 40%
            Color(0xB3000000), // 70%
            Color(0xF2000000), // 95%
            Colors.black,      // 100%
          ],
          stops: [0.0, 0.05, 0.11, 0.18, 0.26, 0.34, 0.42], // Multi-stop ease-out fade tanpa garis batas
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Image.asset(
          isDark
              ? 'assets/images/family_illustration_dark.png'
              : 'assets/images/family_illustration.png',
          width: size.width,
          height: illustH,
          fit: BoxFit.fitWidth,
          alignment: Alignment.bottomCenter,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/family_illustration.png',
              width: size.width,
              height: illustH,
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
            );
          },
        ),
      ),
    );
  }
}
