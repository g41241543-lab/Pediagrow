import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../beranda/beranda_page.dart';
import '../konsultasi/daftar_dokter_page.dart';
import '../profil/menu_profil_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_page.dart';
import 'models/fasyankes_model.dart';
import 'services/fasyankes_service.dart';
import 'widgets/fasyankes_card_item.dart';
import 'widgets/fasyankes_map_widget.dart';
import '../../../shared/widgets/illustration_forest_footer.dart';

/// Halaman Lokasi Fasilitas Pelayanan Kesehatan (Fasyankes) PediaGrow
///
/// Fitur:
/// - Header fixed 56dp (tidak ikut scroll) dengan tombol kembali 12dp dari kiri
///   dan judul "Lokasi Fasyankes" berjarak 12dp setelahnya.
/// - Search bar "Cari Lokasi" pill-shaped keyboard-aware.
/// - Google Maps interaktif dengan switch Map/Satellite dan kontrol zoom in/out.
/// - Daftar maksimal 10 fasyankes terdekat dengan efek 3D card elevation,
///   nama Lato 18sp bold, telepon, rating bintang kuning, dan aksi "Buka di Maps".
/// - Penanganan state komprehensif (loading, empty, error).
/// - Ilustrasi landscape pepohonan & tenda di footer menempel ke nav bar.
/// - Bottom Navigation Bar fixed (Beranda, Konsultasi, Riwayat Konsultasi, Profil).
class LokasiFasyankesPage extends StatefulWidget {
  const LokasiFasyankesPage({super.key});

  @override
  State<LokasiFasyankesPage> createState() => _LokasiFasyankesPageState();
}

class _LokasiFasyankesPageState extends State<LokasiFasyankesPage> {
  // Service
  final FasyankesService _service = FasyankesService();

  // Search & Controller
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  // State Data
  List<FasyankesModel> _fasyankesList = [];
  FasyankesModel? _selectedFasyankes;
  bool _isLoading = true;
  String? _errorMessage;

  // Koordinat pengguna (default: Jember sesuai referensi desain)
  double _userLat = FasyankesService.defaultLat;
  double _userLng = FasyankesService.defaultLng;

  // Navigasi Bottom Bar — -1 berarti tidak ada tab yang aktif
  final int _selectedNavIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadFasyankes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Memuat data fasyankes dari service
  Future<void> _loadFasyankes({String query = ''}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getNearestFasyankes(
        userLat: _userLat,
        userLng: _userLng,
        query: query,
      );

      if (!mounted) return;
      setState(() {
        _fasyankesList = list;
        _isLoading = false;
        // Pilih item pertama secara default jika ada
        if (list.isNotEmpty && _selectedFasyankes == null) {
          _selectedFasyankes = list.first;
        } else if (list.isNotEmpty &&
            !list.any((item) => item.id == _selectedFasyankes?.id)) {
          _selectedFasyankes = list.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data fasyankes. Silakan coba lagi.';
      });
    }
  }

  /// Pencarian dengan debounce 350ms agar hemat resource & API request
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _loadFasyankes(query: value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    _loadFasyankes(query: '');
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BerandaPage()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const DaftarDokterPage()));
        break;
      case 2:
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const DaftarRiwayatPage()));
        break;
      case 3:
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const MenuProfilPage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1014) : Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildFixedHeader(isDark),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBarSection(isDark),
                      FasyankesMapWidget(
                        fasyankesList: _fasyankesList,
                        selectedFasyankes: _selectedFasyankes,
                        userLat: _userLat,
                        userLng: _userLng,
                        onFasyankesSelected: (fasyankes) {
                          setState(() => _selectedFasyankes = fasyankes);
                        },
                        onLocateUser: () {
                          setState(() {
                            _userLat = FasyankesService.defaultLat;
                            _userLng = FasyankesService.defaultLng;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildFasyankesListContent(isDark),
                      const SizedBox(height: 16),
                      _buildFooterIllustration(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildFixedNavBar(isDark),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER TETAP (Tinggi 56dp)
  // ===========================================================================
  Widget _buildFixedHeader(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      color: isDark ? const Color(0xFF0B1014) : Colors.white,
      padding: const EdgeInsets.only(left: 12, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back,
                color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lokasi Fasyankes',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. SEARCH BAR "CARI LOKASI FASYANKES"
  // ===========================================================================
  Widget _buildSearchBarSection(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0B1014) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF1F2F6),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 22,
              color: isDark ? const Color(0xFF667781) : const Color(0xFF9E9E9E),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (val) {
                  setState(() {});
                  _onSearchChanged(val);
                },
                textInputAction: TextInputAction.search,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                ),
                decoration: InputDecoration(
                  hintText: 'Cari Lokasi Fasyankes',
                  hintStyle: GoogleFonts.lato(
                    fontSize: 15,
                    color: isDark ? const Color(0xFF667781) : const Color(0xFFA0A0A0),
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {});
                  _clearSearch();
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFF667781) : const Color(0xFF9E9E9E),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. LIST CARD FASYANKES / STATE VIEWS
  // ===========================================================================
  Widget _buildFasyankesListContent(bool isDark) {
    // A. State Loading
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2B7AE8),
            strokeWidth: 2.8,
          ),
        ),
      );
    }

    // B. State Error
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadFasyankes(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B7AE8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Coba Lagi',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // C. State Kosong (Empty)
    if (_fasyankesList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_off_outlined,
                size: 50,
                color: Color(0xFF8696A0),
              ),
              const SizedBox(height: 12),
              Text(
                'Tidak ada fasilitas kesehatan ditemukan',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Coba gunakan kata kunci pencarian yang lain.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // D. Daftar Fasyankes (Maksimal 10 Fasyankes Terdekat)
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _fasyankesList.length,
      itemBuilder: (context, index) {
        final fasyankes = _fasyankesList[index];
        final isSelected = _selectedFasyankes?.id == fasyankes.id;

        return FasyankesCardItem(
          fasyankes: fasyankes,
          isSelected: isSelected,
          onTap: () {
            setState(() => _selectedFasyankes = fasyankes);
          },
        );
      },
    );
  }

  // ===========================================================================
  // 4. ILUSTRASI FOOTER LANDSCAPE (Menempel ke Nav Bar)
  // ===========================================================================
  Widget _buildFooterIllustration() {
    return const IllustrationForestFooter(fit: BoxFit.fitWidth);
  }

  // ===========================================================================
  // 5. NAVIGATION BAR FIXED (Tinggi 68dp, #F2EDED)
  // ===========================================================================
  Widget _buildFixedNavBar(bool isDark) {
    final navItems = [
      const _NavData(icon: Icons.home_rounded, label: 'Beranda'),
      const _NavData(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
      const _NavData(
        icon: Icons.manage_search_rounded,
        label: 'Riwayat Konsultasi',
      ),
      const _NavData(icon: Icons.person_outline_rounded, label: 'Profil'),
    ];

    return Container(
      width: double.infinity,
      height: 68,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF2EDED),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(navItems.length, (i) {
          final isSelected = i == _selectedNavIndex;
          final item = navItems[i];

          return GestureDetector(
            onTap: () => _onNavTap(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 80,
              height: 68,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected) ...[
                    // State aktif: lingkaran putih dengan ikon biru #72A9F4
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0B1014) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        item.icon,
                        size: 24,
                        color: const Color(0xFF72A9F4),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
                      ),
                    ),
                  ] else ...[
                    Icon(
                      item.icon,
                      size: 24,
                      color: isDark ? const Color(0xFF667781) : const Color(0xFF9E9E9E),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: isDark ? const Color(0xFF667781) : const Color(0xFF9E9E9E),
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

class _NavData {
  final IconData icon;
  final String label;

  const _NavData({required this.icon, required this.label});
}
