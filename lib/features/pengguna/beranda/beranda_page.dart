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
    if (page is PilihAnakPage) {
      PilihAnakPage.show(context, children: page.children);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
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

              // Card MomDad (margin 12dp horizontal, radius 15, #FFFFFF)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
  // Dimensi: lebar penuh sejajar margin 12dp x height 120, warna #FFFFFF, corner radius 15
  // ===================================================================
  Widget _buildMomDadCard(BuildContext context) {
    return Container(
      width: double.infinity,
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
                // "Mom Dad belum punya profil anak" (Lato Regular 15, #7F7F7F)
                Text(
                  'Mom Dad belum punya profil anak',
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
                          color: const Color(0xFF3985E7)
                              .withValues(alpha: 0.25),
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
          // 6 Card Menu (lebar penuh sejajar margin 12dp)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: _build6MenuGrid(context),
          ),

          const SizedBox(height: 24),

          // Card PediaGrow (lebar penuh identik dengan Card MomDad & Menu, margin 12dp)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: _buildPediaGrowCard(),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // 6 CARD MENU
  // Warna #ECF6FF, dimensi 3 kolom sejajar presisi, corner radius 10
  // ===================================================================
  Widget _build6MenuGrid(BuildContext context) {
    return Column(
      children: [
        // Baris 1: Cek Stunting, Grafik Pertumbuhan, Resep MPASI
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMenuItem(
                title: 'Cek\nStunting',
                imageAsset: 'assets/images/cek_stunting_logo.png',
                onTap: () => _navigateTo(const PilihAnakPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Grafik\nPertumbuhan',
                imageAsset: 'assets/images/grafik_pertumbuhan_logo.png',
                onTap: () => _navigateTo(const PilihAnakGrafikPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Resep\nMPASI',
                imageAsset: 'assets/images/resep_mpasi_logo.png',
                onTap: () => _navigateTo(const DaftarResepPage()),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Baris 2: Artikel Kesehatan, Lokasi Fasyankes, Permainan
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMenuItem(
                title: 'Artikel\nKesehatan',
                imageAsset: 'assets/images/artikel_kesehatan_logo.png',
                onTap: () => _navigateTo(const DaftarArtikelPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Lokasi\nFasyankes',
                imageAsset: 'assets/images/lokasi_fasyankes_logo.png',
                onTap: () => _navigateTo(const LokasiFasyankesPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Permainan\n',
                imageAsset: 'assets/images/permainan_logo.png',
                onTap: () => _navigateTo(const GameMulaiPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String imageAsset,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Menu: fills available width of this column!
          Container(
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
            child: Image.asset(imageAsset, height: 48, fit: BoxFit.contain),
          ),
          const SizedBox(height: 8),
          // Judul Menu (Lato Regular 14, #000000)
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF000000),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // CARD PEDIAGROW
  // Warna #ECF6FF, dimensi lebar penuh (margin 12dp) x height 115, corner radius 10
  // Sisi kiri: ilustrasi bayi pediagrow
  // Sisi kanan: "PediaGrow" + Tagline
  // ===================================================================
  Widget _buildPediaGrowCard() {
    return Container(
      width: double.infinity,
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
          // Ilustrasi Bayi PediaGrow (gambar 7)
          SizedBox(
            width: 84,
            height: 94,
            child: Image.asset(
              'assets/images/bayi_pediagrow_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.child_care_rounded,
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
    return SizedBox(
      width: double.infinity,
      child: Image.asset(
        'assets/images/beranda_landscape_footer.jpg',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.bottomCenter,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 100,
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
                    Icon(item.icon, size: 24, color: const Color(0xFF9E9E9E)),
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

  const _BlurredEllipsePainter({required this.color, required this.blurSigma});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    canvas.drawOval(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _BlurredEllipsePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.blurSigma != blurSigma;
}
