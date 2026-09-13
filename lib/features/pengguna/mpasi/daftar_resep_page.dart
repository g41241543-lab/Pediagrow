import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/resep_mpasi_service.dart';
import '../../../models/resep_mpasi_model.dart';
import '../beranda/beranda_page.dart';
import '../konsultasi/daftar_dokter_page.dart';
import '../profil/menu_profil_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_page.dart';
import 'detail_resep_page.dart';

/// Halaman "Daftar Resep MPASI" PediaGrow.
///
/// Data bersumber dari [ResepMpasiService] (SQLite lokal) yang dikelola
/// oleh PMIK/Superadmin. Halaman ini hanya menampilkan, tidak ada dummy data
/// hardcoded sebagai sumber data utama.
///
/// Struktur Fixed/Scrollable:
/// - FIXED  : Header (back + search bar) + Filter Kategori Usia + Bottom Nav
/// - SCROLL : Daftar Resep + Garden Illustration
class DaftarResepPage extends StatefulWidget {
  const DaftarResepPage({super.key});

  @override
  State<DaftarResepPage> createState() => _DaftarResepPageState();
}

class _DaftarResepPageState extends State<DaftarResepPage> {
  // -------------------------------------------------------------------------
  // Design Tokens (konsisten dengan beranda_page.dart & design reference)
  // -------------------------------------------------------------------------
  static const Color _colorPrimaryBlue = Color(0xFF2A85FF);
  static const Color _colorSoftBlue = Color(0xFFEBF5FF);
  static const Color _colorWhite = Color(0xFFFFFFFF);
  static const Color _colorDark = Color(0xFF1A202C);
  static const Color _colorTextMuted = Color(0xFF94A3B8);
  static const Color _colorBorderLight = Color(0xFFC5C5C5);
  static const Color _colorSearchBg = Color(0xFFF1F5F9);
  static const Color _colorDivider = Color(0xFFF1F5F9);
  static const Color _colorNavBg = Color(0xFFFFFFFF);

  // -------------------------------------------------------------------------
  // State
  // -------------------------------------------------------------------------
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  // Async state
  List<ResepMpasiModel> _recipes = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const List<String> _categories = [
    'Semua',
    '6-8 bulan',
    '9-11 bulan',
    '12-23 bulan',
  ];

  final ResepMpasiService _service = ResepMpasiService();

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Data loading
  // -------------------------------------------------------------------------

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    if (q == _searchQuery) return;
    setState(() => _searchQuery = q);
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.getAllResep(
        kategoriUsia: _selectedCategory,
        searchQuery: _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _recipes = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Resep belum dapat dimuat. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

  void _onCategoryChanged(String category) {
    if (category == _selectedCategory) return;
    setState(() => _selectedCategory = category);
    _loadRecipes();
  }

  void _onBackPressed() => Navigator.of(context).maybePop();

  // -------------------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorWhite,
      // Bottom navigation FIXED — tidak ikut scroll
      bottomNavigationBar: _buildBottomNavigation(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: back button + search bar — FIXED
            _buildHeader(),

            // Filter kategori usia — FIXED
            _buildAgeFilter(),

            // Area scrollable: Daftar Resep + Garden Illustration
            Expanded(
              child: _buildScrollableContent(),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 1. HEADER (Back Button + Search Bar) — FIXED
  // -------------------------------------------------------------------------

Widget _buildHeader() {
  return Container(
    width: double.infinity,
    color: _colorWhite,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Back button
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _onBackPressed,
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: _colorDark,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Search bar
        Expanded(child: _buildSearchBar()),
      ],
    ),
  );
}

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _colorSearchBg,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_rounded,
            color: _colorTextMuted,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: _colorDark,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Cari Resep MPASI',
                hintStyle: GoogleFonts.lato(
                  fontSize: 14,
                  color: _colorTextMuted,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () => _searchController.clear(),
              child: const Icon(
                Icons.close_rounded,
                color: _colorTextMuted,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 2. FILTER KATEGORI USIA — FIXED
  // -------------------------------------------------------------------------

  Widget _buildAgeFilter() {
    return Container(
      width: double.infinity,
      color: _colorWhite,
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _categories.map((cat) {
            final isActive = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => _onCategoryChanged(cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? _colorSoftBlue : _colorWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? _colorPrimaryBlue : _colorBorderLight,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? _colorPrimaryBlue : _colorBorderLight,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 3. SCROLLABLE CONTENT (Recipe List + Garden Illustration)
  // -------------------------------------------------------------------------

  Widget _buildScrollableContent() {
    // Loading state
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _colorPrimaryBlue,
          strokeWidth: 2.5,
        ),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    // Empty state — belum ada resep dari PMIK/Superadmin
    if (_recipes.isEmpty) {
      return _buildEmptyState();
    }

    // Recipe list + Garden illustration dalam satu scroll
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Daftar resep
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final recipe = _recipes[index];
              return Column(
                children: [
                  _buildRecipeItem(recipe),
                  if (index < _recipes.length - 1)
                    Divider(
                      color: _colorDivider,
                      thickness: 1,
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            },
            childCount: _recipes.length,
          ),
        ),

        // Spacer antara list terakhir dan garden illustration
        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // Garden illustration — SCROLL (bukan fixed!)
        SliverToBoxAdapter(child: _buildGardenIllustration()),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 4. RECIPE ITEM
  // -------------------------------------------------------------------------

  Widget _buildRecipeItem(ResepMpasiModel recipe) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailResepPage(resep: _toDetailModel(recipe)),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kiri: judul, metadata, tanggal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul resep — maks 2 baris
                  Text(
                    recipe.judul,
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _colorDark,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),

                  // Metadata: ikon jam + kategori
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 15,
                        color: _colorTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Resep MPASI  •  ${recipe.kategoriUsia}',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: _colorTextMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tanggal resep
                  Text(
                    recipe.tanggal,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: _colorTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Kanan: thumbnail resep
            _buildThumbnail(recipe),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(ResepMpasiModel recipe) {
    final imagePath = recipe.displayImage;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 100,
        height: 70,
        color: _colorSearchBg,
        child: imagePath != null
            ? Image.asset(
                imagePath,
                width: 100,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _thumbnailFallback(),
              )
            : _thumbnailFallback(),
      ),
    );
  }

  Widget _thumbnailFallback() {
    return Container(
      width: 100,
      height: 70,
      color: _colorSoftBlue,
      child: const Icon(
        Icons.restaurant_menu_rounded,
        color: _colorPrimaryBlue,
        size: 28,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 5. GARDEN ILLUSTRATION — ikut scroll bersama daftar resep
  // -------------------------------------------------------------------------

  Widget _buildGardenIllustration() {
    return Image.asset(
      'assets/images/garden_illustration.png',
      width: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (context, error, stackTrace) {
        return CustomPaint(
          size: const Size(double.infinity, 90),
          painter: _GardenFallbackPainter(),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // 6. EMPTY STATE
  // -------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: _EmptyStateContent(),
                  ),
                ),
              ),
              // Garden illustration tetap tampil di empty state
              Image.asset(
                'assets/images/garden_illustration.png',
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => CustomPaint(
                  size: const Size(double.infinity, 90),
                  painter: _GardenFallbackPainter(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 7. ERROR STATE
  // -------------------------------------------------------------------------

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: _colorTextMuted,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Terjadi kesalahan.',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: _colorTextMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadRecipes,
              child: Text(
                'Coba Lagi',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _colorPrimaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 8. BOTTOM NAVIGATION — FIXED (Scaffold.bottomNavigationBar)
  // -------------------------------------------------------------------------

  Widget _buildBottomNavigation() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: _colorNavBg,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home_rounded,
              label: 'Beranda',
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const BerandaPage()),
                  (route) => false,
                );
              },
            ),
            _buildNavItem(
              icon: Icons.question_answer_rounded,
              label: 'Konsultasi',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DaftarDokterPage()),
              ),
            ),
            _buildNavItem(
              icon: Icons.manage_search_rounded,
              label: 'Riwayat Konsultasi',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DaftarRiwayatPage()),
              ),
            ),
            _buildNavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profil Ibu',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MenuProfilPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 75,
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: const Color(0xFF9E9E9E)),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 10.5,
                  color: const Color(0xFF9E9E9E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // HELPER: konversi ResepMpasiModel → ResepMpasi (untuk detail page)
  // -------------------------------------------------------------------------

  ResepMpasi _toDetailModel(ResepMpasiModel m) {
    return ResepMpasi(
      id: m.id?.toString() ?? '',
      title: m.judul,
      author: m.penulis ?? '',
      date: m.tanggal,
      category: m.kategoriUsia,
      assetImage: m.assetImagePath ?? '',
      energi: m.energiKkal ?? 0,
      lemak: m.lemakGr ?? 0,
      protein: m.proteinGr ?? 0,
      porsi: m.porsi ?? 0,
      bahan: m.bahan,
      bahanPelapis: m.bahanPelapis,
      buah: m.buah,
      caraMembuat: m.caraMembuat,
    );
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

/// Empty state content widget
class _EmptyStateContent extends StatelessWidget {
  const _EmptyStateContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.restaurant_menu_outlined,
          size: 52,
          color: Color(0xFFCBD5E1),
        ),
        const SizedBox(height: 14),
        Text(
          'Belum ada resep MPASI',
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Resep akan muncul setelah PMIK\nmenambahkan data resep.',
          style: GoogleFonts.lato(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Fallback CustomPainter untuk garden illustration
class _GardenFallbackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Langit
    final skyPaint = Paint()..color = const Color(0xFFE8F5E9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    final darkGreenPaint = Paint()
      ..color = const Color(0xFF4A7D32)
      ..style = PaintingStyle.fill;
    final greenPaint = Paint()
      ..color = const Color(0xFF679A45)
      ..style = PaintingStyle.fill;

    // Bukit belakang
    final backPath = Path();
    backPath.moveTo(0, size.height * 0.5);
    backPath.quadraticBezierTo(
        size.width * 0.25, size.height * 0.15, size.width * 0.5, size.height * 0.4);
    backPath.quadraticBezierTo(
        size.width * 0.75, size.height * 0.6, size.width, size.height * 0.35);
    backPath.lineTo(size.width, size.height);
    backPath.lineTo(0, size.height);
    backPath.close();
    canvas.drawPath(backPath, darkGreenPaint);

    // Bukit depan
    final frontPath = Path();
    frontPath.moveTo(0, size.height * 0.65);
    frontPath.quadraticBezierTo(
        size.width * 0.3, size.height * 0.4, size.width * 0.6, size.height * 0.55);
    frontPath.quadraticBezierTo(
        size.width * 0.85, size.height * 0.7, size.width, size.height * 0.5);
    frontPath.lineTo(size.width, size.height);
    frontPath.lineTo(0, size.height);
    frontPath.close();
    canvas.drawPath(frontPath, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
