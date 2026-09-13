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
/// - Bottom Navigation Bar fixed (Beranda, Konsultasi, Riwayat Konsultasi, Profil Ibu).
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

  // Navigasi Bottom Bar
  final int _selectedNavIndex = 0;

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
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DaftarDokterPage()),
        );
        break;
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DaftarRiwayatPage()),
        );
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MenuProfilPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dismiss keyboard saat pengguna mengetuk area di luar input pencarian
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // -------------------------------------------------------------
              // 1. HEADER FIXED (56dp) — Tidak ikut scrolling
              // -------------------------------------------------------------
              _buildFixedHeader(),

              // -------------------------------------------------------------
              // 2. KONTEN UTAMA SCROLLABLE (Peta + List Card Fasyankes + Footer)
              // -------------------------------------------------------------
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // A. Search Bar "Cari Lokasi" di atas Peta
                      _buildSearchBarSection(),

                      // B. Peta Google Maps Interaktif
                      FasyankesMapWidget(
                        fasyankesList: _fasyankesList,
                        selectedFasyankes: _selectedFasyankes,
                        userLat: _userLat,
                        userLng: _userLng,
                        onFasyankesSelected: (fasyankes) {
                          setState(() => _selectedFasyankes = fasyankes);
                        },
                        onLocateUser: () {
                          // Tetapkan posisi pengguna ke koordinat default
                          setState(() {
                            _userLat = FasyankesService.defaultLat;
                            _userLng = FasyankesService.defaultLng;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      // C. Konten List Fasyankes / Loading / Empty / Error State
                      _buildFasyankesListContent(),

                      const SizedBox(height: 16),

                      // D. Ilustrasi Footer Landscape (Pepohonan & Tenda)
                      _buildFooterIllustration(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // -----------------------------------------------------------------
        // 3. BOTTOM NAVIGATION BAR FIXED — Menempel di Scaffold
        // -----------------------------------------------------------------
        bottomNavigationBar: _buildFixedNavBar(),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER TETAP (Tinggi 56dp)
  // Tombol Back 12dp dari sisi kiri layar, Judul 12dp setelah tombol back.
  // ===========================================================================
  Widget _buildFixedHeader() {
    return Container(
      width: double.infinity,
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.only(left: 12, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Kembali
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back,
                color: Color(0xFF000000),
                size: 24,
              ),
            ),
          ),

          // Jarak 12dp setelah tombol kembali
          const SizedBox(width: 12),

          // Judul Halaman "Lokasi Fasyankes" (Font Lato, Bold, #000000)
          Expanded(
            child: Text(
              'Lokasi Fasyankes',
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

  // ===========================================================================
  // 2. SEARCH BAR "CARI LOKASI" (Keyboard-Aware & Rounded)
  // ===========================================================================
  Widget _buildSearchBarSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD1D5DB), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  color: const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: 'Cari Lokasi',
                  hintStyle: GoogleFonts.lato(
                    fontSize: 14,
                    color: const Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9CA3AF)),
                onPressed: _clearSearch,
                splashRadius: 16,
              ),
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(
                Icons.search_rounded,
                size: 22,
                color: Color(0xFF6B7280),
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
  Widget _buildFasyankesListContent() {
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
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  color: const Color(0xFF64748B),
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
              const Icon(Icons.location_off_outlined,
                  size: 50, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              Text(
                'Tidak ada fasilitas kesehatan ditemukan',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Coba gunakan kata kunci pencarian yang lain.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
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
    return SizedBox(
      width: double.infinity,
      child: Image.asset(
        'assets/images/beranda_landscape_footer.jpg',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.bottomCenter,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 90,
          color: const Color(0xFFDCFCE7),
          alignment: Alignment.center,
          child: const Icon(
            Icons.park_outlined,
            size: 40,
            color: Color(0xFF10B981),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. NAVIGATION BAR FIXED (Tinggi 68dp, #F2EDED)
  // ===========================================================================
  Widget _buildFixedNavBar() {
    final navItems = [
      const _NavData(icon: Icons.home_rounded, label: 'Beranda'),
      const _NavData(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
      const _NavData(icon: Icons.manage_search_rounded, label: 'Riwayat Konsultasi'),
      const _NavData(icon: Icons.person_outline_rounded, label: 'Profil Ibu'),
    ];

    return Container(
      width: double.infinity,
      height: 68,
      decoration: const BoxDecoration(
        color: Color(0xFFF2EDED),
        boxShadow: [
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
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
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
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ] else ...[
                    // State tidak aktif: icon & label abu-abu #9E9E9E
                    Icon(item.icon, size: 24, color: const Color(0xFF9E9E9E)),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF9E9E9E),
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
