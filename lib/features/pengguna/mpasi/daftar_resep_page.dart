import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../beranda/beranda_page.dart';
import '../konsultasi/daftar_dokter_page.dart';
import '../profil/menu_profil_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_page.dart';
import 'detail_resep_page.dart';

/// Halaman "Daftar Resep MPASI" PediaGrow.
///
/// Dibuat semirip dan sepresisi mungkin dengan desain Figma acuan:
/// - Header fixed di atas: Tombol Back (12dp dari kiri) + Search Bar rounded #F1F5F9
/// - Filter kategori usia horizontal fixed di bawah search bar
/// - Area list resep adalah satu-satunya area yang scrollable vertikal
/// - Item resep: Judul (max 2 baris), metadata (icon jam + kategori), tanggal, dan thumbnail
/// - Ilustrasi taman (rumput, bukit, pohon, tenda) fixed di bagian bawah
/// - Bottom navigation bar 4 menu fixed di bagian paling bawah
class DaftarResepPage extends StatefulWidget {
  const DaftarResepPage({super.key});

  @override
  State<DaftarResepPage> createState() => _DaftarResepPageState();
}

class _DaftarResepPageState extends State<DaftarResepPage> {
  // Design Tokens Resmi PediaGrow
  static const Color colorPrimaryBlue = Color(0xFF2A85FF);
  static const Color colorSoftBlue = Color(0xFFEBF5FF);
  static const Color colorWhite = Color(0xFFFFFFFF);
  static const Color colorTextPrimary = Color(0xFF1A202C);
  static const Color colorTextSecondary = Color(0xFF718096);
  static const Color colorTextMuted = Color(0xFF94A3B8);
  static const Color colorSearchBg = Color(0xFFF1F5F9);
  static const Color colorBorder = Color(0xFFE2E8F0);
  static const Color colorSeparator = Color(0xFFF1F5F9);

  // Search & Filter Controller/State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  // Daftar Pilihan Kategori Usia
  static const List<String> _categories = [
    'Semua',
    '6-8 bulan',
    '9-11 bulan',
    '12-23 bulan',
  ];

  // Dummy data untuk preview/testing UI.
  // Nantinya dapat diganti dengan data dari backend PMIK/Superadmin.
  final List<Map<String, dynamic>> _allRecipes = const [
    {
      'id': 'resep-1',
      'title': 'Bubur Singkong Isi Ikan dan Ayam dengan Saus Jeruk',
      'category': '6-8 bulan',
      'date': '26 Agustus 2026',
      'assetImage': 'assets/images/resep_1.png',
    },
    {
      'id': 'resep-2',
      'title': 'Bubur Soto Ayam Santan',
      'category': '6-8 bulan',
      'date': '26 Agustus 2026',
      'assetImage': 'assets/images/resep_2.png',
    },
    {
      'id': 'resep-3',
      'title': 'Puding Kentang Ayam dan Telur',
      'category': '6-8 bulan',
      'date': '26 Agustus 2026',
      'assetImage': 'assets/images/resep_3.png',
    },
    {
      'id': 'resep-4',
      'title': 'Nasi Tim Ikan Tuna Telur Puyuh',
      'category': '9-11 bulan',
      'date': '26 Agustus 2026',
      'assetImage': 'assets/images/resep_4.png',
    },
    {
      'id': 'resep-5',
      'title': 'Mie Kukus Telur Puyuh',
      'category': '9-11 bulan',
      'date': '26 Agustus 2026',
      'assetImage': 'assets/images/resep_5.png',
    },
    {
      'id': 'resep-6',
      'title': 'Tim Bubur Manado Daging dan Udang',
      'category': '9-11 bulan',
      'date': '26 Agustus 2026',
      'assetImage': 'assets/images/resep_6.png',
    },
    {
      'id': 'resep-7',
      'title': 'Nasi Soto Ayam Kuah Kuning',
      'category': '12-23 bulan',
      'date': '26 Agustus 2026',
      'assetImage': 'assets/images/resep_7.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter resep berdasarkan kategori dan kata kunci pencarian secara realtime
  List<Map<String, dynamic>> get _filteredRecipes {
    return _allRecipes.where((recipe) {
      final matchesCategory = _selectedCategory == 'Semua' ||
          recipe['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          (recipe['title'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _onBackPressed() {
    Navigator.of(context).maybePop();
  }

  // ===========================================================================
  // BUILD METHOD UTAMA
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorWhite,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER ATAS FIXED: Back Button + Search Bar
            _buildHeader(),

            // 2. FILTER KATEGORI USIA FIXED: Horizontal Scrollable Chips
            _buildCategoryFilterChips(),
            const SizedBox(height: 6),

            // 3. DAFTAR RESEP: Satu-satunya area yang scrollable vertikal
            Expanded(
              child: _buildRecipeList(),
            ),

            // 4. ILUSTRASI TAMAN FIXED (Pohon, bukit, tenda, rumput)
            _buildGardenIllustration(),

            // 5. BOTTOM NAVIGATION BAR FIXED (4 Menu)
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER ATAS (Fixed, Back Button 12dp + Search Bar)
  // ===========================================================================

  Widget _buildHeader() {
    return Container(
      height: 56,
      width: double.infinity,
      color: colorWhite,
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol back berjarak tepat 12dp dari pinggir kiri layar
          const SizedBox(width: 12),
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
                    color: colorTextPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Search Bar Abu-Abu Sangat Muda (#F1F5F9) Mengisi Sisa Ruang
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: colorSearchBg,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: colorTextMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: colorTextPrimary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Cari Resep MPASI',
                        hintStyle: GoogleFonts.lato(
                          fontSize: 14,
                          color: colorTextMuted,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        color: colorTextMuted,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. FILTER KATEGORI USIA (Horizontal Scroll, Fixed di Atas)
  // ===========================================================================

  Widget _buildCategoryFilterChips() {
    return Container(
      width: double.infinity,
      color: colorWhite,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? colorSoftBlue : colorWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? colorPrimaryBlue : colorBorder,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? colorPrimaryBlue
                            : const Color(0xFF64748B),
                      ),
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

  // ===========================================================================
  // 3. DAFTAR RESEP (ListView Scrollable Vertikal)
  // ===========================================================================

  Widget _buildRecipeList() {
    final recipes = _filteredRecipes;

    if (recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: colorTextMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'Tidak ada resep yang ditemukan',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Coba gunakan kata kunci lain atau ubah filter kategori usia.',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  color: colorTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: recipes.length,
      separatorBuilder: (context, index) => const Divider(
        color: colorSeparator,
        thickness: 1.0,
        height: 24,
      ),
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return _buildRecipeItem(recipe);
      },
    );
  }

  // Item Resep: Judul, Metadata, Tanggal di kiri, Thumbnail di kanan
  Widget _buildRecipeItem(Map<String, dynamic> recipe) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DetailResepPage(),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sisi Kiri: Informasi Resep
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul Resep (Max 2 baris)
                Text(
                  recipe['title'] ?? '',
                  style: GoogleFonts.lato(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: colorTextPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Metadata: Ikon Jam + "Resep MPASI • [Kategori Usia]"
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: colorTextMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Resep MPASI  •  ${recipe['category']}',
                        style: GoogleFonts.lato(
                          fontSize: 11.5,
                          color: colorTextMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Tanggal Resep
                Text(
                  recipe['date'] ?? '26 Agustus 2026',
                  style: GoogleFonts.lato(
                    fontSize: 11.5,
                    color: colorTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Sisi Kanan: Thumbnail Makanan (~95x66dp)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 95,
              height: 66,
              color: colorSearchBg,
              child: Image.asset(
                recipe['assetImage'] ?? 'assets/images/resep_1.png',
                width: 95,
                height: 66,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 95,
                  height: 66,
                  color: colorSoftBlue,
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: colorPrimaryBlue,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. ILUSTRASI TAMAN FIXED (Rumput, bukit, pohon, tenda)
  // ===========================================================================

  Widget _buildGardenIllustration() {
    return SizedBox(
      width: double.infinity,
      height: 68,
      child: Image.asset(
        'assets/images/garden_illustration.png',
        width: double.infinity,
        height: 68,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) {
          // Fallback ilustrasi alam jika aset belum tersedia
          return CustomPaint(
            size: const Size(double.infinity, 68),
            painter: _GardenPainter(),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 5. BOTTOM NAVIGATION BAR FIXED (4 Menu)
  // ===========================================================================

  Widget _buildBottomNavigation() {
    return Container(
      height: 58,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: colorWhite,
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Menu Beranda
          _buildNavItem(
            icon: Icons.home_outlined,
            label: 'Beranda',
            isActive: false,
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          // 2. Menu Konsultasi
          _buildNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Konsultasi',
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DaftarDokterPage(),
                ),
              );
            },
          ),
          // 3. Menu Riwayat Konsultasi
          _buildNavItem(
            icon: Icons.assignment_outlined,
            label: 'Riwayat Konsultasi',
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DaftarRiwayatPage(),
                ),
              );
            },
          ),
          // 4. Menu Profil Ibu
          _buildNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil Ibu',
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MenuProfilPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? colorPrimaryBlue : colorTextMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 75,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 10.5,
                  color: color,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fallback Painter ilustrasi taman jika file gambar belum siap
class _GardenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final hillPaint = Paint()
      ..color = const Color(0xFF679A45)
      ..style = PaintingStyle.fill;

    final darkHillPaint = Paint()
      ..color = const Color(0xFF4A7D32)
      ..style = PaintingStyle.fill;

    // Bukit belakang
    final backHill = Path();
    backHill.moveTo(0, size.height * 0.4);
    backHill.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.15,
      size.width * 0.5,
      size.height * 0.35,
    );
    backHill.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.55,
      size.width,
      size.height * 0.3,
    );
    backHill.lineTo(size.width, size.height);
    backHill.lineTo(0, size.height);
    backHill.close();
    canvas.drawPath(backHill, darkHillPaint);

    // Bukit depan
    final frontHill = Path();
    frontHill.moveTo(0, size.height * 0.55);
    frontHill.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.35,
      size.width * 0.6,
      size.height * 0.5,
    );
    frontHill.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.65,
      size.width,
      size.height * 0.45,
    );
    frontHill.lineTo(size.width, size.height);
    frontHill.lineTo(0, size.height);
    frontHill.close();
    canvas.drawPath(frontHill, hillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
