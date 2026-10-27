import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/artikel_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../models/artikel_model.dart';
import '../../../shared/widgets/illustration_forest_footer.dart';
import '../../../shared/widgets/pedia_banner.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';
import '../../features/dokter/beranda/beranda_dokter_page.dart';
import '../../features/pengguna/detail/detail_artikel_page.dart';
import '../../features/pmik_admin/beranda/beranda_pmik_page.dart';
import '../../features/pmik_superadmin/beranda/beranda_superadmin_page.dart';
import '../../../core/services/staff_auth_service.dart';
import '../../../models/staff_account_model.dart';
import 'form_artikel_page.dart';

/// Halaman "Daftar Artikel" untuk peran PMIK Superadmin dan Dokter (read-only).
class DaftarArtikelPage extends StatefulWidget {
  final bool isReadOnly;

  const DaftarArtikelPage({super.key, this.isReadOnly = false});

  @override
  State<DaftarArtikelPage> createState() => _DaftarArtikelPageState();
}

class _DaftarArtikelPageState extends State<DaftarArtikelPage> {
  // Service terpusat yang sama persis dengan halaman pengguna
  final ArtikelService _artikelService = ArtikelService();

  bool get isReadOnly =>
      widget.isReadOnly ||
      StaffAuthService().currentStaff?.role == StaffRole.dokter;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<ArtikelModel> _allArticles = [];
  List<ArtikelModel> _filteredArticles = [];

  bool _isLoading = true;
  String? _errorMessage;

  // Konstanta warna sesuai panduan desain
  static const Color _colorDarkGray = Color(0xFF7F7F7F);
  static const Color _colorLightGray = Color(0xFFC5C5C5);
  static const Color _colorPrimaryBlue = Color(0xFF3985E7);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _scaffoldBg => _isDark ? const Color(0xFF0B1014) : Colors.white;
  Color get _cardBg => _isDark ? const Color(0xFF1A2228) : Colors.white;
  Color get _borderColor => _isDark ? const Color(0xFF2C363D) : const Color(0xFFE5E7EB);
  Color get _textBlack => _isDark ? const Color(0xFFE9EDEF) : Colors.black;
  Color get _textGrey => _isDark ? const Color(0xFF8696A0) : _colorDarkGray;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadArticles();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Mengambil data artikel dari sumber data terpusat (Firestore / SQLite / PMIK service)
  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final articles = await _artikelService.getAllArticles();
      if (!mounted) return;

      setState(() {
        _allArticles = articles;
        _applySearchFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      // Fallback graceful ke currentArticles atau seedArticles jika offline/test
      final fallback = _artikelService.currentArticles.isNotEmpty
          ? _artikelService.currentArticles
          : ArtikelModel.seedArticles;

      setState(() {
        if (fallback.isNotEmpty) {
          _allArticles = fallback;
          _applySearchFilter();
          _isLoading = false;
        } else {
          _errorMessage = 'Gagal memuat artikel: $e';
          _isLoading = false;
        }
      });
    }
  }

  /// Filter pencarian real-time berdasarkan judul dan tag / kategori artikel
  void _onSearchChanged() {
    setState(() {
      _applySearchFilter();
    });
  }

  void _applySearchFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _filteredArticles = List.of(_allArticles);
    } else {
      _filteredArticles = _allArticles.where((artikel) {
        final matchJudul = artikel.judul.toLowerCase().contains(query);
        final matchKategori = artikel.kategori.toLowerCase().contains(query);
        final matchSubKategori = artikel.subKategori.any(
          (sub) => sub.toLowerCase().contains(query),
        );
        return matchJudul || matchKategori || matchSubKategori;
      }).toList();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  /// Navigasi ke Form Tambah Artikel
  Future<void> _navigateToTambahArtikel() async {
    final result = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const FormArtikelPage()));

    if (result == true && mounted) {
      await _loadArticles();
    }
  }

  /// Navigasi ke Form Edit/Ubah Artikel dengan data artikel terpilih
  Future<void> _navigateToEditArtikel(ArtikelModel artikel) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => FormArtikelPage(artikel: artikel)),
    );

    if (result == true && mounted) {
      await _loadArticles();
    }
  }

  /// Menampilkan dialog konfirmasi hapus artikel sebelum aksi penghapusan dilakukan
  Future<void> _confirmDeleteArtikel(ArtikelModel artikel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor:
          Colors.black54, // Latar belakang gelap transparan sesuai desain
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          elevation: 4,
          backgroundColor: _cardBg,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Judul Dialog "Hapus Data"
                Text(
                  'Hapus Data',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: _textBlack,
                  ),
                ),
                const SizedBox(height: 12.0),

                // Pesan Konfirmasi Sesuai Desain
                Text(
                  'Mohon pastikan ulang sebelum menghapus Artikel. Apakah anda yakin ingin menghapus?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    color: _textGrey,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24.0),

                // Dua Tombol Aksi: "Ya" di kiri dan "Tidak" di kanan
                Row(
                  children: [
                    // Tombol "Ya" (Background putih, border abu-abu, teks biru)
                    Expanded(
                      child: SizedBox(
                        height: 44.0,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(true),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _cardBg,
                            side: BorderSide(
                              color: _isDark
                                  ? const Color(0xFF2C363D)
                                  : const Color(0xFFD1D7DB),
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Ya',
                            style: GoogleFonts.lato(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: _colorPrimaryBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),

                    // Tombol "Tidak" (Background biru, teks putih)
                    Expanded(
                      child: SizedBox(
                        height: 44.0,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _colorPrimaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: Text(
                            'Tidak',
                            style: GoogleFonts.lato(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    // Jika pengguna memilih "Tidak" atau menutup dialog, batalkan proses
    if (confirmed != true || !mounted) return;

    try {
      // Dapatkan ID artikel yang dipilih pengguna
      final targetId = artikel.id;

      if (targetId != null && targetId.isNotEmpty) {
        // Hapus dari sumber data bersama (Firestore / ArtikelService)
        await _artikelService.hapusArtikel(targetId);
      } else {
        // Fallback untuk data lokal / seed jika tanpa ID dokumen
        setState(() {
          _allArticles.removeWhere((a) => a.judul == artikel.judul);
          _applySearchFilter();
        });
      }

      // Perbarui daftar artikel pada halaman Superadmin
      await _loadArticles();
    } catch (e) {
      if (mounted) {
        // Tampilkan pesan error jelas jika gagal dan jangan hapus dari daftar
        PediaBanner.showError(context, message: 'Gagal menghapus artikel: $e');
      }
    }
  }

  void _navigateBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      final staff = StaffAuthService().currentStaff;
      final isDokter = staff?.role == StaffRole.dokter;
      final isPmik = staff?.role == StaffRole.admin;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => isDokter
              ? const BerandaDokterPage()
              : isPmik
                  ? const BerandaPmikPage()
                  : const BerandaSuperadminPage(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _navigateBack();
      },
      child: Scaffold(
        backgroundColor: _scaffoldBg,
        // Bottom Navigation Bar hanya untuk Superadmin/PMIK
        bottomNavigationBar: isReadOnly ? null : _buildBottomNavigationBar(),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              _buildHeader(),

              const SizedBox(height: 12.0),

              // 2. Search Bar Real-Time
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildSearchBar(),
              ),

              const SizedBox(height: 16.0),

              // 3. KONTEN UTAMA
              Expanded(child: _buildBodyContent()),
            ],
          ),
        ),
      ),
    );
  }

  /// Header di bagian atas dengan tinggi 56dp:
  Widget _buildHeader() {
    return Container(
      height: 56.0,
      width: double.infinity,
      color: _scaffoldBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Back (12dp dari kiri)
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _navigateBack,
                borderRadius: BorderRadius.circular(24.0),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.arrow_back,
                    size: 24.0,
                    color: _textBlack,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),

          // Judul Halaman "Daftar Artikel"
          Expanded(
            child: Text(
              'Daftar Artikel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: _textBlack,
              ),
            ),
          ),

          if (!isReadOnly)
            // Tombol Tambah berupa ikon plus di dalam lingkaran dengan garis tepi biru (16dp dari kanan)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _navigateToTambahArtikel,
                  borderRadius: BorderRadius.circular(20.0),
                  child: Container(
                    width: 38.0,
                    height: 38.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _colorPrimaryBlue, width: 1.8),
                      color: _isDark ? const Color(0xFF1A2228) : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.add,
                      size: 24.0,
                      color: _colorPrimaryBlue,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Search Bar dengan placeholder "Cari Artikel", background abu sangat muda,
  /// sudut rounded besar, dan warna ikon serta placeholder #7F7F7F
  Widget _buildSearchBar() {
    return Container(
      height: 48.0,
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1A2228) : const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: _isDark ? const Color(0xFF2C363D) : Colors.transparent,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 22.0, color: _textGrey),
          const SizedBox(width: 10.0),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: GoogleFonts.lato(fontSize: 15.0, color: _textBlack),
              decoration: InputDecoration(
                hintText: 'Cari Artikel',
                hintStyle: GoogleFonts.lato(
                  fontSize: 15.0,
                  color: _textGrey,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close_rounded,
                  size: 18.0,
                  color: _textGrey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Memilih widget berdasarkan status data (Loading, Error, Empty, atau Daftar Kartu)
  Widget _buildBodyContent() {
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

    if (_filteredArticles.isEmpty) {
      return _buildEmptyState();
    }

    // Daftar Kartu Artikel yang dapat di-scroll vertikal dengan ilustrasi di bagian paling bawah
    return CustomScrollView(
      // Clamping: tidak memantul, sehingga tidak ada celah putih di atas bottom nav.
      // AlwaysScrollable: tetap konsisten walau konten pendek.
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final artikel = _filteredArticles[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildArticleCard(artikel),
              );
            }, childCount: _filteredArticles.length),
          ),
        ),

        // Ilustrasi pemandangan pohon, tenda & bukit tepat di bawah seluruh artikel
        // (menyesuaikan jumlah artikel, ikut ter-scroll, dan berada di paling bawah tanpa celah/gap dengan footer dashboard)
        // Ilustrasi menempel di dasar layar jika artikel sedikit,
        // dan tepat di akhir daftar jika artikel banyak (tanpa jarak ekstra)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [IllustrationForestFooter(fit: BoxFit.fitWidth)],
          ),
        ),
      ],
    );
  }

  /// Kartu Artikel mengikuti acuan desain dan seragam dengan kartu Resep MPASI:
  /// - Sudut rounded 18dp, border tipis abu muda, shadow halus
  /// - Dapat diklik (InkWell) untuk membuka halaman detail artikel
  /// - Thumbnail berukuran 124x84dp dengan rounded 18dp
  /// - Judul artikel tebal hitam (Lato 16sp bold, max 3 baris dengan ellipsis)
  /// - Informasi meta: ikon jam, teks "Artikel", tag/kategori dipisah titik (Lato 12sp #A0A0A0)
  /// - Garis pemisah horizontal tipis
  /// - Tanggal artikel di kiri (Lato 12sp #A0A0A0)
  /// - Tombol hapus (background & border merah muda, ikon tempat sampah merah)
  /// - Tombol edit (background & border biru muda, ikon pensil biru)
  Widget _buildArticleCard(ArtikelModel artikel) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: _borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: _isDark ? Colors.black.withOpacity(0.2) : const Color(0x0A000000),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(18.0),
          onTap: () => _navigateToDetailArtikel(artikel),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Konten Atas: Thumbnail + Judul & Meta Info
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail foto artikel berukuran seragam 124x84dp dengan sudut rounded 18dp
                    _buildThumbnail(artikel),
                    const SizedBox(width: 14.0),

                    // Judul & Meta Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Judul artikel (Lato 16sp bold hitam, maksimal 3 baris dengan ellipsis)
                          Text(
                            artikel.judul,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: _textBlack,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8.0),

                          // Informasi Meta (Ikon jam + "Artikel • ...") warna #A0A0A0
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14.0,
                                color: _textGrey,
                              ),
                              const SizedBox(width: 5.0),
                              Expanded(
                                child: Text(
                                  _buildMetaText(artikel),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                    fontSize: 12.0,
                                    color: _textGrey,
                                    fontWeight: FontWeight.normal,
                                  ),
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

              // Garis pemisah horizontal tipis
              Divider(
                height: 1.0,
                thickness: 1.0,
                color: _borderColor,
              ),

              // Konten Bawah: Tanggal Artikel di kiri & Dua Tombol Aksi di kanan
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 10.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tanggal Artikel (Lato 12sp warna #A0A0A0)
                    Expanded(
                      child: Text(
                        artikel.tanggal,
                        style: GoogleFonts.lato(
                          fontSize: 12.0,
                          color: _textGrey,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),

                    if (!isReadOnly)
                      // Tombol Hapus & Tombol Edit seragam dan proporsional
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tombol Hapus (background & border merah muda, ikon tempat sampah merah)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _confirmDeleteArtikel(artikel),
                              borderRadius: BorderRadius.circular(8.0),
                              child: Container(
                                width: 34.0,
                                height: 34.0,
                                decoration: BoxDecoration(
                                  color: _isDark
                                      ? const Color(0xFF3B1818)
                                      : const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: _isDark
                                        ? const Color(0xFF5C2424)
                                        : const Color(0xFFFFCDD2),
                                    width: 1.0,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFE53935),
                                  size: 18.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),

                          // Tombol Edit (background & border biru muda, ikon pensil biru)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _navigateToEditArtikel(artikel),
                              borderRadius: BorderRadius.circular(8.0),
                              child: Container(
                                width: 34.0,
                                height: 34.0,
                                decoration: BoxDecoration(
                                  color: _isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: _isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFBBDEFB),
                                    width: 1.0,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Color(0xFF1E88E5),
                                  size: 18.0,
                                ),
                              ),
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

  /// Navigasi ke DetailArtikelPage saat kartu artikel diklik
  void _navigateToDetailArtikel(ArtikelModel artikel) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DetailArtikelPage(artikel: artikel),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0.0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
    // Muat ulang daftar artikel jika ada perubahan saat kembali
    if (mounted) {
      _loadArticles();
    }
  }

  /// Membangun string meta informasi: "Artikel • Stunting • Wasting"
  String _buildMetaText(ArtikelModel artikel) {
    final buffer = StringBuffer(artikel.kategori);
    if (artikel.subKategori.isNotEmpty) {
      for (final sub in artikel.subKategori) {
        buffer.write(' • $sub');
      }
    }
    return buffer.toString();
  }

  /// Thumbnail gambar seragam dengan Resep MPASI (124x84dp, rounded 18dp)
  Widget _buildThumbnail(ArtikelModel artikel) {
    const double width = 124.0;
    const double height = 84.0;
    const double radius = 18.0;

    final image = artikel.displayImage;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF2C363D) : const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: StorageService.buildImageWidget(
          image,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorWidget: _buildPlaceholderImage(),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: _isDark ? const Color(0xFF2C363D) : const Color(0xFFF1F2F6),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 32.0,
        color: _textGrey,
      ),
    );
  }

  /// Empty State: Menampilkan teks pesan saat belum ada artikel / hasil cari nihil
  /// dengan ilustrasi yang berada di bagian bawah
  Widget _buildEmptyState() {
    final isSearching = _searchController.text.trim().isNotEmpty;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSearching
                          ? Icons.search_off_rounded
                          : Icons.article_outlined,
                      size: 54.0,
                      color: _textGrey,
                    ),
                    const SizedBox(height: 14.0),
                    Text(
                      isSearching
                          ? 'Artikel tidak ditemukan'
                          : 'Belum ada artikel',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: _textBlack,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      isSearching
                          ? 'Tidak ada artikel yang sesuai dengan kata kunci "${_searchController.text.trim()}".'
                          : 'Belum ada artikel yang ditambahkan. Gunakan tombol (+) di atas untuk menambahkan artikel baru.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 13.0,
                        color: _textGrey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              const IllustrationForestFooter(fit: BoxFit.fitWidth),
            ],
          ),
        ),
      ],
    );
  }

  /// Error State jika data gagal dimuat dari server
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52.0,
              color: Color(0xFFE53935),
            ),
            const SizedBox(height: 12.0),
            Text(
              'Gagal Memuat Data',
              style: GoogleFonts.lato(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: _textBlack,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              _errorMessage ??
                  'Terjadi kesalahan saat menghubungkan ke database.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 13.0, color: _textGrey),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: _loadArticles,
              icon: const Icon(Icons.refresh_rounded, size: 18.0),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorPrimaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return const PediaBottomNavBar(selectedIndex: -1);
  }
}
