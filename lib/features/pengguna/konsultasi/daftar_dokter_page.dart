import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/booking_service.dart';
import '../../../core/services/child_service.dart';
import '../../../core/services/doctor_service.dart';
import '../../../core/services/jadwal_dokter_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../models/booking_consultation_model.dart';
import '../../../models/doctor_model.dart';
import '../../../models/jadwal_praktik_model.dart';
import '../../../shared/widgets/illustration_forest_footer.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';
import '../beranda/beranda_page.dart';
import '../beranda/notifikasi_page.dart';
import 'profil_dokter_page.dart';

/// Halaman Konsultasi POV Pengguna di PediaGrow.
///
/// Memiliki dua tab sejajar (mirip tampilan superadmin):
/// 1. "Daftar Dokter" — daftar dokter aktif dengan filter pencarian dan tombol ke profil dokter.
/// 2. "Jadwal Konsultasi" — daftar riwayat jadwal booking yang telah dibuat bersama dokter,
///    dengan kartu yang memperjelas identitas anak (khususnya jika pengguna punya >1 anak).
class DaftarDokterPage extends StatefulWidget {
  final int initialTabIndex;

  const DaftarDokterPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<DaftarDokterPage> createState() => _DaftarDokterPageState();
}

class _DaftarDokterPageState extends State<DaftarDokterPage>
    with SingleTickerProviderStateMixin {
  // Palet Warna Resmi PediaGrow
  static const Color _colorPrimaryBlue = Color(0xFF3985E7);
  static const Color _colorTextBlack = Color(0xFF1E293B);
  static const Color _colorLabelGrey = Color(0xFF64748B);
  static const Color _colorCardBg = Color(0xFFFFFFFF);
  static const Color _colorBorder = Color(0xFFE2E8F0);

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Navigasi ke detail dokter (ProfilDokterPage)
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

  void _showBookingDetailModal(BookingConsultationModel booking) {
    final isFemale = booking.child.gender.toLowerCase() == 'perempuan';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF5FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Detail Booking',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _colorPrimaryBlue,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  booking.status,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Info Anak
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _colorBorder, width: 1),
              ),
              child: Row(
                children: [
                  _buildChildAvatar(
                    photoUrl: booking.child.photoUrl,
                    isFemale: isFemale,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.child.name,
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _colorTextBlack,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${booking.child.gender} • ${booking.child.ageDescription}',
                          style: GoogleFonts.lato(
                            fontSize: 12.5,
                            color: _colorLabelGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Jadwal
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: _colorPrimaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  booking.formattedDate,
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: _colorTextBlack,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: _colorPrimaryBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  booking.scheduledTimeSlot,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _colorTextBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Dokter
            Row(
              children: [
                const Icon(
                  Icons.medical_services_rounded,
                  size: 16,
                  color: _colorLabelGrey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${booking.doctor.name} (${booking.doctor.specialization})',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: _colorLabelGrey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFBFDBFE),
                  width: 0.8,
                ),
              ),
              child: Text(
                'Form keluhan akan diisi saat waktu jadwal booking tiba sebelum memulai obrolan dengan dokter.',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: _colorPrimaryBlue,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colorPrimaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Tutup',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: false,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
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
          child: Column(
            children: [
              // 1. Header (56dp)
              _buildHeader(context),

              // 2. Tab Bar (Daftar Dokter | Jadwal Konsultasi)
              _buildTabBar(),

              // 3. Tab Bar View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDaftarDokterTab(),
                    _buildJadwalKonsultasiTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PediaBottomNavBar(selectedIndex: 1),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 56,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Konsultasi Dokter',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _colorTextBlack,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Notifikasi Button
            ValueListenableBuilder<int>(
              valueListenable: NotificationService().unreadCountNotifier,
              builder: (context, unreadCount, _) {
                return GestureDetector(
                  onTap: _navigateToNotification,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _colorBorder, width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x10000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: _colorTextBlack,
                          size: 19,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: -3,
                          right: -3,
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

  // ─── TAB BAR ──────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: _colorPrimaryBlue, width: 3),
        ),
        dividerColor: const Color(0xFFE2E8F0),
        dividerHeight: 1,
        labelPadding: EdgeInsets.zero,
        labelStyle: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelColor: _colorTextBlack,
        unselectedLabelColor: _colorLabelGrey,
        tabs: [
          Tab(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Daftar Dokter'),
                const SizedBox(width: 6),
                ValueListenableBuilder<List<DoctorModel>>(
                  valueListenable: DoctorService().doctorsNotifier,
                  builder: (context, doctors, _) {
                    return _buildTabBadge(doctors.length, isFirstTab: true);
                  },
                ),
              ],
            ),
          ),
          Tab(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Jadwal Konsultasi'),
                const SizedBox(width: 6),
                ValueListenableBuilder<List<BookingConsultationModel>>(
                  valueListenable: BookingService().bookingsNotifier,
                  builder: (context, bookings, _) {
                    return _buildTabBadge(bookings.length, isFirstTab: false);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBadge(int count, {required bool isFirstTab}) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final isThisTabActive =
            (isFirstTab && _tabController.index == 0) ||
            (!isFirstTab && _tabController.index == 1);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: isThisTabActive ? _colorPrimaryBlue : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isThisTabActive ? Colors.white : _colorLabelGrey,
            ),
          ),
        );
      },
    );
  }

  // ─── TAB 1: DAFTAR DOKTER ──────────────────────────────────────────────────
  Widget _buildDaftarDokterTab() {
    return GestureDetector(
      onTap: () => _searchFocusNode.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildSearchBar(),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Dokter Tersedia',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _colorTextBlack,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Doctor List
                    ValueListenableBuilder<List<DoctorModel>>(
                      valueListenable: DoctorService().doctorsNotifier,
                      builder: (context, allDoctors, _) {
                        final filteredDoctors = _searchQuery.isEmpty
                            ? allDoctors
                            : DoctorService().filterDoctors(_searchQuery);

                        if (filteredDoctors.isEmpty) {
                          return _buildEmptyState();
                        }

                        return Column(
                          children: [
                            for (int i = 0; i < filteredDoctors.length; i++) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: _buildDoctorCard(filteredDoctors[i]),
                              ),
                              if (i != filteredDoctors.length - 1)
                                const SizedBox(height: 12),
                            ],
                          ],
                        );
                      },
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    const IllustrationForestFooter(fit: BoxFit.fitWidth),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Icon(
              Icons.search_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
              style: GoogleFonts.lato(
                fontSize: 14,
                color: _colorTextBlack,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Cari nama dokter...',
                hintStyle: GoogleFonts.lato(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w400,
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

  Widget _buildDoctorCard(DoctorModel doctor) {
    final badge = JadwalDokterService().getDoctorBadge(doctor.id);
    final isAvailableSoon = badge.type == DoctorBadgeType.tersediaHariIni ||
        badge.type == DoctorBadgeType.tersediaBesok;
    final borderColor = isAvailableSoon
        ? const Color(0xFFBFDBFE)
        : _colorBorder;

    return Container(
      decoration: BoxDecoration(
        color: _colorCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDetail(doctor),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar Dokter
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _colorPrimaryBlue.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildAvatar(doctor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge Jadwal Dinamis
                          _buildAvailabilityBadge(badge),
                          const SizedBox(height: 3),
                          Text(
                            doctor.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _colorTextBlack,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              doctor.specialization,
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                color: _colorPrimaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.business_center_outlined,
                                size: 13,
                                color: _colorLabelGrey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${doctor.experienceYears} tahun pengalaman',
                                  style: GoogleFonts.lato(
                                    fontSize: 11.5,
                                    color: _colorLabelGrey,
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToDetail(doctor),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 7.0,
                        ),
                        decoration: BoxDecoration(
                          color: _colorPrimaryBlue,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: _colorPrimaryBlue.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Detail Dokter',
                          style: GoogleFonts.lato(
                            fontSize: 12,
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

  /// Membangun badge ketersediaan jadwal dokter dengan warna yang sesuai
  Widget _buildAvailabilityBadge(DoctorBadgeInfo badge) {
    Color dotColor;
    Color textColor;
    String label = badge.label;

    switch (badge.type) {
      case DoctorBadgeType.tersediaHariIni:
        dotColor = const Color(0xFF10B981); // hijau
        textColor = const Color(0xFF059669);
        break;
      case DoctorBadgeType.tersediaBesok:
        dotColor = const Color(0xFF3B82F6); // biru
        textColor = const Color(0xFF2563EB);
        break;
      case DoctorBadgeType.jadwalTerdekat:
        dotColor = const Color(0xFFF59E0B); // kuning/amber
        textColor = const Color(0xFFD97706);
        break;
      case DoctorBadgeType.belumAdaJadwal:
        dotColor = const Color(0xFF94A3B8); // abu-abu
        textColor = const Color(0xFF64748B);
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  // ─── TAB 2: JADWAL KONSULTASI (POV PENGGUNA) ──────────────────────────────
  Widget _buildJadwalKonsultasiTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  // Banner Info Jadwal
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildUserScheduleBanner(),
                  ),
                  const SizedBox(height: 12),
                  // List Kartu Booking Pengguna
                  ValueListenableBuilder<List<BookingConsultationModel>>(
                    valueListenable: BookingService().bookingsNotifier,
                    builder: (context, bookings, _) {
                      if (bookings.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: _buildEmptyBookingsState(),
                        );
                      }

                      return Column(
                        children: bookings.map((booking) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: _buildUserBookingCard(booking),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Spacer(),
                  const IllustrationForestFooter(fit: BoxFit.fitWidth),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserScheduleBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _colorPrimaryBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _colorPrimaryBlue.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _colorPrimaryBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: _colorPrimaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jadwal Booking Saya',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _colorPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Daftar jadwal konsultasi yang telah Anda pesan bersama dokter anak.',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: _colorPrimaryBlue.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu Booking Pengguna dengan identitas anak yang jelas
  /// (sangat penting jika orang tua memiliki lebih dari 1 anak).
  Widget _buildUserBookingCard(BookingConsultationModel booking) {
    final isFemale = booking.child.gender.toLowerCase() == 'perempuan';

    return Container(
      decoration: BoxDecoration(
        color: _colorCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _colorBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Baris Atas: Identitas Anak (Pasien) & Badge Status ──────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                _buildChildAvatar(
                  photoUrl: booking.child.photoUrl,
                  isFemale: isFemale,
                  size: 42,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.child.name,
                              style: GoogleFonts.lato(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: _colorTextBlack,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF5FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              booking.status,
                              style: GoogleFonts.lato(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: _colorPrimaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: isFemale
                                  ? const Color(0xFFFDF2F8)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isFemale
                                    ? const Color(0xFFFBCFE8)
                                    : const Color(0xFFBFDBFE),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              isFemale ? 'Anak Perempuan' : 'Anak Laki-laki',
                              style: GoogleFonts.lato(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isFemale
                                    ? const Color(0xFFDB2777)
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            booking.child.ageDescription,
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: _colorLabelGrey,
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

          // ── Kotak Jadwal Tanggal & Jam ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _colorPrimaryBlue.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: _colorPrimaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.formattedDate,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _colorPrimaryBlue,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: _colorPrimaryBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    booking.scheduledTimeSlot,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _colorPrimaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // ── Baris Bawah: Dokter & Tombol Detail ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.medical_services_rounded,
                  size: 14,
                  color: _colorLabelGrey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    booking.doctor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 12.5,
                      color: _colorLabelGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showBookingDetailModal(booking),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _colorPrimaryBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Lihat Detail',
                      style: GoogleFonts.lato(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  Widget _buildEmptyBookingsState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.event_note_rounded,
            size: 32,
            color: _colorPrimaryBlue,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Belum Ada Jadwal Booking',
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _colorTextBlack,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Silakan pilih dokter di tab "Daftar Dokter" dan jadwalkan konsultasi untuk anak Anda.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontSize: 12.5,
            color: _colorLabelGrey,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(DoctorModel doctor) {
    if (doctor.assetImagePath != null && doctor.assetImagePath!.isNotEmpty) {
      return Image.asset(
        doctor.assetImagePath!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackAvatar(),
      );
    }
    final url = doctor.avatarUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('/') || url.startsWith('file://')) {
        final file = File(url.replaceFirst('file://', ''));
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackAvatar(),
        );
      }
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackAvatar(),
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
        size: 30,
        color: _colorPrimaryBlue,
      ),
    );
  }

  Widget _buildChildAvatar({
    required String? photoUrl,
    required bool isFemale,
    required double size,
  }) {
    final bgColor =
        isFemale ? const Color(0xFFFFE4E6) : const Color(0xFFDBEAFE);

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: bgColor,
            child: CustomPaint(painter: _BabyFacePainter(isGirl: isFemale)),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: CustomPaint(painter: _BabyFacePainter(isGirl: isFemale)),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchQuery.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
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
              size: 32,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isSearching
                ? 'Dokter Tidak Ditemukan'
                : 'Belum Ada Dokter Tersedia',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _colorTextBlack,
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
              color: _colorLabelGrey,
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
                  color: _colorPrimaryBlue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BabyFacePainter extends CustomPainter {
  final bool isGirl;
  const _BabyFacePainter({this.isGirl = true});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokePaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.fill;

    final blushPaint = Paint()
      ..color = const Color(0xFFFF8FA3).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final cx = w * 0.5;
    final cy = h * 0.52;
    final r = w * 0.36;

    final headRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(headRect, 0, math.pi * 2, false, strokePaint);

    final hairPath = Path();
    hairPath.moveTo(cx - r * 0.85, cy - r * 0.3);
    hairPath.quadraticBezierTo(cx - r * 0.35, cy - r * 0.9, cx, cy - r * 0.4);
    hairPath.quadraticBezierTo(
      cx + r * 0.35,
      cy - r * 0.9,
      cx + r * 0.85,
      cy - r * 0.3,
    );
    canvas.drawPath(hairPath, strokePaint);

    canvas.drawCircle(
      Offset(cx - r * 0.38, cy - r * 0.05),
      w * 0.045,
      fillPaint,
    );
    canvas.drawCircle(
      Offset(cx + r * 0.38, cy - r * 0.05),
      w * 0.045,
      fillPaint,
    );

    canvas.drawCircle(
      Offset(cx - r * 0.55, cy + r * 0.15),
      w * 0.065,
      blushPaint,
    );
    canvas.drawCircle(
      Offset(cx + r * 0.55, cy + r * 0.15),
      w * 0.065,
      blushPaint,
    );

    final smilePath = Path();
    smilePath.moveTo(cx - r * 0.35, cy + r * 0.18);
    smilePath.quadraticBezierTo(
      cx,
      cy + r * 0.62,
      cx + r * 0.35,
      cy + r * 0.18,
    );
    canvas.drawPath(smilePath, strokePaint);

    if (isGirl) {
      final bowPaint = Paint()
        ..color = const Color(0xFFFF6B9D)
        ..style = PaintingStyle.fill;
      final bowPath = Path();
      bowPath.moveTo(cx - r * 0.1, cy - r * 0.85);
      bowPath.quadraticBezierTo(
          cx - r * 0.4, cy - r * 1.15, cx - r * 0.25, cy - r * 0.75);
      bowPath.quadraticBezierTo(
          cx - r * 0.1, cy - r * 1.05, cx, cy - r * 0.85);
      bowPath.quadraticBezierTo(
          cx + r * 0.1, cy - r * 1.05, cx + r * 0.25, cy - r * 0.75);
      bowPath.quadraticBezierTo(
          cx + r * 0.4, cy - r * 1.15, cx + r * 0.1, cy - r * 0.85);
      canvas.drawPath(bowPath, bowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
