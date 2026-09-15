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
/// oleh PMIK/Superadmin. Halaman ini hanya menampilkan, tidak ada dummy data
/// hardcoded sebagai sumber data utama.
///
/// Struktur Fixed/Scrollable:
/// - FIXED  : Header (back + judul "Resep MPASI" + search bar) + Filter Kategori Usia
/// - SCROLL : Daftar Resep (hanya menu yang di-scroll, dengan fade mask menyatu mengalir ke ilustrasi)
/// - FIXED  : Ilustrasi Lanskap Hutan (stay/fixed di bagian bawah dengan feather gradient lembut)
/// - FIXED  : PediaBottomNavBar (Scaffold.bottomNavigationBar)
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

  // Design tokens resmi — abu tua & abu muda
  static const Color _colorGreyDark = Color(0xFF7F7F7F); // abu tua
  static const Color _colorGreyLight = Color(0xFFC5C5C5); // abu muda

  // Alias agar konsisten dengan pemakaian sebelumnya di file ini
  static const Color _colorTextMuted = _colorGreyDark;
  static const Color _colorBorderLight = _colorGreyLight;

  static const Color _colorSearchBg = Color(0xFFF1F5F9);
  static const Color _colorDivider = Color(0xFFF1F5F9);

  // (Warna nav dikelola oleh PediaBottomNavBar yang sudah terpusat)

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
      // Bottom navigation FIXED — menggunakan PediaBottomNavBar terpusat
      // (konsisten dengan BerandaPage, warna #F2EDED, tinggi 68dp).
      // selectedIndex: -1 agar tidak ada tab aktif.
      bottomNavigationBar: const PediaBottomNavBar(selectedIndex: -1),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: back button + judul "Resep MPASI" + search bar — FIXED
            _buildHeader(),

            // Filter kategori usia — FIXED
            _buildAgeFilter(),

            // Area konten scrollable & ilustrasi menyatu secara seamless:
            // - Ilustrasi lanskap stay/fixed di posisi bawah
            // - Konten resep dapat di-scroll mengalir dengan efek fade mask halus
            //   di atas ilustrasi sehingga batasannya menyatu dan tidak kaku
            Expanded(
              child: Stack(
                children: [
                  // 1. Ilustrasi lanskap — FIXED di bagian bawah (di atas Nav Bar)
                  //    dilengkapi gradient lembut di batas atas agar membaur
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildSeamlessFooterIllustration(),
                  ),

                  // 2. Daftar resep scrollable — menggunakan ShaderMask gradient
                  //    agar saat di-scroll ke bawah, item mengalir memudar secara halus
                  //    ke dalam ilustrasi tanpa batas potong yang kaku
                  Positioned.fill(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.72, 0.95],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: _buildScrollableContent(),
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
  // 1. HEADER (Back Button + Judul "Resep MPASI" + Search Bar) — FIXED
  //
  //    Baris 1 : tombol back + judul "Resep MPASI"
  //    Baris 2 : search bar (di bawah judul, bukan di sebelah tombol back)
  // -------------------------------------------------------------------------

  // Header (back + judul) — tinggi PERSIS 56dp, terpisah dari search bar.
  // Search bar berada di luar blok header, dengan margin umum 16dp.
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Blok header: tinggi 56dp — back button 12dp dari kiri layar,
        // judul halaman 12dp setelah back button.
        Container(
          height: 56,
          width: double.infinity,
          color: _colorWhite,
          padding: const EdgeInsets.only(left: 12, right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
              const SizedBox(width: 12),
              Text(
                'Resep MPASI',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _colorDark,
                ),
              ),
            ],
          ),
        ),

        // Search bar — di luar blok header 56dp, margin kanan-kiri 16dp
        // (mengikuti aturan umum jarak tepi layar).
        Container(
          width: double.infinity,
          color: _colorWhite,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _buildSearchBar(),
        ),
      ],
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
      padding: const EdgeInsets.only(top: 14, bottom: 10),
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
  //
  //    Ilustrasi SELALU menempel tepat di atas bottom navigation:
  //    - Jika daftar resep kosong/pendek, ilustrasi ditempatkan di bagian
  //      bawah ruang yang tersisa (tidak ada celah putih di bawahnya).
  //    - Jika daftar resep panjang (melebihi tinggi layar), ilustrasi
  //      tetap muncul mengikuti scroll setelah item terakhir, seperti biasa.
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

    // Empty state
    if (_recipes.isEmpty) {
      return const SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 32, 24, 140),
          child: Center(
            child: _EmptyStateContent(),
          ),
        ),
      );
    }

    // Daftar resep — ListView bergaya artikel/majalah:
    // setiap item adalah kartu dengan gambar landscape besar
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
      itemCount: _recipes.length,
      itemBuilder: (_, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildRecipeCard(_recipes[index]),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // 4. RECIPE CARD (Gaya Artikel/Majalah)
  //    - Gambar landscape besar di atas (16:9 / tinggi tetap 190dp)
  //    - Badge kategori usia
  //    - Judul bold besar (maks 2 baris)
  //    - Baris metadata: penulis + tanggal
  // -------------------------------------------------------------------------

  Widget _buildRecipeCard(ResepMpasiModel recipe) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailResepPage(resep: _toDetailModel(recipe)),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: _colorWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------------------------------------------
              // Gambar resep landscape (190dp tinggi, full lebar card)
              // -------------------------------------------------------
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: _buildCardImage(recipe),
              ),

              // -------------------------------------------------------
              // Konten teks resep di bawah gambar
              // -------------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge kategori usia resep
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _colorSoftBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        recipe.kategoriUsia,
                        style: GoogleFonts.lato(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _colorPrimaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Judul resep — bold besar, maks 2 baris
                    Text(
                      recipe.judul,
                      style: GoogleFonts.lato(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: _colorDark,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Baris bawah: metadata resep + tanggal
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
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
                        const SizedBox(width: 8),
                        // Tanggal resep
                        Text(
                          recipe.tanggal,
                          style: GoogleFonts.lato(
                            fontSize: 11.5,
                            color: _colorTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gambar utama kartu artikel — tinggi 190dp, full lebar
  Widget _buildCardImage(ResepMpasiModel recipe) {
    final imagePath = recipe.displayImage;
    return SizedBox(
      width: double.infinity,
      height: 190,
      child: imagePath != null
          ? Image.asset(
              imagePath,
              width: double.infinity,
              height: 190,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _cardImageFallback(),
            )
          : _cardImageFallback(),
    );
  }

  /// Fallback ketika gambar resep tidak tersedia
  Widget _cardImageFallback() {
    return Container(
      width: double.infinity,
      height: 190,
      color: _colorSoftBlue,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.restaurant_menu_rounded,
            color: _colorPrimaryBlue,
            size: 40,
          ),
          const SizedBox(height: 6),
          Text(
            'Foto Belum Tersedia',
            style: GoogleFonts.lato(
              fontSize: 12,
              color: _colorPrimaryBlue.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 5. ERROR STATE
  // -------------------------------------------------------------------------

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
  // 6. SEAMLESS FOOTER ILLUSTRATION (FIXED)
  //    Ilustrasi lanskap tetap diam (stay/fixed) di bagian bawah.
  //    Dilengkapi dengan feather gradient overlay di batas atas agar menyatu
  //    secara mulus tanpa garis potong dengan area putih scroll resep.
  // -------------------------------------------------------------------------

  Widget _buildSeamlessFooterIllustration() {
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          const IllustrationForestFooter(
            fit: BoxFit.fitWidth,
          ),
          // Gradient transparan halus di batas atas ilustrasi
          // agar menyatu tanpa garis batas potongan gambar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 42,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _colorWhite,
                    Color(0x00FFFFFF),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 7. BOTTOM NAVIGATION
  //    → Digantikan oleh PediaBottomNavBar(selectedIndex: -1) di build().
  //    → Tidak ada implementasi lokal; semua routing dikelola oleh widget
  //      terpusat agar konsisten dengan BerandaPage.
  // -------------------------------------------------------------------------

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