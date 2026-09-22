import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/resep_mpasi_service.dart';
import '../../../models/resep_mpasi_model.dart';
import '../../../shared/widgets/illustration_forest_footer.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';
import 'detail_resep_page.dart';

/// Halaman "Daftar Resep MPASI" PediaGrow.
///
/// Data bersumber dari [ResepMpasiService] (SQLite lokal) yang dikelola
/// oleh PMIK/Superadmin.
///
/// Desain & Spesifikasi Layout:
/// 1. Scaffold background putih murni.
/// 2. Header tetap (56dp): tombol back 12dp dari kiri, judul "Daftar Resep MPASI"
///    (font Lato 20sp bold hitam).
/// 3. Search Bar dinamis: rounded corner 20, background abu-abu muda #F1F2F6,
///    ikon pencarian, hint "Cari Resep MPASI", tombol reset pencarian real-time.
/// 4. Filter Kategori Usia: chips horizontal di bawah search bar ('Semua', '6-8 bulan',
///    '9-11 bulan', '12-23 bulan', '24+ bulan').
/// 5. Konten Utama: ListView scrollable bergaya kartu list horizontal seperti
///    pada halaman Daftar Artikel (kiri: judul bold 16sp, ikon jam + metadata 12sp,
///    tanggal 12sp; kanan: thumbnail rounded 18dp 124x84dp).
/// 6. Divider pemisah 1dp #E5E5E5 antar item resep.
/// 7. Ilustrasi Footer: [IllustrationForestFooter] tetap (fixed) di bagian bawah
///    di atas Bottom Navigation Bar. Area scroll berada tepat di atas ilustrasi
///    sehingga ketika di-scroll tidak menindih/menimpa ilustrasi, dan menyatu
///    alami tanpa garis batas kaku. Ilustrasi tidak ditransparasi.
/// 8. Bottom Navigation Bar tetap di `Scaffold.bottomNavigationBar`
///    menggunakan [PediaBottomNavBar] (selectedIndex: -1).
class DaftarResepPage extends StatefulWidget {
  const DaftarResepPage({super.key});

  @override
  State<DaftarResepPage> createState() => _DaftarResepPageState();
}

class _DaftarResepPageState extends State<DaftarResepPage> {
  // -------------------------------------------------------------------------
  // Design Tokens
  // -------------------------------------------------------------------------
  static const Color _colorPrimaryBlue = Color(0xFF2A85FF);
  static const Color _colorSoftBlue = Color(0xFFEBF5FF);
  static const Color _colorWhite = Color(0xFFFFFFFF);
  static const Color _colorDark = Color(0xFF000000);
  static const Color _colorTextMuted = Color(0xFFA0A0A0);
  static const Color _colorSearchBg = Color(0xFFF1F2F6);
  static const Color _colorDivider = Color(0xFFE5E5E5);

  // -------------------------------------------------------------------------
  // State
  // -------------------------------------------------------------------------
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
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
    '24+ bulan',
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
    _searchFocusNode.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Data loading & filtering
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

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  void _onBackPressed() => Navigator.of(context).maybePop();

  // -------------------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Tinggi ilustrasi footer kira-kira 140dp (beranda_landscape_footer.jpg)
    // Digunakan sebagai padding bawah list agar resep tidak tersembunyi di balik ilustrasi
    const double illustrationHeight = 140;

    return Scaffold(
      backgroundColor: _colorWhite,
      // Bottom navigation bar FIXED — PediaBottomNavBar terpusat
      bottomNavigationBar: const PediaBottomNavBar(selectedIndex: -1),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Back button + Judul "Daftar Resep MPASI" (FIXED 56dp)
            _buildHeader(context),

            // 2. Search Bar dinamis (FIXED)
            _buildSearchBar(),

            // 3. Filter Kategori Usia (FIXED)
            _buildAgeFilter(),

            const SizedBox(height: 8),

            // 4. Konten utama: Stack dengan ilustrasi FIXED di bawah,
            //    daftar resep SCROLLABLE di atasnya (muncul seamless tanpa batas kaku)
            Expanded(
              child: Stack(
                children: [
                  // ── Ilustrasi alam: FIXED di bagian dasar ──────────────────
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: IllustrationForestFooter(fit: BoxFit.fitWidth),
                    ),
                  ),

                  // ── Daftar resep SCROLLABLE di atasnya ─────────────────────
                  // ShaderMask menambahkan efek gradient fade di bagian bawah
                  // sehingga daftar resep terlihat "muncul" alami di atas ilustrasi
                  // tanpa garis/sekat yang tampak kaku.
                  Positioned.fill(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,        // Konten penuh terlihat di atas
                            Colors.white,        // Terlihat jelas hingga 75% tinggi
                            Color(0x00FFFFFF),   // Fade ke transparan menuju ilustrasi
                          ],
                          stops: [0.0, 0.75, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: _buildScrollableContent(illustrationHeight),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 1. HEADER (Back button + Judul "Daftar Resep MPASI") — FIXED 56dp
  // -------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      color: _colorWhite,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Kembali
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _onBackPressed,
              borderRadius: BorderRadius.circular(24),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.arrow_back,
                  size: 24,
                  color: _colorDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Judul Halaman
          Expanded(
            child: Text(
              'Daftar Resep MPASI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _colorDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 2. SEARCH BAR DINAMIS — Sesuai Halaman Artikel Kesehatan
  // -------------------------------------------------------------------------

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _colorSearchBg,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_rounded,
              size: 22,
              color: Color(0xFF9E9E9E),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  color: _colorDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari Resep MPASI',
                  hintStyle: GoogleFonts.lato(
                    fontSize: 15,
                    color: _colorTextMuted,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                textInputAction: TextInputAction.search,
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: _clearSearch,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 3. FILTER KATEGORI USIA (0-6 bulan dihapus)
  // -------------------------------------------------------------------------

  Widget _buildAgeFilter() {
    return Container(
      width: double.infinity,
      color: _colorWhite,
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _categories.map((cat) {
            final isActive = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _onCategoryChanged(cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? _colorSoftBlue : _colorWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? _colorPrimaryBlue : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? _colorPrimaryBlue : const Color(0xFF7F7F7F),
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
  // 4. SCROLLABLE CONTENT (Daftar Resep / Loading / Empty / Error)
  // -------------------------------------------------------------------------

  Widget _buildScrollableContent([double illustrationHeight = 140]) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(_colorPrimaryBlue),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_recipes.isEmpty) {
      return _buildEmptyState();
    }

    // Padding bawah: ilustrasi (~140dp) + zona fade gradien (~60dp) + nav bar safe area
    // Memastikan resep terakhir bisa di-scroll ke atas dan terlihat sepenuhnya
    final double bottomPad = illustrationHeight + 60;

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(top: 8, bottom: bottomPad),
      itemCount: _recipes.length,
      separatorBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(
            height: 32,
            thickness: 1,
            color: _colorDivider,
          ),
        );
      },
      itemBuilder: (context, index) {
        final recipe = _recipes[index];
        return _buildRecipeItem(recipe);
      },
    );
  }

  // -------------------------------------------------------------------------
  // 5. RECIPE ITEM — Persis tata letak, ukuran font, gambar, dan jarak
  //    seperti halaman Daftar Artikel Kesehatan
  // -------------------------------------------------------------------------

  Widget _buildRecipeItem(ResepMpasiModel recipe) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailResepPage(
              resepModel: recipe,
              resep: _toDetailModel(recipe),
            ),
          ),
        );
      },
      splashColor: const Color(0x10000000),
      highlightColor: const Color(0x08000000),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Kiri: Judul, Metadata (Jam + Resep MPASI + Kategori), dan Tanggal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul Resep (Lato 16sp bold hitam, max 3 baris dengan ellipsis)
                  Text(
                    recipe.judul,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _colorDark,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Metadata: Ikon Jam + "Resep MPASI" + Kategori Usia
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: _colorTextMuted,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Resep MPASI   •   ${recipe.kategoriUsia}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: _colorTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tanggal publikasi resep
                  Text(
                    recipe.tanggal,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _colorTextMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Bagian Kanan: Thumbnail gambar resep (rounded 18dp, 124x84dp, BoxFit.cover)
            _buildThumbnail(recipe),
          ],
        ),
      ),
    );
  }

  /// Thumbnail resep dengan sudut membulat modern dan placeholder fallback
  Widget _buildThumbnail(ResepMpasiModel recipe) {
    const double thumbWidth = 124;
    const double thumbHeight = 84;
    const double borderRadius = 18;

    final displayImage = recipe.displayImage;
    final isNetwork = recipe.isNetworkImage;

    return Container(
      width: thumbWidth,
      height: thumbHeight,
      decoration: BoxDecoration(
        color: _colorSearchBg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: displayImage == null || displayImage.isEmpty
            ? _buildThumbnailPlaceholder()
            : isNetwork
                ? Image.network(
                    displayImage,
                    width: thumbWidth,
                    height: thumbHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildThumbnailPlaceholder(),
                  )
                : Image.asset(
                    displayImage,
                    width: thumbWidth,
                    height: thumbHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildThumbnailPlaceholder(),
                  ),
      ),
    );
  }

  /// Placeholder jika gambar resep belum tersedia / gagal dimuat
  Widget _buildThumbnailPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFEEEEEE),
      child: const Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          size: 32,
          color: Color(0xFFBDBDBD),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 6. EMPTY STATE & ERROR STATE
  // -------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.restaurant_menu_outlined,
              size: 56,
              color: const Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Resep tidak ditemukan'
                  : 'Belum ada resep MPASI',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Tidak ada resep yang cocok dengan kata kunci "$_searchQuery". Silakan coba kata kunci lain.'
                  : 'Resep MPASI akan ditampilkan di sini setelah administrator PMIK menambahkan data resep.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13,
                color: const Color(0xFF9E9E9E),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFF9E9E9E),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Terjadi kesalahan.',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: const Color(0xFF9E9E9E),
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
  // HELPER: konversi ResepMpasiModel → ResepMpasi (untuk DetailResepPage)
  // -------------------------------------------------------------------------

  ResepMpasi _toDetailModel(ResepMpasiModel m) {
    return ResepMpasi.fromModel(m);
  }
}