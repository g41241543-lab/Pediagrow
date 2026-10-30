import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/fasyankes_model.dart';
import 'services/fasyankes_service.dart';
import 'widgets/fasyankes_card_item.dart';
import 'widgets/fasyankes_map_widget.dart';
import '../../../shared/widgets/illustration_forest_footer.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';

/// Halaman Lokasi Fasilitas Pelayanan Kesehatan (Fasyankes) PediaGrow
///
/// Fitur Lengkap:
/// - Header fixed 56dp dengan tombol kembali dan judul "Lokasi Fasyankes".
/// - Search bar "Cari Lokasi Fasyankes" pill-shaped keyboard-aware.
/// - Status Banner Lokasi Perangkat Real-Time (GPS device tracking).
/// - Google Maps interaktif dengan switch Map/Satellite dan kontrol zoom.
/// - Deteksi titik koordinat perangkat HP pengguna secara langsung (bukan hanya default).
/// - Daftar fasyankes terdekat dari lokasi pengguna, diperkaya data terdaftar di Google Maps:
///   rating bintang, ulasan pengguna asli, jam operasional, foto fasilitas, nomor telepon, dan Plus Code.
/// - Load instan 0ms tanpa blocking loading spinner.
/// - Ilustrasi landscape footer menempel ke nav bar.
/// - Fixed Bottom Navigation Bar.
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

  // Stream Subscription GPS
  StreamSubscription<Position>? _positionStreamSub;

  // State Data: Langsung siap pada frame pertama tanpa layar loading
  List<FasyankesModel> _fasyankesList = [];
  FasyankesModel? _selectedFasyankes;
  final bool _isLoading = false;
  String? _errorMessage;

  // Koordinat pengguna: Default Polije Tegalgede, lalu otomatis disinkronkan dengan posisi real perangkat HP
  double _userLat = FasyankesService.defaultLat;
  double _userLng = FasyankesService.defaultLng;

  // Status GPS Perangkat Pengguna
  bool _isDeviceLocationDetected = false;
  bool _isLocationServiceEnabled = true;
  LocationPermission _locationPermission = LocationPermission.unableToDetermine;
  final bool _autoCenterUser = true;


  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 1. Tampilkan data fasyankes terverifikasi secara instan (0ms tanpa blocking loading)
    _fasyankesList = _service.getLocalFasyankesInstant(
      userLat: _userLat,
      userLng: _userLng,
    );
    if (_fasyankesList.isNotEmpty) {
      _selectedFasyankes = _fasyankesList.first;
    }

    // 2. Ambil titik koordinat terkini pengguna dari sensor GPS perangkat HP
    _initDeviceLocationTracking();

    // 3. Sinkronisasi online di latar belakang tanpa menghambat UI
    _syncFasyankesOnlineBackground();
  }

  /// Inisialisasi pelacakan lokasi fisik perangkat HP pengguna
  Future<void> _initDeviceLocationTracking() async {
    // A. Cek status layanan lokasi (GPS) pada perangkat
    final serviceEnabled = await _service.isLocationServiceEnabled();
    if (!mounted) return;
    setState(() => _isLocationServiceEnabled = serviceEnabled);

    if (!serviceEnabled) {
      debugPrint('LokasiFasyankesPage: Layanan lokasi perangkat tidak aktif');
      return;
    }

    // B. Cek & minta izin lokasi
    var permission = await _service.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _service.requestPermission();
    }
    if (!mounted) return;
    setState(() => _locationPermission = permission);

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('LokasiFasyankesPage: Izin lokasi ditolak');
      return;
    }

    // C. Ambil last known position untuk update instan jika ada
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        _updateUserCoordinates(lastKnown.latitude, lastKnown.longitude);
      }
    } catch (_) {}

    // D. Dapatkan lokasi real-time presisi tinggi dari sensor GPS
    try {
      final currentPos = await _service.getCurrentDeviceLocation(forceHighAccuracy: true);
      if (currentPos != null && mounted) {
        _updateUserCoordinates(currentPos.latitude, currentPos.longitude);
      }
    } catch (_) {}

    // E. Dengarkan stream posisi GPS perangkat jika pengguna berpindah tempat
    _positionStreamSub?.cancel();
    _positionStreamSub = _service.getPositionStream().listen(
      (position) {
        if (mounted) {
          _updateUserCoordinates(position.latitude, position.longitude);
        }
      },
      onError: (err) {
        debugPrint('Position stream error: $err');
      },
    );
  }

  /// Memperbarui koordinat posisi perangkat pengguna dan menghitung ulang jarak fasyankes
  void _updateUserCoordinates(double lat, double lng) {
    setState(() {
      _userLat = lat;
      _userLng = lng;
      _isDeviceLocationDetected = true;
      _isLocationServiceEnabled = true;

      // Hitung ulang dan urutkan fasyankes terdekat dari lokasi fisik perangkat pengguna
      _fasyankesList = _service.getLocalFasyankesInstant(
        userLat: _userLat,
        userLng: _userLng,
        query: _searchController.text,
      );

      if (_fasyankesList.isNotEmpty &&
          (_selectedFasyankes == null ||
              !_fasyankesList.any((item) => item.id == _selectedFasyankes?.id))) {
        _selectedFasyankes = _fasyankesList.first;
      }
    });
  }

  /// Aksi tombol "Lokasi Saya" pada peta untuk memusatkan kembali ke lokasi fisik HP
  Future<void> _onLocateUserPressed() async {
    // Pastikan service dan izin aktif
    final serviceEnabled = await _service.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() => _isLocationServiceEnabled = false);
      _promptEnableLocationService();
      return;
    }

    var permission = await _service.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _service.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() => _locationPermission = permission);
      _promptLocationPermission();
      return;
    }

    final position = await _service.getCurrentDeviceLocation(forceHighAccuracy: true);
    if (position != null && mounted) {
      _updateUserCoordinates(position.latitude, position.longitude);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lokasi Anda terpusat: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
                  style: GoogleFonts.lato(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2B7AE8),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _promptEnableLocationService() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Layanan lokasi (GPS) HP Anda belum aktif.'),
        action: SnackBarAction(
          label: 'Nyalakan',
          textColor: Colors.amber,
          onPressed: () => _service.openLocationSettings(),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _promptLocationPermission() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Izin akses lokasi diperlukan untuk menentukan fasyankes terdekat.'),
        action: SnackBarAction(
          label: 'Buka Pengaturan',
          textColor: Colors.amber,
          onPressed: () => _service.openAppSettings(),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Sinkronisasi online fasyankes di latar belakang tanpa blocking loading
  Future<void> _syncFasyankesOnlineBackground({String query = ''}) async {
    try {
      final list = await _service.getNearestFasyankes(
        userLat: _userLat,
        userLng: _userLng,
        query: query,
      );

      if (!mounted) return;
      if (list.isNotEmpty) {
        setState(() {
          _fasyankesList = list;
          if (_selectedFasyankes == null ||
              !list.any((item) => item.id == _selectedFasyankes?.id)) {
            _selectedFasyankes = list.first;
          }
        });
      }
    } catch (_) {
      // Tetap gunakan data instan yang sudah tampil
    }
  }

  /// Memuat / memfilter data fasyankes secara instan tanpa layar loading
  void _loadFasyankes({String query = ''}) {
    final list = _service.getLocalFasyankesInstant(
      userLat: _userLat,
      userLng: _userLng,
      query: query,
    );

    setState(() {
      _fasyankesList = list;
      if (list.isNotEmpty &&
          (_selectedFasyankes == null ||
              !list.any((item) => item.id == _selectedFasyankes?.id))) {
        _selectedFasyankes = list.first;
      }
    });

    _syncFasyankesOnlineBackground(query: query);
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
                      // Status Banner Koordinat Pengguna
                      _buildLocationStatusBanner(isDark),
                      // Peta Interaktif
                      FasyankesMapWidget(
                        fasyankesList: _fasyankesList,
                        selectedFasyankes: _selectedFasyankes,
                        userLat: _userLat,
                        userLng: _userLng,
                        autoCenterUserOnLocationChange: _autoCenterUser,
                        onFasyankesSelected: (fasyankes) {
                          setState(() => _selectedFasyankes = fasyankes);
                        },
                        onLocateUser: _onLocateUserPressed,
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
        bottomNavigationBar: const PediaBottomNavBar(selectedIndex: -1),
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
  // 3. STATUS BANNER KOORDINAT PENGGUNA (GPS Real-Time Device)
  // ===========================================================================
  Widget _buildLocationStatusBanner(bool isDark) {
    // Kasus 1: Layanan lokasi (GPS) mati di HP
    if (!_isLocationServiceEnabled) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.35) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFFDC2626) : const Color(0xFFFECACA),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off_rounded, size: 18, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Layanan lokasi belum aktif. Nyalakan GPS agar koordinat sesuai posisi HP Anda.',
                style: GoogleFonts.lato(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () async {
                await _service.openLocationSettings();
                _initDeviceLocationTracking();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Nyalakan',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Kasus 2: Izin lokasi ditolak
    if (_locationPermission == LocationPermission.denied ||
        _locationPermission == LocationPermission.deniedForever) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFFD97706) : const Color(0xFFFDE68A),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.fmd_bad_rounded, size: 18, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Izin lokasi diperlukan agar koordinat pengguna terdeteksi dari posisi HP Anda.',
                style: GoogleFonts.lato(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () async {
                if (_locationPermission == LocationPermission.deniedForever) {
                  await _service.openAppSettings();
                } else {
                  await _initDeviceLocationTracking();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Izinkan',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Kasus 3: Lokasi fisik HP berhasil terdeteksi secara real-time
    if (_isDeviceLocationDetected) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFF10B981)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Lokasi HP Terdeteksi (${_userLat.toStringAsFixed(4)}, ${_userLng.toStringAsFixed(4)})',
                style: GoogleFonts.lato(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                ),
              ),
            ),
            GestureDetector(
              onTap: _onLocateUserPressed,
              child: Text(
                'Pusatkan',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Kasus 4: Sedang mencari sinyal GPS
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF2B7AE8),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Menghubungkan sensor GPS perangkat...',
            style: GoogleFonts.lato(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF8696A0) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. LIST CARD FASYANKES / STATE VIEWS
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

    // D. Daftar Fasyankes (Maksimal 10 Fasyankes Terdekat dari Lokasi Fisik Pengguna)
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _fasyankesList.length,
      itemBuilder: (context, index) {
        final fasyankes = _fasyankesList[index];
        final isSelected = _selectedFasyankes?.id == fasyankes.id;

        return FasyankesCardItem(
          key: ValueKey(fasyankes.id),
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
  // 5. ILUSTRASI FOOTER LANDSCAPE (Menempel ke Nav Bar)
  // ===========================================================================
  Widget _buildFooterIllustration() {
    return const IllustrationForestFooter(fit: BoxFit.fitWidth);
  }

}
