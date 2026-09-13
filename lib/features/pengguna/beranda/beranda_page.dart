import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'notifikasi_page.dart';
import '../profil_anak/tambah_anak_page.dart';
import '../cek_stunting/pilih_anak_page.dart';
import '../grafik_pertumbuhan/pilih_anak_grafik_page.dart';
import '../mpasi/daftar_resep_page.dart';
import '../artikel/daftar_artikel_page.dart';
import '../fasyankes/lokasi_fasyankes_page.dart';
import '../game_edukasi/game_mulai_page.dart';
import '../konsultasi/daftar_dokter_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_page.dart';
import '../profil/menu_profil_page.dart';
import '../../../shared/widgets/illustration_forest_footer.dart';

/// Halaman Beranda Pengguna PediaGrow.
///
/// Ditampilkan setelah login berhasil untuk pengguna yang BELUM memiliki profil anak.
/// Halaman scrollable secara penuh dengan Navigation Bar tetap (fixed di Scaffold).
class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage>
    with SingleTickerProviderStateMixin {
  int _selectedNavIndex = 0;

  late AnimationController _ellipseController;
  late Animation<double> _ellipsePulse;

  @override
  void initState() {
    super.initState();
    _ellipseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _ellipsePulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _ellipseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ellipseController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    switch (index) {
      case 0:
        setState(() => _selectedNavIndex = 0);
        break;
      case 1:
        _navigateTo(const DaftarDokterPage());
        break;
      case 2:
        _navigateTo(const DaftarRiwayatPage());
        break;
      case 3:
        _navigateTo(const MenuProfilPage());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------------
            // 1. AREA BIRU SEAMLESS (Header + "Profil Anak" + Card MomDad)
            //    Satu container gradient menerus dari paling atas layar
            // -------------------------------------------------------------
            _buildSeamlessBlueArea(context),

            // -------------------------------------------------------------
            // 2. KONTEN PUTIH (6 Card Menu & Card PediaGrow)
            // -------------------------------------------------------------
            _buildWhiteContentSection(context),

            // -------------------------------------------------------------
            // 3. ILUSTRASI PENUTUP FOOTER (Full-Bleed, Menempel ke Nav Bar)
            // -------------------------------------------------------------
            _buildFooterIllustration(),
          ],
        ),
      ),
      // Navigation Bar tetap di posisi Scaffold
      bottomNavigationBar: _buildFixedNavBar(),
    );
  }

  // ===================================================================
  // 1. AREA BIRU SEAMLESS
  // Gradient menerus dari atas layar (termasuk Safe Area).
  // Total tinggi sekitar 270-290dp.
  // ===================================================================
  Widget _buildSeamlessBlueArea(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5BA4F5), // Biru lebih terang di kiri-atas
            Color(0xFF4592F0),
            Color(0xFF2872E5), // Biru lebih pekat di kanan-bawah
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // -----------------------------------------------------------
          // DIRECT NON-POSITIONED CHILD PERTAMA: Column konten utama
          // Memberi constraint ukuran alami tanpa loose constraint issue
          // -----------------------------------------------------------
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Safe area top + Header (56dp)
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // "Hai, Susanti" (Lato Bold 24, #FFFFFF)
                        Text(
                          'Hai, Susanti',
                          style: GoogleFonts.lato(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        // Lingkaran Notifikasi (31×31, #FFFFFF, 12dp dari kanan)
                        GestureDetector(
                          onTap: () => _navigateTo(const NotifikasiPage()),
                          child: Container(
                            width: 31,
                            height: 31,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x1F000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF1E293B),
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Tulisan "Profil Anak" (Lato Regular 20, #FFFFFF)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'Profil Anak',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
              ),

              // Jarak margin-top dari teks "Profil Anak" ke card: 16dp
              const SizedBox(height: 16),

              // Card MomDad (340×120, radius 15, #FFFFFF)
              Center(
                child: _buildMomDadCard(context),
              ),

              // Jarak ±20-30dp dari bottom card MomDad ke batas transisi biru→putih
              const SizedBox(height: 24),
            ],
          ),

          // -----------------------------------------------------------
          // DEKORASI: 2 Elips Blur di Kiri Atas
          // -----------------------------------------------------------
          AnimatedBuilder(
            animation: _ellipsePulse,
            builder: (context, child) {
              final scale = _ellipsePulse.value;
              return Positioned(
                top: -45 * scale,
                left: -45 * scale,
                child: IgnorePointer(
                  child: _BlurredEllipse(
                    width: 175 * scale,
                    height: 175 * scale,
                    color: Colors.white.withValues(alpha: 0.05),
                    blurSigma: 22,
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _ellipsePulse,
            builder: (context, child) {
              final scale = _ellipsePulse.value;
              return Positioned(
                top: -15 * scale,
                left: -15 * scale,
                child: IgnorePointer(
                  child: _BlurredEllipse(
                    width: 115 * scale,
                    height: 115 * scale,
                    color: Colors.white.withValues(alpha: 0.10),
                    blurSigma: 14,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // CARD MOMDAD (Belum Punya Profil Anak)
  // Dimensi: width 340 x height 120, warna #FFFFFF, corner radius 15
  // ===================================================================
  Widget _buildMomDadCard(BuildContext context) {
    return Container(
      width: 340,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ilustrasi Bayi Tidur di Atas Awan
          SizedBox(
            width: 72,
            height: 72,
            child: Image.asset(
              'assets/images/baby_cloud_illustration.jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.child_friendly_rounded,
                size: 54,
                color: Color(0xFF3985E7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Teks Informasi & Tombol Tambah Anak
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "MomDad belum punya profil anak" (Lato Regular 17, #7F7F7F)
                Text(
                  'MomDad belum punya profil anak',
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF7F7F7F),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Tombol "+ Tambah Anak" (width 232 x height 35, radius 10, #3985E7)
                GestureDetector(
                  onTap: () => _navigateTo(const TambahAnakPage()),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 232),
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3985E7),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3985E7).withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+ Tambah Anak',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // 2. KONTEN PUTIH (6 Card Menu & Card PediaGrow)
  // Margin 12dp dari sisi kiri & kanan layar
  // ===================================================================
  Widget _buildWhiteContentSection(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      child: Column(
        children: [
          // 6 Card Menu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: _build6MenuGrid(context),
          ),

          const SizedBox(height: 24),

          // Card PediaGrow (340×115, radius 10, #ECF6FF)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Center(
              child: _buildPediaGrowCard(),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // 6 CARD MENU
  // Warna #ECF6FF, dimensi width 80 x height 85, corner radius 10
  // ===================================================================
  Widget _build6MenuGrid(BuildContext context) {
    return Column(
      children: [
        // Baris 1: Cek Stunting, Grafik Pertumbuhan, Resep MPASI
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMenuItem(
              title: 'Cek\nStunting',
              iconWidget: const _ScaleIcon(),
              onTap: () => _navigateTo(const PilihAnakPage()),
            ),
            _buildMenuItem(
              title: 'Grafik\nPertumbuhan',
              iconWidget: const _BarChartIcon(),
              onTap: () => _navigateTo(const PilihAnakGrafikPage()),
            ),
            _buildMenuItem(
              title: 'Resep\nMPASI',
              iconWidget: const _FoodJarIcon(),
              onTap: () => _navigateTo(const DaftarResepPage()),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Baris 2: Artikel Kesehatan, Lokasi Fasyankes, Permainan
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMenuItem(
              title: 'Artikel\nKesehatan',
              iconWidget: const _HealthCertIcon(),
              onTap: () => _navigateTo(const DaftarArtikelPage()),
            ),
            _buildMenuItem(
              title: 'Lokasi\nFasyankes',
              iconWidget: const _MapPinIcon(),
              onTap: () => _navigateTo(const LokasiFasyankesPage()),
            ),
            _buildMenuItem(
              title: 'Permainan\n',
              iconWidget: const _GameScreenIcon(),
              onTap: () => _navigateTo(const GameMulaiPage()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String title,
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 95,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Card Menu: 80×85, radius 10, #ECF6FF
            Container(
              width: 80,
              height: 85,
              decoration: BoxDecoration(
                color: const Color(0xFFECF6FF),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3985E7).withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: iconWidget,
            ),
            const SizedBox(height: 8),
            // Judul Menu (Lato Regular 16-18, #000000)
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 15,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF000000),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // CARD PEDIAGROW
  // Warna #ECF6FF, dimensi width 340 x height 115, corner radius 10
  // Sisi kiri: ilustrasi bayi bermain dengan mainan
  // Sisi kanan: "PediaGrow" + Tagline
  // ===================================================================
  Widget _buildPediaGrowCard() {
    return Container(
      width: 340,
      height: 115,
      decoration: BoxDecoration(
        color: const Color(0xFFECF6FF),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3985E7).withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ilustrasi Bayi Bermain Mainan
          SizedBox(
            width: 84,
            height: 94,
            child: Image.asset(
              'assets/images/baby_cloud_illustration.jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.toys_outlined,
                size: 50,
                color: Color(0xFF3985E7),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Teks PediaGrow & Tagline
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Pedia" (#4B83D6) & "Grow" (#3CC3A6) Baloo 2 Bold 18
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Pedia',
                        style: GoogleFonts.baloo2(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4B83D6),
                        ),
                      ),
                      TextSpan(
                        text: 'Grow',
                        style: GoogleFonts.baloo2(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3CC3A6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Tagline "Pantau Pertumbuhan, Cegah Stunting untuk Masa Depan" (Lato Regular 16, #000000)
                Text(
                  'Pantau Pertumbuhan,\nCegah Stunting untuk Masa Depan',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF000000),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // 3. ILUSTRASI FOOTER FULL-BLEED
  // 100% width layar, tanpa margin/padding, menempel langsung ke Nav Bar
  // ===================================================================
  Widget _buildFooterIllustration() {
    return const IllustrationForestFooter(
      fit: BoxFit.fitWidth,
    );
  }

  // ===================================================================
  // 4. NAVIGATION BAR (Fixed di Scaffold)
  // Warna #F2EDED, tinggi 68dp (range 65-70dp)
  // Beranda aktif: bulatan putih dengan ikon biru #72A9F4 di dalamnya
  // ===================================================================
  Widget _buildFixedNavBar() {
    final navItems = [
      _NavData(icon: Icons.home_rounded, label: 'Beranda'),
      _NavData(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
      _NavData(icon: Icons.manage_search_rounded, label: 'Riwayat Konsultasi'),
      _NavData(icon: Icons.person_outline_rounded, label: 'Profil Ibu'),
    ];

    return Container(
      width: double.infinity,
      height: 68,
      decoration: const BoxDecoration(
        color: Color(0xFFF2EDED),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(navItems.length, (i) {
          final isSelected = i == _selectedNavIndex;
          final item = navItems[i];

          return GestureDetector(
            onTap: () => _onNavTap(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 80,
              height: 68,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected) ...[
                    // State aktif: lingkaran putih dengan icon biru #72A9F4
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        item.icon,
                        size: 24,
                        color: const Color(0xFF72A9F4),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ] else ...[
                    // State tidak aktif: icon & label abu-abu #9E9E9E
                    Icon(
                      item.icon,
                      size: 24,
                      color: const Color(0xFF9E9E9E),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// =====================================================================
// DATA MODELS & HELPER WIDGETS
// =====================================================================

class _NavData {
  final IconData icon;
  final String label;

  const _NavData({required this.icon, required this.label});
}

/// Widget elips dekoratif dengan efek Gaussian blur
class _BlurredEllipse extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double blurSigma;

  const _BlurredEllipse({
    required this.width,
    required this.height,
    required this.color,
    required this.blurSigma,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _BlurredEllipsePainter(color: color, blurSigma: blurSigma),
    );
  }
}

class _BlurredEllipsePainter extends CustomPainter {
  final Color color;
  final double blurSigma;

  const _BlurredEllipsePainter({
    required this.color,
    required this.blurSigma,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    canvas.drawOval(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BlurredEllipsePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.blurSigma != blurSigma;
}

// =====================================================================
// CUSTOM PAINTER ICONS (6 MENU)
// Sesuai persis dengan ilustrasi referensi desain
// =====================================================================

/// 1. Ikon Cek Stunting: Timbangan (Balance Scale), biru
class _ScaleIcon extends StatelessWidget {
  const _ScaleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 40),
      painter: _ScaleIconPainter(),
    );
  }
}

class _ScaleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF72A9F4)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Tiang Tengah & Alas
    canvas.drawLine(Offset(w * 0.5, h * 0.15), Offset(w * 0.5, h * 0.88), strokePaint);
    canvas.drawLine(Offset(w * 0.35, h * 0.88), Offset(w * 0.65, h * 0.88), strokePaint);

    // Palang Horizontal Atas
    canvas.drawLine(Offset(w * 0.18, h * 0.22), Offset(w * 0.82, h * 0.22), strokePaint);

    // Titik tumpu tengah atas
    canvas.drawCircle(Offset(w * 0.5, h * 0.18), 3, strokePaint..style = PaintingStyle.fill);
    strokePaint.style = PaintingStyle.stroke;

    // Tali kiri
    canvas.drawLine(Offset(w * 0.18, h * 0.22), Offset(w * 0.10, h * 0.48), strokePaint);
    canvas.drawLine(Offset(w * 0.18, h * 0.22), Offset(w * 0.28, h * 0.48), strokePaint);

    // Piringan kiri (fill + stroke)
    final leftPan = Path()
      ..moveTo(w * 0.08, h * 0.48)
      ..quadraticBezierTo(w * 0.19, h * 0.62, w * 0.30, h * 0.48)
      ..close();
    canvas.drawPath(leftPan, fillPaint);
    canvas.drawPath(leftPan, strokePaint);

    // Tali kanan
    canvas.drawLine(Offset(w * 0.82, h * 0.22), Offset(w * 0.72, h * 0.48), strokePaint);
    canvas.drawLine(Offset(w * 0.82, h * 0.22), Offset(w * 0.90, h * 0.48), strokePaint);

    // Piringan kanan (fill + stroke)
    final rightPan = Path()
      ..moveTo(w * 0.70, h * 0.48)
      ..quadraticBezierTo(w * 0.81, h * 0.62, w * 0.92, h * 0.48)
      ..close();
    canvas.drawPath(rightPan, fillPaint);
    canvas.drawPath(rightPan, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. Ikon Grafik Pertumbuhan: Bar chart 3 batang warna-warni (kuning, biru, tosca/hijau)
class _BarChartIcon extends StatelessWidget {
  const _BarChartIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 40),
      painter: _BarChartIconPainter(),
    );
  }
}

class _BarChartIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Sumbu X & Sumbu Y
    canvas.drawLine(Offset(w * 0.15, h * 0.15), Offset(w * 0.15, h * 0.85), strokePaint);
    canvas.drawLine(Offset(w * 0.15, h * 0.85), Offset(w * 0.88, h * 0.85), strokePaint);

    // Batang 1: Kuning
    final bar1Rect = Rect.fromLTWH(w * 0.25, h * 0.50, w * 0.16, h * 0.35);
    final fill1 = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawRect(bar1Rect, fill1);
    canvas.drawRect(bar1Rect, strokePaint);

    // Batang 2: Biru/Ungu
    final bar2Rect = Rect.fromLTWH(w * 0.45, h * 0.60, w * 0.16, h * 0.25);
    final fill2 = Paint()..color = const Color(0xFF6366F1);
    canvas.drawRect(bar2Rect, fill2);
    canvas.drawRect(bar2Rect, strokePaint);

    // Batang 3: Tosca/Hijau
    final bar3Rect = Rect.fromLTWH(w * 0.65, h * 0.32, w * 0.16, h * 0.53);
    final fill3 = Paint()..color = const Color(0xFF06B6D4);
    canvas.drawRect(bar3Rect, fill3);
    canvas.drawRect(bar3Rect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. Ikon Resep MPASI: Toples/jar makanan bayi dengan sendok, oranye
class _FoodJarIcon extends StatelessWidget {
  const _FoodJarIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 40),
      painter: _FoodJarIconPainter(),
    );
  }
}

class _FoodJarIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()..color = const Color(0xFFFDBA74);
    final innerPaint = Paint()..color = const Color(0xFFFED7AA);

    final w = size.width;
    final h = size.height;

    // Tutup toples
    final lidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, h * 0.16, w * 0.42, h * 0.10),
      const Radius.circular(3),
    );
    canvas.drawRRect(lidRect, strokePaint);

    // Badan toples
    final jarRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.26, w * 0.50, h * 0.58),
      const Radius.circular(8),
    );
    canvas.drawRRect(jarRect, fillPaint);
    canvas.drawRRect(jarRect, strokePaint);

    // Label di toples
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.40, w * 0.38, h * 0.26),
      const Radius.circular(4),
    );
    canvas.drawRRect(labelRect, innerPaint);
    canvas.drawRRect(labelRect, strokePaint);

    // Sendok di samping kanan
    final spoonHead = Rect.fromLTWH(w * 0.74, h * 0.22, w * 0.14, h * 0.22);
    canvas.drawOval(spoonHead, Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawOval(spoonHead, strokePaint);
    canvas.drawLine(Offset(w * 0.81, h * 0.44), Offset(w * 0.81, h * 0.84), strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. Ikon Artikel Kesehatan: Sertifikat/piagam dengan simbol palang kesehatan (+)
class _HealthCertIcon extends StatelessWidget {
  const _HealthCertIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 40),
      painter: _HealthCertIconPainter(),
    );
  }
}

class _HealthCertIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final frameFill = Paint()..color = const Color(0xFFFEF08A);
    final blueFill = Paint()..color = const Color(0xFF38BDF8);

    final w = size.width;
    final h = size.height;

    // Bingkai sertifikat
    final certRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.64, h * 0.64),
      const Radius.circular(6),
    );
    canvas.drawRRect(certRect, frameFill);
    canvas.drawRRect(certRect, strokePaint);

    // 4 Corner tabs
    const tabSize = 5.0;
    canvas.drawRect(Rect.fromLTWH(w * 0.14, h * 0.14, tabSize, tabSize), strokePaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.82 - tabSize, h * 0.14, tabSize, tabSize), strokePaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.14, h * 0.82 - tabSize, tabSize, tabSize), strokePaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.82 - tabSize, h * 0.82 - tabSize, tabSize, tabSize), strokePaint);

    // Lambang tameng / palang di tengah
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.32, h * 0.32, w * 0.36, h * 0.36),
      const Radius.circular(4),
    );
    canvas.drawRRect(badgeRect, blueFill);
    canvas.drawRRect(badgeRect, strokePaint);

    // Palang (+) putih
    final plusPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.5, h * 0.38), Offset(w * 0.5, h * 0.62), plusPaint);
    canvas.drawLine(Offset(w * 0.38, h * 0.5), Offset(w * 0.62, h * 0.5), plusPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5. Ikon Lokasi Fasyankes: Peta terlipat dengan pin lokasi merah
class _MapPinIcon extends StatelessWidget {
  const _MapPinIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 40),
      painter: _MapPinIconPainter(),
    );
  }
}

class _MapPinIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final mapFill = Paint()..color = const Color(0xFFBAE6FD);
    final pinFill = Paint()..color = const Color(0xFFEF4444);

    final w = size.width;
    final h = size.height;

    // Peta terlipat 3 panel
    final mapPath = Path()
      ..moveTo(w * 0.12, h * 0.38)
      ..lineTo(w * 0.38, h * 0.30)
      ..lineTo(w * 0.64, h * 0.38)
      ..lineTo(w * 0.88, h * 0.30)
      ..lineTo(w * 0.88, h * 0.76)
      ..lineTo(w * 0.64, h * 0.84)
      ..lineTo(w * 0.38, h * 0.76)
      ..lineTo(w * 0.12, h * 0.84)
      ..close();

    canvas.drawPath(mapPath, mapFill);
    canvas.drawPath(mapPath, strokePaint);

    // Garis lipatan vertikal
    canvas.drawLine(Offset(w * 0.38, h * 0.30), Offset(w * 0.38, h * 0.76), strokePaint);
    canvas.drawLine(Offset(w * 0.64, h * 0.38), Offset(w * 0.64, h * 0.84), strokePaint);

    // Pin Lokasi Merah di panel tengah
    final pinCenter = Offset(w * 0.52, h * 0.32);
    final pinHead = Path()
      ..addOval(Rect.fromCircle(center: pinCenter, radius: 7.5))
      ..moveTo(w * 0.44, h * 0.34)
      ..lineTo(w * 0.52, h * 0.54)
      ..lineTo(w * 0.60, h * 0.34)
      ..close();

    canvas.drawPath(pinHead, pinFill);
    canvas.drawPath(pinHead, strokePaint);

    // Titik putih di dalam pin
    canvas.drawCircle(pinCenter, 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 6. Ikon Permainan: Layar monitor/tablet dengan simbol gear/kursor
class _GameScreenIcon extends StatelessWidget {
  const _GameScreenIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 40),
      painter: _GameScreenIconPainter(),
    );
  }
}

class _GameScreenIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final screenFill = Paint()..color = const Color(0xFFBAE6FD);
    final sunFill = Paint()..color = const Color(0xFFFBBF24);

    final w = size.width;
    final h = size.height;

    // Bingkai monitor
    final monitorRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, h * 0.16, w * 0.56, h * 0.56),
      const Radius.circular(5),
    );
    canvas.drawRRect(monitorRect, screenFill);
    canvas.drawRRect(monitorRect, strokePaint);

    // Stand / kaki monitor
    canvas.drawLine(Offset(w * 0.48, h * 0.72), Offset(w * 0.48, h * 0.84), strokePaint);
    canvas.drawLine(Offset(w * 0.32, h * 0.84), Offset(w * 0.64, h * 0.84), strokePaint);

    // Gambar di dalam layar: matahari & bukit
    canvas.drawCircle(Offset(w * 0.60, h * 0.30), 4, sunFill);
    final hillPath = Path()
      ..moveTo(w * 0.22, h * 0.62)
      ..lineTo(w * 0.38, h * 0.46)
      ..lineTo(w * 0.52, h * 0.58)
      ..lineTo(w * 0.64, h * 0.48)
      ..lineTo(w * 0.74, h * 0.62)
      ..close();
    canvas.drawPath(hillPath, Paint()..color = const Color(0xFF34D399));
    canvas.drawPath(hillPath, strokePaint..strokeWidth = 1.5);
    strokePaint.strokeWidth = 2.2;

    // Kursor Mouse di kanan bawah
    final cursor = Path()
      ..moveTo(w * 0.66, h * 0.50)
      ..lineTo(w * 0.88, h * 0.66)
      ..lineTo(w * 0.78, h * 0.68)
      ..lineTo(w * 0.84, h * 0.84)
      ..lineTo(w * 0.76, h * 0.86)
      ..lineTo(w * 0.70, h * 0.70)
      ..lineTo(w * 0.62, h * 0.74)
      ..close();

    canvas.drawPath(cursor, Paint()..color = const Color(0xFF1E293B));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
