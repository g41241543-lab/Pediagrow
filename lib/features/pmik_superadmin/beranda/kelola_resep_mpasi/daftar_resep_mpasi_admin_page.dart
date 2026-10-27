import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/resep_mpasi_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../models/resep_mpasi_model.dart';
import '../../../../shared/widgets/illustration_forest_footer.dart';
import '../../../../shared/widgets/pedia_banner.dart';
import '../../../../shared/widgets/pedia_bottom_nav_bar.dart';
import '../../../pengguna/mpasi/detail_resep_page.dart';
import '../../../pmik_admin/beranda/beranda_pmik_page.dart';
import '../beranda_superadmin_page.dart';
import '../../../dokter/beranda/beranda_dokter_page.dart';
import '../../../../core/services/staff_auth_service.dart';
import '../../../../models/staff_account_model.dart';
import 'edit_resep_mpasi_page.dart';
import 'tambah_resep_mpasi_page.dart';

/// Halaman "Daftar Resep MPASI" untuk Superadmin / PMIK dan Dokter (read-only).
class DaftarResepMpasiAdminPage extends StatefulWidget {
  final bool isReadOnly;

  const DaftarResepMpasiAdminPage({super.key, this.isReadOnly = false});

  @override
  State<DaftarResepMpasiAdminPage> createState() =>
      _DaftarResepMpasiAdminPageState();
}

class _DaftarResepMpasiAdminPageState extends State<DaftarResepMpasiAdminPage> {
  final ResepMpasiService _service = ResepMpasiService();

  bool get isReadOnly {
    if (widget.isReadOnly) return true;
    final staff = StaffAuthService().currentStaff;
    if (staff == null) return false;
    if (staff.isSuperAdmin) return false;
    return !staff.hasPermission('edit_resep_mpasi');
  }

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

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _scaffoldBg => _isDark ? const Color(0xFF0B1014) : Colors.white;
  Color get _cardBg => _isDark ? const Color(0xFF1A2228) : Colors.white;
  Color get _borderColor => _isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);
  Color get _textBlack => _isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014);
  Color get _textGrey => _isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);

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
    }
  }

  Future<void> _navigateToEditResep(ResepMpasiModel resep) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditResepMpasiPage(resep: resep)),
    );

    if (result == true && mounted) {
      await _loadRecipes();
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
          backgroundColor: _cardBg,
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
                    color: _textBlack,
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'Mohon pastikan ulang sebelum menghapus resep MPASI. Apakah anda yakin ingin menghapus?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    color: _textGrey,
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
                            backgroundColor: _cardBg,
                            side: BorderSide(
                              color: _borderColor,
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
    } catch (e) {
      if (mounted) {
        PediaBanner.showError(context, message: 'Gagal menghapus resep: $e');
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
              onTap: _navigateBack,
              borderRadius: BorderRadius.circular(24.0),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.arrow_back, size: 24.0, color: _textBlack),
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
                color: _textBlack,
              ),
            ),
          ),
          if (!isReadOnly)
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
          color: _isDark ? const Color(0xFF1A2228) : const Color(0xFFE9EDEF),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: _borderColor),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: GoogleFonts.lato(fontSize: 14.0, color: _textBlack),
          decoration: InputDecoration(
            hintText: 'Cari Resep MPASI',
            hintStyle: GoogleFonts.lato(fontSize: 14.0, color: _textGrey),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _textGrey,
              size: 22.0,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 18.0,
                      color: _textGrey,
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
                color: isSelected
                    ? (_isDark ? const Color(0xFF1E3A5F) : Colors.white)
                    : _cardBg,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isSelected
                      ? _colorPrimaryBlue
                      : _borderColor,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Text(
                cat,
                style: GoogleFonts.lato(
                  fontSize: 13.0,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (_isDark ? const Color(0xFF60A5FA) : _colorPrimaryBlue)
                      : _textGrey,
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
                style: GoogleFonts.lato(color: _textBlack, fontSize: 14.0),
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
            Icon(
              Icons.receipt_long_outlined,
              size: 56.0,
              color: _borderColor,
            ),
            const SizedBox(height: 12.0),
            Text(
              'Belum ada resep MPASI',
              style: GoogleFonts.lato(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: _textGrey,
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
        color: _cardBg,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: _borderColor, width: 1.0),
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
                            color: _textBlack,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14.0,
                              color: _textGrey,
                            ),
                            const SizedBox(width: 4.0),
                            Flexible(
                              child: Text(
                                'Resep MPASI • ${resep.kategoriUsia}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 12.0,
                                  color: _textGrey,
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
          Divider(height: 1.0, thickness: 1.0, color: _borderColor),

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
                    color: _textGrey,
                  ),
                ),
                if (!isReadOnly) ...[
                  const Spacer(),
                  // Tombol Hapus (merah muda)
                  GestureDetector(
                    onTap: () => _confirmDeleteResep(resep),
                    child: Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        color: _isDark ? const Color(0xFF3B1818) : const Color(0xFFFFECEC),
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
                        color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFE0EFFF),
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
        color: _isDark ? const Color(0xFF222C33) : const Color(0xFFE9EDEF),
        child: Icon(
          Icons.restaurant_menu_rounded,
          color: _borderColor,
          size: 32.0,
        ),
      );
    }

    return StorageService.buildImageWidget(
      img,
      fit: BoxFit.cover,
      errorWidget: Container(
        color: _isDark ? const Color(0xFF222C33) : const Color(0xFFE9EDEF),
        child: Icon(
          Icons.restaurant_menu_rounded,
          color: _borderColor,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return const PediaBottomNavBar(selectedIndex: -1);
  }
}
