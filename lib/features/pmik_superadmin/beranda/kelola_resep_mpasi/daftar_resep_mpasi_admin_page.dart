import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/resep_mpasi_service.dart';
import '../../../../models/resep_mpasi_model.dart';
import '../../../../shared/widgets/illustration_forest_footer.dart';
import '../../../../shared/widgets/pedia_banner.dart';
import '../../../pengguna/mpasi/detail_resep_page.dart';
import '../../konsultasi/konsultasi_superadmin_page.dart';
import '../../profil/profil_superadmin_page.dart';
import '../../riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import '../beranda_superadmin_page.dart';
import 'edit_resep_mpasi_page.dart';
import 'tambah_resep_mpasi_page.dart';

/// Halaman "Daftar Resep MPASI" untuk Superadmin / PMIK.
///
/// Fitur:
/// 1. Header dengan tombol kembali, judul "Daftar Resep MPASI", dan tombol tambah (+)
///    lingkaran biru yang mengarah ke [TambahResepMpasiPage].
/// 2. Search bar "Cari Resep MPASI".
/// 3. Filter chips kategori usia: Semua, 6-8 bulan, 9-11 bulan, 12-23 bulan, 24+ bulan.
/// 4. Kartu resep dengan thumbnail, judul, keterangan usia, tanggal,
///    tombol hapus (merah muda) dan tombol ubah (biru muda).
///    Klik bagian atas kartu membuka [DetailResepPage] (sama dengan tampilan pengguna).
/// 5. Dialog konfirmasi hapus data ("Hapus Data", tombol "Ya" dan "Tidak").
/// 6. Bottom Navigation Bar konsisten dengan Superadmin.
/// 7. Otomatis terhubung dengan database Cloud Firestore dan memicu notifikasi Superadmin.
class DaftarResepMpasiAdminPage extends StatefulWidget {
  const DaftarResepMpasiAdminPage({super.key});

  @override
  State<DaftarResepMpasiAdminPage> createState() =>
      _DaftarResepMpasiAdminPageState();
}

class _DaftarResepMpasiAdminPageState extends State<DaftarResepMpasiAdminPage> {
  final ResepMpasiService _service = ResepMpasiService();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  String _selectedCategory = 'Semua';

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

  static const Color _colorPrimaryBlue = Color(0xFF2A85FF);
  static const Color _colorDark = Color(0xFF0F172A);
  static const Color _colorMuted = Color(0xFF94A3B8);

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
        _errorMessage = 'Gagal memuat resep MPASI: $e';
        _isLoading = false;
      });
    }
  }

  void _onCategoryChanged(String category) {
    if (category == _selectedCategory) return;
    setState(() => _selectedCategory = category);
    _loadRecipes();
  }

  Future<void> _navigateToTambahResep() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TambahResepMpasiPage()),
    );

    if (result == true && mounted) {
      await _loadRecipes();
      if (!mounted) return;
      PediaBanner.showSuccess(
        context,
        message: 'Berhasil Menyimpan Resep Baru',
      );
    }
  }

  Future<void> _navigateToEditResep(ResepMpasiModel resep) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditResepMpasiPage(resep: resep)),
    );

    if (result == true && mounted) {
      await _loadRecipes();
      if (!mounted) return;
      PediaBanner.showSuccess(context, message: 'Berhasil Menyimpan Perubahan');
    }
  }

  /// Membuka halaman Detail Resep (halaman yang sama dengan POV pengguna).
  void _navigateToDetailResep(ResepMpasiModel resep) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailResepPage(resepModel: resep)),
    );
  }

  Future<void> _confirmDeleteResep(ResepMpasiModel resep) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
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
                Text(
                  'Hapus Data',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: _colorDark,
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'Mohon pastikan ulang sebelum menghapus resep MPASI. Apakah anda yakin ingin menghapus?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    color: const Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24.0),
                Row(
                  children: [
                    // Tombol "Ya" di kiri
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
                    // Tombol "Tidak" di kanan
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

    if (confirmed != true || !mounted) return;

    try {
      final targetId = resep.id;
      if (targetId != null && targetId.isNotEmpty) {
        await _service.deleteResep(targetId, judul: resep.judul);
      } else {
        setState(() {
          _recipes.removeWhere((r) => r.judul == resep.judul);
        });
      }

      await _loadRecipes();

      if (mounted) {
        PediaBanner.showSuccess(
          context,
          message: 'Berhasil Menghapus Resep MPASI',
        );
      }
    } catch (e) {
      if (mounted) {
        PediaBanner.showError(context, message: 'Gagal menghapus resep: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8.0),
            _buildSearchBar(),
            const SizedBox(height: 12.0),
            _buildCategoryFilter(),
            const SizedBox(height: 12.0),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(24.0),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.arrow_back, size: 24.0, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              'Daftar Resep MPASI',
              style: GoogleFonts.lato(
                fontSize: 19.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          // Tombol tambah lingkaran bergaris biru (+)
          GestureDetector(
            onTap: _navigateToTambahResep,
            child: Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _colorPrimaryBlue, width: 2.0),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add,
                size: 20.0,
                color: _colorPrimaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 44.0,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: GoogleFonts.lato(fontSize: 14.0, color: _colorDark),
          decoration: InputDecoration(
            hintText: 'Cari Resep MPASI',
            hintStyle: GoogleFonts.lato(fontSize: 14.0, color: _colorMuted),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF94A3B8),
              size: 22.0,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      size: 18.0,
                      color: Color(0xFF94A3B8),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _searchFocusNode.unfocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 38.0,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => _onCategoryChanged(cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isSelected
                      ? _colorPrimaryBlue
                      : const Color(0xFFCBD5E1),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Text(
                cat,
                style: GoogleFonts.lato(
                  fontSize: 13.0,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? _colorPrimaryBlue
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_colorPrimaryBlue),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48.0,
                color: Colors.red,
              ),
              const SizedBox(height: 12.0),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(color: _colorDark, fontSize: 14.0),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _loadRecipes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colorPrimaryBlue,
                ),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 56.0,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12.0),
            Text(
              'Belum ada resep MPASI',
              style: GoogleFonts.lato(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4.0),
            for (final resep in _recipes)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildRecipeCard(resep),
              ),

            // Spacer fleksibel agar ilustrasi menempel di dasar bila item sedikit
            const Spacer(),

            const SizedBox(height: 16.0),

            // Ilustrasi footer scrollable (sama seperti daftar_pengguna_page)
            const IllustrationForestFooter(fit: BoxFit.fitWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(ResepMpasiModel resep) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian atas: Thumbnail + Judul & Kategori (klik → Detail Resep)
          GestureDetector(
            onTap: () => _navigateToDetailResep(resep),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: SizedBox(
                      width: 96.0,
                      height: 76.0,
                      child: _buildThumbnailImage(resep),
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resep.judul,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: _colorDark,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 14.0,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4.0),
                            Flexible(
                              child: Text(
                                'Resep MPASI • ${resep.kategoriUsia}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 12.0,
                                  color: const Color(0xFF94A3B8),
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

          // Divider pemisah horizontal
          const Divider(height: 1.0, thickness: 1.0, color: Color(0xFFF1F5F9)),

          // Bagian bawah: Tanggal + Tombol Hapus & Edit
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Text(
                  resep.tanggal,
                  style: GoogleFonts.lato(
                    fontSize: 12.0,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const Spacer(),
                // Tombol Hapus (merah muda)
                GestureDetector(
                  onTap: () => _confirmDeleteResep(resep),
                  child: Container(
                    width: 32.0,
                    height: 32.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEC),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 18.0,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                // Tombol Edit (biru muda)
                GestureDetector(
                  onTap: () => _navigateToEditResep(resep),
                  child: Container(
                    width: 32.0,
                    height: 32.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0EFFF),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF2A85FF),
                      size: 18.0,
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

  Widget _buildThumbnailImage(ResepMpasiModel resep) {
    final img = resep.displayImage;
    if (img == null || img.isEmpty) {
      return Container(
        color: const Color(0xFFF1F5F9),
        child: const Icon(
          Icons.restaurant_menu_rounded,
          color: Color(0xFFCBD5E1),
          size: 32.0,
        ),
      );
    }

    if (kIsWeb || img.startsWith('http://') || img.startsWith('https://')) {
      return Image.network(
        img,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFFCBD5E1),
          ),
        ),
      );
    }

    if (img.startsWith('assets/')) {
      return Image.asset(
        img,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Icon(
            Icons.restaurant_menu_rounded,
            color: Color(0xFFCBD5E1),
          ),
        ),
      );
    }

    return Image.file(
      File(img),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFF1F5F9),
        child: const Icon(
          Icons.broken_image_outlined,
          color: Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final navItems = [
      const _NavItem(icon: Icons.home_rounded, label: 'Beranda'),
      const _NavItem(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
      const _NavItem(
        icon: Icons.manage_search_rounded,
        label: 'Riwayat Konsultasi',
      ),
      const _NavItem(icon: Icons.person_rounded, label: 'Profil'),
    ];

    return Container(
      width: double.infinity,
      height: 68.0,
      decoration: const BoxDecoration(
        color: Color(0xFFF2EDED),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(navItems.length, (i) {
            final isSelected =
                i == 0; // Beranda aktif karena berada dalam modul Beranda
            final item = navItems[i];

            return Expanded(
              child: GestureDetector(
                onTap: () => _onNavTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 68.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4.0,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            item.icon,
                            size: 22.0,
                            color: const Color(0xFF72A9F4),
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 11.0,
                                fontWeight: FontWeight.normal,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Icon(
                          item.icon,
                          size: 24.0,
                          color: const Color(0xFF9E9E9E),
                        ),
                        const SizedBox(height: 3.0),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                fontSize: 11.0,
                                fontWeight: FontWeight.normal,
                                color: const Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BerandaSuperadminPage()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const KonsultasiSuperadminPage()),
        );
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const DaftarRiwayatKonsultasiAdminPage(),
          ),
        );
        break;
      case 3:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfilSuperadminPage()),
        );
        break;
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
