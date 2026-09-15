import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/doctor_service.dart';
import '../../../models/doctor_model.dart';
import '../../../shared/widgets/illustration_forest_footer.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';
import '../../../core/services/notification_service.dart';
import '../beranda/notifikasi_page.dart';
import 'profil_dokter_page.dart';

/// Halaman "Konsultasi Dokter" (Daftar Dokter) untuk Pengguna PediaGrow.
///
/// Halaman ini menampilkan:
/// 1. Header Tetap (56dp) di atas layar dengan judul "Konsultasi Dokter" & tombol notifikasi
/// 2. Search Bar dinamis dengan hint "Cari nama dokter..." (real-time filtering)
/// 3. Judul bagian "Daftar Dokter"
/// 4. Kartu Profil Dokter yang terhubung dengan [DoctorService] (data dari PMIK Superadmin/database)
///    - Foto profil + status online badge (lingkaran hijau)
///    - Nama dokter, kategori spesialis, dan lama pengalaman kerja
///    - Divider pemisah abu-abu #E5E5E5
///    - Tombol pill oranye "Detail Dokter" -> navigasi ke [ProfilDokterPage] dengan animasi halus
/// 5. Ilustrasi dekoratif pohon, rumput, dan tenda ([IllustrationForestFooter]) di bagian bawah konten
/// 6. Navigation Bar Tetap (Scaffold bottomNavigationBar) dengan menu Konsultasi aktif
class DaftarDokterPage extends StatefulWidget {
  const DaftarDokterPage({super.key});

  @override
  State<DaftarDokterPage> createState() => _DaftarDokterPageState();
}

class _DaftarDokterPageState extends State<DaftarDokterPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Animasi halus saat halaman pertama kali dibuka
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _navigateToDetail(DoctorModel doctor) {
    _searchFocusNode.unfocus();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProfilDokterPage(doctor: doctor),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => _searchFocusNode.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------------------------------------------------
              // 1. HEADER TETAP (56dp)
              // -------------------------------------------------------------
              _buildHeader(context),

              // -------------------------------------------------------------
              // 2. KONTEN SCROLLABLE
              // Search Bar + Title + Doctor Cards + Landscape Illustration
              // -------------------------------------------------------------
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 12),

                                  // Search Bar (Cari nama dokter)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: _buildSearchBar(),
                                  ),

                                  const SizedBox(height: 18),

                                  // Judul Bagian "Daftar Dokter"
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: Text(
                                      'Daftar Dokter',
                                      style: GoogleFonts.lato(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF000000),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Daftar Dokter Dinamis (Reaktif terhadap database/PMIK)
                                  ValueListenableBuilder<List<DoctorModel>>(
                                    valueListenable:
                                        DoctorService().doctorsNotifier,
                                    builder: (context, allDoctors, _) {
                                      final filteredDoctors =
                                          _searchQuery.isEmpty
                                              ? allDoctors
                                              : DoctorService()
                                                  .filterDoctors(_searchQuery);

                                      if (filteredDoctors.isEmpty) {
                                        return _buildEmptyState();
                                      }

                                      return Column(
                                        children: [
                                          for (int i = 0;
                                              i < filteredDoctors.length;
                                              i++) ...[
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                              ),
                                              child: _buildDoctorCard(
                                                filteredDoctors[i],
                                              ),
                                            ),
                                            if (i != filteredDoctors.length - 1)
                                              const SizedBox(height: 14),
                                          ],
                                        ],
                                      );
                                    },
                                  ),

                                  // Spacer fleksibel agar ketika konten pendek/kosong, ilustrasi tetap menempel di bawah
                                  const Spacer(),

                                  const SizedBox(height: 20),

                                  // Ilustrasi Pemandangan Hutan, Rumput & Tenda (Reusable)
                                  // Menutup halaman dan menempel tepat di bagian bawah konten sebelum Navigation Bar
                                  const IllustrationForestFooter(
                                    fit: BoxFit.fitWidth,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // -------------------------------------------------------------
      // 3. NAVIGATION BAR TETAP (Fixed di Scaffold)
      // Konsisten dengan BerandaPage dan MenuProfilPage
      // Menu Konsultasi aktif (index: 1)
      // -------------------------------------------------------------
      bottomNavigationBar: const PediaBottomNavBar(selectedIndex: 1),
    );
  }

  /// Header tetap di atas (56dp)
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Judul "Konsultasi Dokter" (16dp dari kiri, Lato Bold 20, #000000)
          Expanded(
            child: Text(
              'Konsultasi Dokter',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF000000),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Lingkaran Notifikasi (31×31) + badge angka
          ValueListenableBuilder<int>(
            valueListenable: NotificationService().unreadCountNotifier,
            builder: (context, unreadCount, _) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const NotifikasiPage()),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 31,
                      height: 31,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF1E293B),
                        size: 19,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53E3E),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.white, width: 1),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Search Bar dengan background abu-abu muda, sudut rounded, dan pencarian real-time
  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _searchFocusNode.hasFocus
              ? const Color(0xFF72A9F4)
              : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14.0, right: 10.0),
            child: Icon(
              Icons.search_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: GoogleFonts.lato(
                fontSize: 14,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Cari nama dokter...',
                hintStyle: GoogleFonts.lato(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Icon(
                  Icons.close_rounded,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Card Profil Dokter sesuai acuan desain
  Widget _buildDoctorCard(DoctorModel doctor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sisi Atas: Avatar + Informasi Dokter
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Dokter dengan Badge Status Online (Lingkaran Hijau)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildAvatar(doctor),
                    ),
                    // Indikator Status Online (Lingkaran hijau di sudut kanan atas avatar)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: doctor.isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // Informasi Dokter (Nama, Spesialis, Pengalaman)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama Dokter (Lato 16sp, #000000, Bold, maks 1 baris)
                      Text(
                        doctor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Kategori Spesialis (Lato 12sp, #A0A0A0)
                      Text(
                        doctor.specialization,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: const Color(0xFFA0A0A0),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Informasi Pengalaman Kerja (Ikon koper + teks)
                      Row(
                        children: [
                          const Icon(
                            Icons.business_center_outlined,
                            size: 15,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${doctor.experienceYears} tahun',
                            style: GoogleFonts.lato(
                              fontSize: 12.5,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Divider Garis Abu-abu #E5E5E5
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE5E5E5),
              ),
            ),

            // Sisi Bawah: Tombol "Detail Dokter" berbentuk pill di sebelah kanan
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => _navigateToDetail(doctor),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18.0,
                    vertical: 7.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA000),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33FFA000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Detail Dokter',
                    style: GoogleFonts.lato(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Avatar dokter dengan fallback cerdas
  Widget _buildAvatar(DoctorModel doctor) {
    if (doctor.assetImagePath != null && doctor.assetImagePath!.isNotEmpty) {
      return Image.asset(
        doctor.assetImagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackAvatar(),
      );
    }
    if (doctor.avatarUrl != null && doctor.avatarUrl!.isNotEmpty) {
      return Image.network(
        doctor.avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackAvatar(),
      );
    }
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() {
    return Container(
      color: const Color(0xFFECF6FF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 32,
        color: Color(0xFF3985E7),
      ),
    );
  }

  /// Tampilan jika belum ada dokter yang ditambahkan oleh PMIK atau hasil pencarian nihil
  Widget _buildEmptyState() {
    final isSearching = _searchQuery.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.medical_services_outlined,
              size: 36,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'Dokter Tidak Ditemukan'
                : 'Belum Ada Dokter Tersedia',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'Tidak ada dokter dengan kata kunci "$_searchQuery". Silakan coba kata kunci lain.'
                : 'Daftar dokter belum ditambahkan oleh administrator PMIK. Silakan periksa kembali nanti.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          if (isSearching) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Reset Pencarian',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
