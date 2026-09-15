import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/artikel_service.dart';
import '../../../models/artikel_model.dart';
import '../../../shared/widgets/illustration_forest_footer.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';
import '../detail/detail_artikel_page.dart';

/// Halaman Artikel Kesehatan untuk pengguna PediaGrow.
///
/// Fitur & Spesifikasi:
/// 1. Scaffold dengan background putih murni.
/// 2. Header tetap (56dp): tombol back 12dp dari kiri, judul "Artikel Kesehatan"
///    12dp setelah tombol back (font Lato 20sp bold hitam).
/// 3. Search Bar dinamis: rounded corner, background abu-abu muda, ikon pencarian,
///    hint "Cari Artikel", tombol reset pencarian, dan filtering live real-time.
/// 4. Bottom Navigation Bar tetap di `Scaffold.bottomNavigationBar` (tidak ikut scroll).
/// 5. Konten utama dinamis terhubung ke [ArtikelService] (SQLite / PMIK database-ready).
/// 6. Empty State: Jika belum ada artikel dari PMIK atau pencarian nihil, tidak menampilkan
///    card artikel dan menampilkan ilustrasi pemandangan lanskap hutan/tenda di bagian bawah.
/// 7. Populated State: Card artikel sesuai referensi (kiri: judul, icon jam + kategori + topik,
///    tanggal publikasi; kanan: thumbnail rounded 18dp BoxFit.cover dengan placeholder fallback).
/// 8. Divider pemisah 1dp #E5E5E5 antar artikel.
/// 9. Navigasi ke [DetailArtikelPage] dengan animasi transisi fade/slide yang halus.
class ArtikelKesehatanPage extends StatefulWidget {
  const ArtikelKesehatanPage({super.key});

  @override
  State<ArtikelKesehatanPage> createState() => _ArtikelKesehatanPageState();
}

class _ArtikelKesehatanPageState extends State<ArtikelKesehatanPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ArtikelService _artikelService = ArtikelService();

  late final AnimationController _entryAnimController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  List<ArtikelModel> _displayedArticles = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Animasi masuk halus untuk halaman
    _entryAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entryAnimController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryAnimController,
        curve: Curves.easeOutCubic,
      ),
    );

    _searchController.addListener(_onSearchChanged);
    _loadArticles();

    _entryAnimController.forward();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _entryAnimController.dispose();
    super.dispose();
  }

  /// Memuat artikel dari database SQLite / PMIK service
  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    try {
      final articles = await _artikelService.getAllArticles();
      if (!mounted) return;
      setState(() {
        _displayedArticles = articles;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _displayedArticles = [];
        _isLoading = false;
      });
    }
  }

  /// Filter pencarian live real-time saat pengguna mengetik
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _searchQuery) return;

    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _displayedArticles = _artikelService.currentArticles;
      } else {
        _displayedArticles = _artikelService.filterArticles(query);
      }
    });
  }

  /// Reset kata kunci pencarian
  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  /// Navigasi kembali dengan transisi halus
  void _onBackPressed() {
    Navigator.of(context).maybePop();
  }

  /// Navigasi ke DetailArtikelPage dengan transisi halus
  void _navigateToDetail(ArtikelModel artikel) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DetailArtikelPage(artikel: artikel),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.06, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);
          final fadeAnimation =
              CurvedAnimation(parent: animation, curve: Curves.easeOut);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Navigation Bar tetap di Scaffold bagian bawah layar
      bottomNavigationBar: const PediaBottomNavBar(selectedIndex: -1),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER TETAP (56dp)
                _buildHeader(context),

                // 2. SEARCH BAR DINAMIS
                _buildSearchBar(),

                const SizedBox(height: 12),

                // 3. KONTEN UTAMA (DAFTAR ARTIKEL ATAU EMPTY STATE) DENGAN ILUSTRASI DI DASAR SEPERTI BERANDA
                Expanded(
                  child: Stack(
                    children: [
                      // Ilustrasi lanskap alam selalu terpaku menempel di bagian dasar, tepat di atas Navigation Bar seperti pada Beranda
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: IllustrationForestFooter(fit: BoxFit.fitWidth),
                        ),
                      ),

                      // Konten scrollable di atasnya
                      Positioned.fill(
                        child: _buildBodyContent(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header tetap 56dp: tombol back 12dp dari kiri dan judul "Artikel Kesehatan"
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      color: Colors.white,
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
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Judul Halaman
          Expanded(
            child: Text(
              'Artikel Kesehatan',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF000000),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Search Bar dinamis dengan rounded corners dan latar abu-abu muda
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F6),
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
                  color: const Color(0xFF000000),
                ),
                decoration: InputDecoration(
                  hintText: 'Cari Artikel',
                  hintStyle: GoogleFonts.lato(
                    fontSize: 15,
                    color: const Color(0xFFA0A0A0),
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

  /// Membangun konten utama sesuai ketersediaan data artikel
  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF72A9F4)),
        ),
      );
    }

    // EMPTY STATE: Database kosong dari PMIK atau pencarian tidak menghasilkan artikel
    if (_displayedArticles.isEmpty) {
      return _buildEmptyState();
    }

    // POPULATED STATE: Tampilkan daftar artikel scrollable
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 96),
      itemCount: _displayedArticles.length,
      separatorBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(
            height: 32,
            thickness: 1,
            color: Color(0xFFE5E5E5),
          ),
        );
      },
      itemBuilder: (context, index) {
        final artikel = _displayedArticles[index];
        return _buildArticleCardItem(artikel);
      },
    );
  }

  /// Empty State: Tidak menampilkan card artikel apa pun, ilustrasi tetap di dasar
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
                  : Icons.article_outlined,
              size: 56,
              color: const Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Artikel tidak ditemukan'
                  : 'Belum ada artikel kesehatan',
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
                  ? 'Tidak ada artikel yang cocok dengan kata kunci "$_searchQuery". Silakan coba kata kunci lain.'
                  : 'Artikel akan ditampilkan di sini setelah administrator PMIK menambahkan data artikel.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13,
                color: const Color(0xFF9E9E9E),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 60), // Memberi ruang dari footer
          ],
        ),
      ),
    );
  }

  /// Card/Item artikel kesehatan sesuai proporsi dan struktur desain referensi
  Widget _buildArticleCardItem(ArtikelModel artikel) {
    return InkWell(
      onTap: () => _navigateToDetail(artikel),
      splashColor: const Color(0x10000000),
      highlightColor: const Color(0x08000000),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Kiri: Judul, Metadata (Jam, Kategori, Sub-topik), dan Tanggal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul Artikel (Lato 16sp hitam, max 3 baris dengan ellipsis)
                  Text(
                    artikel.judul,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF000000),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Metadata: Ikon Jam + "Artikel" + Topik/Subkategori
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Color(0xFFA0A0A0),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _buildMetadataString(artikel),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFA0A0A0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tanggal dibuat (contoh: "26 Agustus 2026")
                  Text(
                    artikel.tanggal,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFA0A0A0),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Bagian Kanan: Thumbnail gambar artikel (rounded 18dp, BoxFit.cover)
            _buildThumbnail(artikel),
          ],
        ),
      ),
    );
  }

  /// Menyusun string metadata kategori & sub-topik (contoh: "Artikel  •  Apa itu Stunting?")
  String _buildMetadataString(ArtikelModel artikel) {
    final buffer = StringBuffer(artikel.kategori);
    if (artikel.subKategori.isNotEmpty) {
      for (final sub in artikel.subKategori) {
        buffer.write('   •   $sub');
      }
    }
    return buffer.toString();
  }

  /// Thumbnail artikel dengan sudut membulat modern dan placeholder fallback
  Widget _buildThumbnail(ArtikelModel artikel) {
    const double thumbWidth = 124;
    const double thumbHeight = 84;
    const double borderRadius = 18;

    final displayImage = artikel.displayImage;

    return Container(
      width: thumbWidth,
      height: thumbHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F6),
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
        child: displayImage == null
            ? _buildThumbnailPlaceholder()
            : (artikel.isAssetImage
                ? Image.asset(
                    displayImage,
                    width: thumbWidth,
                    height: thumbHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildThumbnailPlaceholder(),
                  )
                : Image.network(
                    displayImage,
                    width: thumbWidth,
                    height: thumbHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildThumbnailPlaceholder(),
                  )),
      ),
    );
  }

  /// Placeholder jika gambar artikel belum tersedia / gagal dimuat
  Widget _buildThumbnailPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFEEEEEE),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: Color(0xFFBDBDBD),
        ),
      ),
    );
  }
}
