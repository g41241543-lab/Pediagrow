import 'dart:math' as math;

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
/// Layout:
/// - Header pinned 56dp (gradient biru): "Hai Susanti" + ikon notifikasi
/// - Blue gradient card (≈290dp) dengan card profil anak di atasnya
/// - Konten putih scrollable: 6 menu + card PediaGrow + ilustrasi footer
/// - Navigation Bar fixed (55dp, #F2EDED)
class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage>
    with TickerProviderStateMixin {
  // Indeks navigasi bar yang aktif (0 = Beranda)
  int _selectedNavIndex = 0;

  // Animasi controller untuk dekorasi elips
  late AnimationController _ellipseController;
  late Animation<double> _ellipsePulse;

  @override
  void initState() {
    super.initState();
    _ellipseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _ellipsePulse = Tween<double>(begin: 0.85, end: 1.0).animate(
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

  // ------------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      // Body: Stack agar Blue Card + konten white bisa overlap sedikit
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ------------------------------------------------
                  // BLUE GRADIENT SECTION (header + card)
                  // ------------------------------------------------
                  _buildBlueSection(context),

                  // ------------------------------------------------
                  // WHITE CONTENT SECTION
                  // ------------------------------------------------
                  _buildWhiteSection(context),
                ],
              ),
            ),
          ),

          // ------------------------------------------------
          // NAVIGATION BAR (fixed di bawah)
          // ------------------------------------------------
          _buildNavBar(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // BLUE GRADIENT SECTION
  // ------------------------------------------------------------------
  Widget _buildBlueSection(BuildContext context) {
    return Container(
      width: double.infinity,
      // Total: header 56dp + padding + card profil anak yang "menjulur keluar"
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
          // --- Dekorasi Elips Animasi (kiri atas) ---
          _buildAnimatedEllipses(),

          // --- HEADER (56dp) ---
          _buildHeader(context),

          // --- Label "Profil Anak" ---
          Positioned(
            top: 56 + 12,
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

          // --- Card Putih "MomDad belum punya profil anak" ---
          // Diposisikan menempel di bagian bawah blue section (overlap ke bawah)
          Positioned(
            bottom: -60, // menjulur ke area putih di bawahnya
            left: 0,
            right: 0,
            child: Center(child: _buildProfileCard(context)),
          ),
        ],
      ),
    );
  }

  /// Dua elips dekoratif di sudut kiri atas dengan animasi pulse.
  Widget _buildAnimatedEllipses() {
    return AnimatedBuilder(
      animation: _ellipsePulse,
      builder: (context, child) {
        return Stack(
          children: [
            // Elips besar (opacity 5%, blur)
            Positioned(
              top: -70 * _ellipsePulse.value,
              left: -60 * _ellipsePulse.value,
              child: _Ellipse(
                width: 200 * _ellipsePulse.value,
                height: 200 * _ellipsePulse.value,
                color: Colors.white.withOpacity(0.05),
                blurSigma: 12,
              ),
            ),
            // Elips kecil (opacity 10%, blur)
            Positioned(
              top: -30,
              left: -20,
              child: _Ellipse(
                width: 130 * _ellipsePulse.value,
                height: 130 * _ellipsePulse.value,
                color: Colors.white.withOpacity(0.10),
                blurSigma: 8,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Header 56dp: nama pengguna + ikon notifikasi.
  Widget _buildHeader(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Nama pengguna
                Text(
                  'Hai Susanti',
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                // Lingkaran notifikasi (31x31, putih, 12dp dari kanan)
                GestureDetector(
                  onTap: () => _navigateTo(const NotifikasiPage()),
                  child: Container(
                    width: 31,
                    height: 31,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF3985E7),
                      size: 18,
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

  /// Card putih (340×120, radius 15) berisi teks + tombol tambah anak.
  Widget _buildProfileCard(BuildContext context) {
    return Container(
      width: 340,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          // Ilustrasi bayi
          SizedBox(
            width: 72,
            height: 88,
            child: Image.asset(
              'assets/images/baby_cloud_illustration.jpg',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.child_care,
                size: 56,
                color: Color(0xFF3985E7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Teks + tombol
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MomDad belum punya profil anak',
                  style: GoogleFonts.lato(
                    fontSize: 17,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF7F7F7F),
                  ),
                ),
                const SizedBox(height: 10),
                // Tombol + Tambah Anak (232×35, radius 10)
                GestureDetector(
                  onTap: () => _navigateTo(const TambahAnakPage()),
                  child: Container(
                    width: 232,
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3985E7),
                      borderRadius: BorderRadius.circular(10),
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
  // WHITE CONTENT SECTION
  // ------------------------------------------------------------------
  Widget _buildWhiteSection(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ruang untuk card profil yang menjulur (60dp overlap)
          const SizedBox(height: 72),

          // --- 6 Menu Cards (grid 3x2) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: _buildMenuGrid(context),
          ),

          const SizedBox(height: 20),

          // --- Card PediaGrow ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: _buildPediaGrowCard(),
          ),

          const SizedBox(height: 16),

          // --- Ilustrasi Footer (pohon + tenda) ---
          _buildFooterIllustration(),
        ],
      ),
    );
  }

  /// Grid 3 kolom × 2 baris untuk 6 menu utama.
  Widget _buildMenuGrid(BuildContext context) {
    final menus = [
      _MenuItem(
        icon: Icons.balance_outlined,
        label: 'Cek\nStunting',
        iconColor: const Color(0xFF4B83D6),
        onTap: () => _navigateTo(const PilihAnakPage()),
      ),
      _MenuItem(
        icon: Icons.bar_chart_rounded,
        label: 'Grafik\nPertumbuhan',
        iconColor: const Color(0xFFEAA63C),
        onTap: () => _navigateTo(const PilihAnakGrafikPage()),
      ),
      _MenuItem(
        icon: Icons.local_dining_outlined,
        label: 'Resep\nMPASI',
        iconColor: const Color(0xFFE08040),
        onTap: () => _navigateTo(const DaftarResepPage()),
      ),
      _MenuItem(
        icon: Icons.article_outlined,
        label: 'Artikel\nKesehatan',
        iconColor: const Color(0xFF4B83D6),
        onTap: () => _navigateTo(const DaftarArtikelPage()),
      ),
      _MenuItem(
        icon: Icons.location_on_outlined,
        label: 'Lokasi\nFasyankes',
        iconColor: const Color(0xFF3CC3A6),
        onTap: () => _navigateTo(const LokasiFasyankesPage()),
      ),
      _MenuItem(
        icon: Icons.sports_esports_outlined,
        label: 'Permainan',
        iconColor: const Color(0xFF7B61FF),
        onTap: () => _navigateTo(const GameMulaiPage()),
      ),
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: menus.sublist(0, 3).map(_buildMenuCard).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: menus.sublist(3, 6).map(_buildMenuCard).toList(),
        ),
      ],
    );
  }

  Widget _buildMenuCard(_MenuItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        width: 80,
        height: 85,
        decoration: BoxDecoration(
          color: const Color(0xFFECF6FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 36, color: item.iconColor),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF000000),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card promosi PediaGrow (340×115, #ECF6FF, radius 10).
  Widget _buildPediaGrowCard() {
    return Container(
      width: 340,
      height: 115,
      decoration: BoxDecoration(
        color: const Color(0xFFECF6FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          // Ilustrasi karakter anak
          SizedBox(
            width: 88,
            height: 96,
            child: Image.asset(
              'assets/images/register_family.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.child_care_rounded,
                size: 56,
                color: Color(0xFF3985E7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Teks
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "PediaGrow" dengan dua warna
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
                Text(
                  'Pantau Pertumbuhan,\nCegah Stunting untuk Masa Depan',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF000000),
                    height: 1.4,
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

  /// Ilustrasi pohon/rumput/tenda sebagai penutup konten sebelum nav bar.
  Widget _buildFooterIllustration() {
    return SizedBox(
      width: double.infinity,
      child: Image.asset(
        'assets/images/beranda_landscape_footer.jpg',
        fit: BoxFit.fitWidth,
        errorBuilder: (_, __, ___) => Container(
          height: 120,
          color: const Color(0xFFD1FAE5),
          child: const Center(
            child: Icon(Icons.park_outlined, size: 48, color: Color(0xFF3CC3A6)),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // NAVIGATION BAR
  // ------------------------------------------------------------------
  Widget _buildNavBar() {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Beranda'),
      _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Konsultasi'),
      _NavItem(icon: Icons.history_rounded, label: 'Riwayat Konsultasi'),
      _NavItem(icon: Icons.person_outline_rounded, label: 'Profil Ibu'),
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
        children: List.generate(items.length, (i) {
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
                    // Bulatan putih berisi ikon biru untuk item aktif
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        items[i].icon,
                        size: 22,
                        color: const Color(0xFF72A9F4),
                      ),
                    )
                  else
                    Icon(
                      items[i].icon,
                      size: 22,
                      color: const Color(0xFF94A3B8),
                    ),
                  if (!isSelected) ...[
                    const SizedBox(height: 2),
                    Text(
                      items[i].label,
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
// Helper classes & widgets
// ------------------------------------------------------------------

class _MenuItem {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

/// Widget elips dekoratif dengan efek blur.
class _Ellipse extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double blurSigma;

  const _Ellipse({
    required this.width,
    required this.height,
    required this.color,
    required this.blurSigma,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ColorFilter.matrix(<double>[
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: CustomPaint(
        size: Size(width, height),
        painter: _EllipsePainter(color: color, blurSigma: blurSigma),
      ),
    );
  }
}

class _EllipsePainter extends CustomPainter {
  final Color color;
  final double blurSigma;

  const _EllipsePainter({required this.color, required this.blurSigma});

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
  bool shouldRepaint(covariant _EllipsePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.blurSigma != blurSigma;
}
