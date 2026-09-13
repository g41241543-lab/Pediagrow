import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/doctor_model.dart';
import '../beranda/beranda_page.dart';
import '../profil/menu_profil_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_page.dart';
import 'profil_dokter_page.dart';

/// Halaman Daftar Dokter Spesialis Anak PediaGrow.
///
/// Memungkinkan pengguna mencari dan memilih dokter spesialis anak.
/// Mengetuk dokter membuka [ProfilDokterPage] yang menyediakan rincian
/// lengkap serta tombol "Chat Dokter" menuju [MenungguPersetujuanPage].
class DaftarDokterPage extends StatefulWidget {
  const DaftarDokterPage({super.key});

  @override
  State<DaftarDokterPage> createState() => _DaftarDokterPageState();
}

class _DaftarDokterPageState extends State<DaftarDokterPage> {
  // Design Tokens Resmi PediaGrow
  static const Color colorPrimaryBlue = Color(0xFF2A85FF);
  static const Color colorSoftBlue = Color(0xFFEBF5FF);
  static const Color colorTextPrimary = Color(0xFF1A202C);
  static const Color colorTextSecondary = Color(0xFF718096);
  static const Color colorBorder = Color(0xFFE2E8F0);
  static const Color colorOnlineGreen = Color(0xFF48BB78);

  final TextEditingController _searchController = TextEditingController();
  final int _selectedNavIndex = 1; // Tab Konsultasi aktif

  List<DoctorModel> _allDoctors = [];
  List<DoctorModel> _filteredDoctors = [];

  @override
  void initState() {
    super.initState();
    _allDoctors = DoctorModel.dummyList;
    _filteredDoctors = _allDoctors;

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredDoctors = _allDoctors;
      } else {
        _filteredDoctors = _allDoctors.where((doc) {
          final matchName = doc.name.toLowerCase().contains(query);
          final matchSpec = doc.specialization.toLowerCase().contains(query);
          final matchHospital =
              doc.hospital?.toLowerCase().contains(query) ?? false;
          return matchName || matchSpec || matchHospital;
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToDoctorProfile(DoctorModel doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilDokterPage(doctor: doctor),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BerandaPage()),
          (route) => false,
        );
        break;
      case 1:
        // Sudah di Konsultasi Dokter
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header Tetap
            _buildFixedHeader(),

            // 2. Kolom Pencarian
            _buildSearchBar(),

            // 3. Banner Edukasi Ringkas
            _buildInfoBanner(),

            // 4. Daftar Dokter
            Expanded(
              child: _filteredDoctors.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _filteredDoctors.length,
                      itemBuilder: (context, index) {
                        return _buildDoctorCard(_filteredDoctors[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFixedNavBar(),
    );
  }

  // ===========================================================================
  // 1. HEADER TETAP (56dp)
  // ===========================================================================

  Widget _buildFixedHeader() {
    final canPop = Navigator.of(context).canPop();

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (canPop)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(context).maybePop(),
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: colorTextPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 4),
          const SizedBox(width: 8),
          Text(
            'Konsultasi Dokter',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. SEARCH BAR
  // ===========================================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.lato(fontSize: 14, color: colorTextPrimary),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Cari dokter spesialis anak...',
            hintStyle: GoogleFonts.lato(
              fontSize: 14,
              color: const Color(0xFFA0AEC0),
            ),
            icon: const Icon(Icons.search_rounded,
                color: Color(0xFFA0AEC0), size: 22),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: const Icon(Icons.clear_rounded,
                        size: 18, color: Color(0xFFA0AEC0)),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. BANNER EDUKASI
  // ===========================================================================

  Widget _buildInfoBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorSoftBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_outlined,
              size: 20,
              color: colorPrimaryBlue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Dokter spesialis anak terverifikasi IDAI dan aktif praktik.',
                style: GoogleFonts.lato(
                  fontSize: 12.5,
                  color: const Color(0xFF2B6CB0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. KARTU DOKTER
  // ===========================================================================

  Widget _buildDoctorCard(DoctorModel doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDoctorProfile(doctor),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Dokter dengan Border & Badge Online
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF1F5F9),
                        border: Border.all(color: colorBorder, width: 1.5),
                      ),
                      child: ClipOval(
                        child: doctor.assetImagePath != null &&
                                doctor.assetImagePath!.isNotEmpty
                            ? Image.asset(
                                doctor.assetImagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  size: 32,
                                  color: colorTextSecondary,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 32,
                                color: colorTextSecondary,
                              ),
                      ),
                    ),
                    if (doctor.isOnline)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colorOnlineGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Data Dokter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: GoogleFonts.lato(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: colorTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.specialization,
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: colorPrimaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.work_outline_rounded,
                            size: 14,
                            color: colorTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${doctor.experienceYears} thn pengalaman',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: colorTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tombol "Lihat"
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorSoftBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Pilih',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorPrimaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 56,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            'Dokter tidak ditemukan',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Silakan coba kata kunci nama atau spesialisasi lain.',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: colorTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. NAVIGATION BAR TETAP (68dp, #F2EDED)
  // ===========================================================================

  Widget _buildFixedNavBar() {
    final navItems = [
      _NavData(icon: Icons.home_rounded, label: 'Beranda'),
      _NavData(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
      _NavData(
          icon: Icons.manage_search_rounded, label: 'Riwayat Konsultasi'),
      _NavData(icon: Icons.person_outline_rounded, label: 'Profil Ibu'),
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
                    Icon(
                      item.icon,
                      size: 24,
                      color: const Color(0xFF9E9E9E),
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
