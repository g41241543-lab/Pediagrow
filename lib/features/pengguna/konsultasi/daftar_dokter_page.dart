import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pediagrow/core/services/child_service.dart';

import '../../../core/services/child_service.dart';
import '../../../core/services/doctor_service.dart';
import '../../../models/doctor_model.dart';
import '../../../shared/widgets/illustration_forest_footer.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';
import '../../../core/services/notification_service.dart';
import '../beranda/beranda_page.dart';
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
///    - Tombol pill biru "Detail Dokter" -> navigasi ke [ProfilDokterPage] dengan animasi halus
/// 5. Ilustrasi dekoratif pohon, rumput, dan tenda ([IllustrationForestFooter]) di bagian bawah konten
/// 6. Navigation Bar Tetap (Scaffold bottomNavigationBar) dengan menu Konsultasi aktif
class DaftarDokterPage extends StatefulWidget {
  const DaftarDokterPage({super.key});

  @override
  State<DaftarDokterPage> createState() => _DaftarDokterPageState();
}

class _DaftarDokterPageState extends State<DaftarDokterPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Navigasi ke detail dokter dengan slide + fade transition (halaman sub, bukan tab)
  void _navigateToDetail(DoctorModel doctor) {
    _searchFocusNode.unfocus();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProfilDokterPage(doctor: doctor, child: ChildService().activeChild),
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
            child: FadeTransition(opacity: animation, child: child),
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
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            // Kembali ke Beranda dengan FadeTransition (seragam dengan tab lain)
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const BerandaPage(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) => FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 200),
              ),
              (route) => false,
            );
          }
        },
        child: SafeArea(
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
                                    final filteredDoctors = _searchQuery.isEmpty
                                        ? allDoctors
                                        : DoctorService().filterDoctors(
                                            _searchQuery,
                                          );

                                    if (filteredDoctors.isEmpty) {
                                      return _buildEmptyState();
                                    }

                                    return Column(
                                      children: [
                                        for (
                                          int i = 0;
                                          i < filteredDoctors.length;
                                          i++
                                        ) ...[
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
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

                                // Spacer fleksibel agar ilustrasi tetap menempel di bawah
                                const Spacer(),

                                const SizedBox(height: 20),

                                // Ilustrasi Pemandangan Hutan, Rumput & Tenda (Reusable)
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
              ],
            ),
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

  /// Navigasi ke halaman Notifikasi dengan animasi FadeTransition konsisten
  void _navigateToNotification() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NotifikasiPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  /// Header tetap di atas (56dp)
  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 12.0),
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
            const SizedBox(width: 8),

            // Lingkaran Notifikasi (31×31, #FFFFFF, 12dp dari kanan) + badge angka
            ValueListenableBuilder<int>(
              valueListenable: NotificationService().unreadCountNotifier,
              builder: (context, unreadCount, _) {
                return GestureDetector(
                  onTap: _navigateToNotification,
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
                      // Badge angka notifikasi belum dibaca
                      if (unreadCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53E3E),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 1),
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

  /// Card Profil Dokter dengan hover effect & desain premium
  Widget _buildDoctorCard(DoctorModel doctor) {
    const colorPrimaryBlue = Color(0xFF3985E7);
    const colorBlueShadow = Color(0xFF2B7AE8);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDetail(doctor),
          splashColor: colorPrimaryBlue.withValues(alpha: 0.08),
          highlightColor: colorPrimaryBlue.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sisi Atas: Avatar + Informasi Dokter
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar Dokter dengan Badge Status Online
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECF6FF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: colorPrimaryBlue.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildAvatar(doctor),
                        ),
                        // Indikator Status Online
                        Positioned(
                          bottom: 0,
                          right: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: doctor.isOnline
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF94A3B8),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (doctor.isOnline
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF94A3B8))
                                          .withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
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
                          // Status online teks kecil
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: doctor.isOnline
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF94A3B8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                doctor.isOnline ? 'Online' : 'Offline',
                                style: GoogleFonts.lato(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: doctor.isOnline
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Nama Dokter
                          Text(
                            doctor.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Chip Spesialis
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              doctor.specialization,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                fontSize: 11.5,
                                color: colorBlueShadow,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Pengalaman Kerja
                          Row(
                            children: [
                              const Icon(
                                Icons.business_center_outlined,
                                size: 14,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '${doctor.experienceYears} tahun pengalaman',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
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

                // Divider
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                ),

                // Sisi Bawah: Tombol "Detail Dokter" biru
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToDetail(doctor),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: colorPrimaryBlue,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: colorPrimaryBlue.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Detail Dokter',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
