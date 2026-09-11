import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../beranda/notifikasi_page.dart';
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
/// Ditampilkan setelah login berhasil, khusus untuk kondisi
/// pengguna yang BELUM memiliki profil anak.
///
/// Ketentuan Desain & Layout:
/// 1. Header Tetap (Pinned 56dp) di posisi Scaffold (tidak ikut scroll):
///    - Latar gradien biru (#5BA4F5) menyatu dengan area atas blue card.
///    - Teks "Hai Susanti" (Lato Bold 24, #FFFFFF).
///    - Lingkaran lonceng notifikasi (31×31, #FFFFFF) di sebelah kanan (12dp dari tepi).
/// 2. Konten Scrollable:
///    - Seluruh konten berada 12dp dari sisi kanan dan kiri layar.
///    - Card Biru Linear (Tinggi 290dp) dengan 2 elemen animasi elips dekoratif di kiri atas
///      (elips 10% dan 5% blur).
///    - Tulisan "Profil Anak" (Lato reguler 20, #FFFFFF).
///    - Card putih "MomDad belum punya profil anak" (340×120, radius 15, #FFFFFF)
///      overlapping di atas card biru (posisi bawah menjulur sekitar 340-360dp dari atas layar).
///      Berisi ilustrasi bayi, teks "MomDad belum punya profil anak" (Lato reguler 17, #7F7F7F),
///      dan tombol "+ Tambah Anak" (232×35, radius 10, #3985E7, Lato bold 16 #FFFFFF).
///    - Sisa konten berwarna putih (#FFFFFF) hingga bawah.
///    - 6 Card Menu (80×85, radius 10, #ECF6FF):
///      Berisi logo menu dan judul dengan font Lato reguler #000000:
///      (Cek stunting, Grafik pertumbuhan, Resep MPASI, Artikel Kesehatan, Lokasi fasyankes, Permainan).
///    - Card PediaGrow (340×115, radius 10, #ECF6FF):
///      Tulisan "Pedia" (#4B83D6) & "Grow" (#3CC3A6) Baloo 2 Bold 18,
///      Tagline "Pantau Pertumbuhan, Cegah Stunting untuk Masa Depan" Lato reguler 16 #000000.
///    - Ilustrasi penutup footer (kumpulan pohon, rumput, dan tenda) menempel di bagian bawah
///      konten sebelum Navigation Bar.
/// 3. Navigation Bar Tetap (Fixed 55dp, #F2EDED) di posisi Scaffold:
///    - Menu Beranda terpilih dengan bulatan putih dan ikon di dalamnya biru (#72A9F4).
///    - Menu Konsultasi, Riwayat Konsultasi, dan Profil Ibu.
class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage>
    with TickerProviderStateMixin {
  // Indeks navigasi bar yang aktif (0 = Beranda)
  int _selectedNavIndex = 0;

  // Animasi controller untuk 2 elips dekoratif
  late AnimationController _ellipseController;
  late Animation<double> _ellipseScale;

  @override
  void initState() {
    super.initState();
    _ellipseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _ellipseScale = Tween<double>(begin: 0.90, end: 1.05).animate(
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
      body: Column(
        children: [
          // -----------------------------------------------------------------
          // 1. HEADER TETAP DI POSISI SCAFFOLD (56dp)
          // -----------------------------------------------------------------
          _buildFixedHeader(context),

          // -----------------------------------------------------------------
          // 2. KONTEN YANG DAPAT DI-SCROLL
          // -----------------------------------------------------------------
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section Card Biru 1/3 Halaman (Height 290)
                  _buildBlueCardSection(context),

                  // Sisa Halaman Berwarna Putih (#FFFFFF)
                  _buildWhiteContentSection(context),
                ],
              ),
            ),
          ),

          // -----------------------------------------------------------------
          // 3. NAVIGATION BAR TETAP DI POSISI SCAFFOLD (55dp)
          // -----------------------------------------------------------------
          _buildFixedNavBar(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // HEADER TETAP DI POSISI SCAFFOLD (56dp)
  // ------------------------------------------------------------------
  Widget _buildFixedHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFF5BA4F5),
            Color(0xFF4B8FE9),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Nama Pengguna: "Hai Susanti" (Lato Bold 24, #FFFFFF)
                Text(
                  'Hai Susanti',
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                // Lingkaran di belakang lonceng (31×31, #FFFFFF, 12dp dari tepi kanan)
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
                          color: Color(0x1A000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF3985E7),
                      size: 19,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // CARD BIRU 1/3 HALAMAN (Height 290dp)
  // ------------------------------------------------------------------
  Widget _buildBlueCardSection(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 290,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5BA4F5),
            Color(0xFF3985E7),
            Color(0xFF2563EB),
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 2 Elemen Elips Animasi (kiri atas)
          _buildAnimatedEllipses(),

          // Tulisan "Profil Anak" (Lato reguler 20, #FFFFFF)
          Positioned(
            top: 20,
            left: 12,
            child: Text(
              'Profil Anak',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ),

          // Card MomDad belum memiliki profil anak (340×120, radius 15, #FFFFFF)
          // Menjulur ke bawah agar letak total mencapai sekitar 340-360 dp dari atas
          Positioned(
            bottom: -55,
            left: 0,
            right: 0,
            child: Center(
              child: _buildProfileCard(context),
            ),
          ),
        ],
      ),
    );
  }

  /// 2 Elemen elips animasi di sudut kiri atas
  /// - Elips 10% fill #FFFFFF dengan effect layer blur
  /// - Elips 5% fill #FFFFFF dengan effect layer blur lebih besar
  Widget _buildAnimatedEllipses() {
    return AnimatedBuilder(
      animation: _ellipseScale,
      builder: (context, child) {
        final scale = _ellipseScale.value;
        return Stack(
          children: [
            // Elips 2 (Ukuran lebih besar, 5% opacity, blur)
            Positioned(
              top: -85 * scale,
              left: -70 * scale,
              child: _BlurredEllipse(
                width: 220 * scale,
                height: 220 * scale,
                color: Colors.white.withValues(alpha: 0.05),
                blurSigma: 16,
              ),
            ),
            // Elips 1 (Ukuran lebih kecil, 10% opacity, blur)
            Positioned(
              top: -30 * scale,
              left: -25 * scale,
              child: _BlurredEllipse(
                width: 140 * scale,
                height: 140 * scale,
                color: Colors.white.withValues(alpha: 0.10),
                blurSigma: 10,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Card Putih "MomDad belum punya profil anak" (340×120, corner radius 15, #FFFFFF)
  Widget _buildProfileCard(BuildContext context) {
    return Container(
      width: 340,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 12),
          // Gambar Ilustrasi Bayi & Awan
          SizedBox(
            width: 74,
            height: 90,
            child: Image.asset(
              'assets/images/baby_cloud_illustration.jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.child_care_rounded,
                size: 56,
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
                // "MomDad belum punya profil anak" (Lato reguler 17, #7F7F7F)
                Text(
                  'MomDad belum punya profil anak',
                  style: GoogleFonts.lato(
                    fontSize: 17,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF7F7F7F),
                  ),
                ),
                const SizedBox(height: 10),
                // Card / Tombol "+ Tambah Anak" (232×35, radius 10, #3985E7)
                GestureDetector(
                  onTap: () => _navigateTo(const TambahAnakPage()),
                  child: Container(
                    width: 232,
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3985E7),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3985E7).withValues(alpha: 0.3),
                          blurRadius: 8,
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
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // AREA KONTEN PUTIH (Scrollable)
  // ------------------------------------------------------------------
  Widget _buildWhiteContentSection(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ruang kompensasi untuk card profil anak yang menjulur (55dp + padding)
          const SizedBox(height: 75),

          // -------------------------------------------------------------
          // 6 Card Menu Layanan Utama
          // -------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: _build6MenuGrid(context),
          ),

          const SizedBox(height: 24),

          // -------------------------------------------------------------
          // Card PediaGrow (340×115, radius 10, #ECF6FF)
          // -------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Center(child: _buildPediaGrowCard()),
          ),

          const SizedBox(height: 20),

          // -------------------------------------------------------------
          // Ilustrasi Penutup Footer (Pohon, Rumput, Tenda)
          // -------------------------------------------------------------
          _buildFooterIllustration(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // 6 CARD MENU (Grid 3 Kolom × 2 Baris)
  // ------------------------------------------------------------------
  Widget _build6MenuGrid(BuildContext context) {
    final menuItems = [
      _MenuData(
        title: 'Cek stunting',
        icon: Icons.monitor_weight_outlined,
        iconColor: const Color(0xFF4B83D6),
        onTap: () => _navigateTo(const PilihAnakPage()),
      ),
      _MenuData(
        title: 'Grafik pertumbuhan',
        icon: Icons.bar_chart_rounded,
        iconColor: const Color(0xFFEAA63C),
        onTap: () => _navigateTo(const PilihAnakGrafikPage()),
      ),
      _MenuData(
        title: 'Resep MPASI',
        icon: Icons.restaurant_rounded,
        iconColor: const Color(0xFFE08040),
        onTap: () => _navigateTo(const DaftarResepPage()),
      ),
      _MenuData(
        title: 'Artikel Kesehatan',
        icon: Icons.article_outlined,
        iconColor: const Color(0xFF4B83D6),
        onTap: () => _navigateTo(const DaftarArtikelPage()),
      ),
      _MenuData(
        title: 'Lokasi fasyankes',
        icon: Icons.location_on_outlined,
        iconColor: const Color(0xFF3CC3A6),
        onTap: () => _navigateTo(const LokasiFasyankesPage()),
      ),
      _MenuData(
        title: 'Permainan',
        icon: Icons.sports_esports_outlined,
        iconColor: const Color(0xFF7B61FF),
        onTap: () => _navigateTo(const GameMulaiPage()),
      ),
    ];

    return Column(
      children: [
        // Baris 1: 3 Menu Pertama
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: menuItems.sublist(0, 3).map(_buildMenuItem).toList(),
        ),
        const SizedBox(height: 16),
        // Baris 2: 3 Menu Berikutnya
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: menuItems.sublist(3, 6).map(_buildMenuItem).toList(),
        ),
      ],
    );
  }

  Widget _buildMenuItem(_MenuData item) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card Menu (dimensi weight 80, height 85, corner radius 10, #ECF6FF)
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
            // Di dalam card diisikan logo dari menu
            child: Icon(
              item.icon,
              size: 40,
              color: item.iconColor,
            ),
          ),
          const SizedBox(height: 6),
          // Judul Menu (font Lato reguler 18 / auto fit proporsional, #000000)
          SizedBox(
            width: 96,
            child: Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF000000),
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // CARD PEDIAGROW (340×115, corner radius 10, #ECF6FF)
  // ------------------------------------------------------------------
  Widget _buildPediaGrowCard() {
    return Container(
      width: 340,
      height: 115,
      decoration: BoxDecoration(
        color: const Color(0xFFECF6FF),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3985E7).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          // Gambar Ilustrasi Anak/Keluarga
          SizedBox(
            width: 88,
            height: 96,
            child: Image.asset(
              'assets/images/register_family.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.child_care_rounded,
                size: 56,
                color: Color(0xFF3985E7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Tulisan PediaGrow & Tagline
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama aplikasi PediaGrow (Baloo 2 Bold 18, #4B83D6 & #3CC3A6)
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
                // Tagline: "Pantau Pertumbuhan, Cegah Stunting untuk Masa Depan" (Lato reguler 16, #000000)
                Text(
                  'Pantau Pertumbuhan, Cegah Stunting untuk Masa Depan',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF000000),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // ILUSTRASI FOOTER (Pohon, Rumput, Tenda)
  // ------------------------------------------------------------------
  Widget _buildFooterIllustration() {
    return SizedBox(
      width: double.infinity,
      child: Image.asset(
        'assets/images/beranda_landscape_footer.jpg',
        fit: BoxFit.fitWidth,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 110,
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

  // ------------------------------------------------------------------
  // NAVIGATION BAR TETAP DI POSISI SCAFFOLD (55dp, #F2EDED)
  // ------------------------------------------------------------------
  Widget _buildFixedNavBar() {
    final navItems = [
      _NavigationData(icon: Icons.home_rounded, label: 'Beranda'),
      _NavigationData(icon: Icons.chat_bubble_outline_rounded, label: 'Konsultasi'),
      _NavigationData(icon: Icons.history_rounded, label: 'Riwayat Konsultasi'),
      _NavigationData(icon: Icons.person_outline_rounded, label: 'Profil Ibu'),
    ];

    return Container(
      width: double.infinity,
      height: 55,
      decoration: const BoxDecoration(
        color: Color(0xFFF2EDED),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (i) {
          final isSelected = i == _selectedNavIndex;
          return GestureDetector(
            onTap: () => _onNavTap(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 80,
              height: 55,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    // Menu Beranda aktif: bulatan putih dengan ikon biru di dalamnya (#72A9F4)
                    Container(
                      width: 40,
                      height: 40,
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
                        navItems[i].icon,
                        size: 24,
                        color: const Color(0xFF72A9F4),
                      ),
                    )
                  else ...[
                    Icon(
                      navItems[i].icon,
                      size: 22,
                      color: const Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      navItems[i].label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
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

// ------------------------------------------------------------------
// DATA MODELS & HELPER WIDGETS
// ------------------------------------------------------------------

class _MenuData {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuData({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });
}

class _NavigationData {
  final IconData icon;
  final String label;

  const _NavigationData({required this.icon, required this.label});
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
