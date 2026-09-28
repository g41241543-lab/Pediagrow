import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/artikel_service.dart';
import '../../../models/artikel_model.dart';
import '../../../shared/widgets/illustration_forest_footer.dart';
import '../../../shared/widgets/pedia_banner.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';
import '../../features/pmik_superadmin/beranda/beranda_superadmin_page.dart';
import '../../features/pmik_superadmin/konsultasi/konsultasi_superadmin_page.dart';
import '../../features/pmik_superadmin/profil/profil_superadmin_page.dart';
import '../../features/pmik_superadmin/riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import 'form_artikel_page.dart';

/// Halaman "Daftar Artikel" untuk peran PMIK Superadmin pada aplikasi PediaGrow.
///
/// Halaman ini terhubung langsung ke sumber data artikel yang sama dengan pengguna
/// melalui [ArtikelService] dan [ArtikelModel].
///
/// Fitur utama:
/// 1. Header berjarak 56dp dari atas layar dengan tombol back (12dp dari kiri),
///    judul "Daftar Artikel" (12dp setelah back), dan tombol tambah lingkaran bergaris
///    biru (16dp dari kanan).
/// 2. Search bar real-time dengan placeholder "Cari Artikel", ikon search #7F7F7F,
///    dan sudut rounded besar.
/// 3. Kartu artikel responsif dengan thumbnail rounded, judul hitam bold (maks 4 baris),
///    meta info (jam + kategori/tag artikel warna #C5C5C5), divider tipis, tanggal artikel (#C5C5C5),
///    tombol hapus (merah muda) dan tombol edit (biru muda).
/// 4. Dialog konfirmasi sebelum menghapus artikel.
/// 5. Navigasi tambah artikel & edit artikel ke [FormArtikelPage].
/// 6. Loading, empty state (teks "Belum ada artikel" & ilustrasi pohon, rumput, tenda),
///    serta error state dengan tombol coba lagi.
/// 7. Bottom Navigation Bar konsisten dengan dashboard beranda (bentuk, ukuran, font, ikon sama).
/// 8. Ilustrasi kumpulan pohon dan lanskap alam di atas dashboard footer seperti di halaman artikel pengguna.
class DaftarArtikelPage extends StatefulWidget {
  const DaftarArtikelPage({super.key});

  @override
  State<DaftarArtikelPage> createState() => _DaftarArtikelPageState();
}

class _DaftarArtikelPageState extends State<DaftarArtikelPage> {
  // Service terpusat yang sama persis dengan halaman pengguna
  final ArtikelService _artikelService = ArtikelService();

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
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const FormArtikelPage(),
      ),
    );

    if (result == true && mounted) {
      await _loadArticles();
      PediaBanner.showSuccess(
        context,
        message: 'Berhasil Menyimpan Artikel Baru',
      );
    }
  }

  /// Navigasi ke Form Edit/Ubah Artikel dengan data artikel terpilih
  Future<void> _navigateToEditArtikel(ArtikelModel artikel) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FormArtikelPage(artikel: artikel),
      ),
    );

    if (result == true && mounted) {
      await _loadArticles();
      PediaBanner.showSuccess(
        context,
        message: 'Berhasil Menyimpan Perubahan',
      );
    }
  }

  /// Menampilkan dialog konfirmasi hapus artikel sebelum aksi penghapusan dilakukan
  Future<void> _confirmDeleteArtikel(ArtikelModel artikel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54, // Latar belakang gelap transparan sesuai desain
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          elevation: 4,
          backgroundColor: Colors.white,
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
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12.0),

                // Pesan Konfirmasi Sesuai Desain
                Text(
                  'Mohon pastikan ulang sebelum menghapus Artikel. Apakah anda yakin ingin menghapus?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    color: const Color(0xFF64748B),
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
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFFCBD5E1),
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

      if (mounted) {
        // Notifikasi panel biru melayang dengan icon silang hitam di kanan
        PediaBanner.showSuccess(
          context,
          message: 'Berhasil Menghapus Artikel',
        );
      }
    } catch (e) {
      if (mounted) {
        // Tampilkan pesan error jelas jika gagal dan jangan hapus dari daftar
        PediaBanner.showError(
          context,
          message: 'Gagal menghapus artikel: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Bottom Navigation Bar konsisten dengan dashboard beranda (bentuk, ukuran, font, ikon)
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (tinggi 56dp, back 12dp dari kiri, judul 12dp setelahnya, tombol plus 16dp dari kanan)
            _buildHeader(),

            const SizedBox(height: 12.0),

            // 2. Search Bar Real-Time
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSearchBar(),
            ),

            const SizedBox(height: 16.0),

            // 3. KONTEN UTAMA (DAFTAR ARTIKEL ATAU EMPTY STATE) DENGAN ILUSTRASI DI DASAR SEPERTI HALAMAN ARTIKEL PENGGUNA
            Expanded(
              child: Stack(
                children: [
                  // Ilustrasi lanskap alam kumpulan pohon, tenda & rumput tepat di atas dashboard footer
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: IllustrationForestFooter(
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),

                  // Konten scrollable di atas ilustrasi
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildBodyContent(),
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

  /// Header di bagian atas dengan tinggi 56dp:
  /// - Tombol back berada 12dp dari tepi kiri layar
  /// - Judul "Daftar Artikel" berada 12dp setelah tombol back sejajar secara vertikal
  /// - Tombol tambah berupa ikon plus di dalam lingkaran bergaris tepi biru berjarak 16dp dari kanan
  Widget _buildHeader() {
    return Container(
      height: 56.0,
      width: double.infinity,
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Back (12dp dari kiri)
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(24.0),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.arrow_back,
                    size: 24.0,
                    color: Colors.black,
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
                color: Colors.black,
              ),
            ),
          ),

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
                    border: Border.all(
                      color: _colorPrimaryBlue,
                      width: 1.8,
                    ),
                    color: Colors.transparent,
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
        color: const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(16.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.search,
            size: 22.0,
            color: _colorDarkGray,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: GoogleFonts.lato(
                fontSize: 15.0,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Cari Artikel',
                hintStyle: GoogleFonts.lato(
                  fontSize: 15.0,
                  color: _colorDarkGray,
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
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close_rounded,
                  size: 18.0,
                  color: _colorDarkGray,
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

    // Daftar Kartu Artikel yang dapat di-scroll vertikal
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 4.0, bottom: 48.0),
      itemCount: _filteredArticles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16.0),
      itemBuilder: (context, index) {
        final artikel = _filteredArticles[index];
        return _buildArticleCard(artikel);
      },
    );
  }

  /// Kartu Artikel mengikuti acuan desain:
  /// - Sudut rounded, border tipis abu muda, shadow halus
  /// - Thumbnail dengan sudut rounded di sebelah kiri
  /// - Judul artikel tebal hitam (maksimal 4 baris, ellipsis)
  /// - Informasi meta: ikon jam, teks "Artikel", tag/kategori dipisah titik (warna #C5C5C5)
  /// - Garis pemisah horizontal tipis
  /// - Tanggal artikel di kiri (#C5C5C5)
  /// - Tombol hapus (background & border merah muda, icon tempat sampah merah)
  /// - Tombol edit (background & border biru muda, icon pensil biru)
  Widget _buildArticleCard(ArtikelModel artikel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Konten Atas: Thumbnail + Judul & Meta Info
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail foto artikel dengan sudut rounded
                _buildThumbnail(artikel),
                const SizedBox(width: 14.0),

                // Judul & Meta Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul artikel (maksimal 4 baris, ellipsis)
                      Text(
                        artikel.judul,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8.0),

                      // Informasi Meta (Ikon jam + "Artikel • ...") warna #C5C5C5
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14.0,
                            color: _colorLightGray,
                          ),
                          const SizedBox(width: 5.0),
                          Expanded(
                            child: Text(
                              _buildMetaText(artikel),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                fontSize: 12.0,
                                color: _colorLightGray,
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
          const Divider(
            height: 1.0,
            thickness: 1.0,
            color: Color(0xFFF1F5F9),
          ),

          // Konten Bawah: Tanggal Artikel di kiri & Dua Tombol Aksi di kanan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tanggal Artikel (warna #C5C5C5)
                Expanded(
                  child: Text(
                    artikel.tanggal,
                    style: GoogleFonts.lato(
                      fontSize: 13.0,
                      color: _colorLightGray,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),

                // Tombol Hapus & Tombol Edit
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
                          width: 36.0,
                          height: 36.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: const Color(0xFFFFCDD2),
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFE53935),
                            size: 20.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),

                    // Tombol Edit (background & border biru muda, ikon pensil biru)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _navigateToEditArtikel(artikel),
                        borderRadius: BorderRadius.circular(8.0),
                        child: Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: const Color(0xFFBBDEFB),
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFF1E88E5),
                            size: 20.0,
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
    );
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

  /// Thumbnail gambar dengan sudut rounded dan fallback placeholder
  Widget _buildThumbnail(ArtikelModel artikel) {
    const double width = 112.0;
    const double height = 82.0;
    const double radius = 12.0;

    final image = artikel.displayImage;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: image == null
            ? _buildPlaceholderImage()
            : (artikel.isAssetImage
                ? Image.asset(
                    image,
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  )
                : Image.network(
                    image,
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  )),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFFF1F2F6),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 32.0,
        color: _colorLightGray,
      ),
    );
  }

  /// Empty State: Menampilkan teks pesan saat belum ada artikel / hasil cari nihil
  Widget _buildEmptyState() {
    final isSearching = _searchController.text.trim().isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0, bottom: 80.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSearching ? Icons.search_off_rounded : Icons.article_outlined,
                size: 54.0,
                color: _colorLightGray,
              ),
              const SizedBox(height: 14.0),
              Text(
                isSearching ? 'Artikel tidak ditemukan' : 'Belum ada artikel',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF334155),
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
                  color: _colorDarkGray,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
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
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              _errorMessage ?? 'Terjadi kesalahan saat menghubungkan ke database.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13.0,
                color: _colorDarkGray,
              ),
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

  /// Bottom Navigation Bar mengikuti ukuran, bentuk, font, dan icon dashboard beranda
  Widget _buildBottomNavigationBar() {
    return PediaBottomNavBar(
      selectedIndex: -1,
      onNavTap: (index) {
        // Navigasi menu superadmin sesuai dengan dashboard beranda
        switch (index) {
          case 0:
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const BerandaSuperadminPage(),
                  transitionsBuilder: (_, animation, __, child) =>
                      FadeTransition(opacity: animation, child: child),
                  transitionDuration: const Duration(milliseconds: 200),
                ),
                (route) => false,
              );
            }
            break;
          case 1:
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const KonsultasiSuperadminPage(),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
            break;
          case 2:
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    const DaftarRiwayatKonsultasiAdminPage(),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
            break;
          case 3:
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const ProfilSuperadminPage(),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 200),
              ),
            );
            break;
        }
      },
    );
  }
}
