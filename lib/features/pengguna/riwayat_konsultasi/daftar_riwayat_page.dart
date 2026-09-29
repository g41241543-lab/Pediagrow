import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/child_service.dart';
import '../../../core/services/resume_medis_service.dart';
import '../../../core/services/user_service.dart';
import '../../../models/child_model.dart';
import '../../../models/resume_medis_model.dart';
import '../../../models/riwayat_konsultasi_model.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';
import 'detail_konsultasi_page.dart';
import 'widgets/riwayat_consultation_card.dart';
import 'widgets/riwayat_empty_state.dart';
import 'widgets/riwayat_header.dart';

/// Halaman "Riwayat Konsultasi" Pengguna PediaGrow.
///
/// Mengambil data dari koleksi `resume_medis` di Firestore berdasarkan
/// anak yang sedang aktif dipilih. Menampilkan nama anak, keluhan,
/// dan ringkasan konsultasi dari setiap resume medis.
///
/// Struktur halaman:
/// - Custom Header (56dp) di paling atas, permanen dan tidak ikut ter-scroll.
/// - Konten scrollable (ListView / SingleChildScrollView) bebas RenderFlex overflow.
/// - Scaffold.bottomNavigationBar permanen dengan menu "Riwayat Konsultasi" aktif (Index 2).
class DaftarRiwayatPage extends StatefulWidget {
  const DaftarRiwayatPage({super.key});

  @override
  State<DaftarRiwayatPage> createState() => _DaftarRiwayatPageState();
}

class _DaftarRiwayatPageState extends State<DaftarRiwayatPage> {
  List<RiwayatKonsultasiModel> _riwayatList = [];
  bool _isLoading = true;
  String? _errorMessage;

  ChildModel? _activeChild;
  StreamSubscription<List<ResumeMedisModel>>? _resumeSub;

  @override
  void initState() {
    super.initState();
    _init();
    ChildService().activeChildNotifier.addListener(_onActiveChildChanged);
    ChildService().childrenNotifier.addListener(_onChildrenChanged);
  }

  @override
  void dispose() {
    ChildService().activeChildNotifier.removeListener(_onActiveChildChanged);
    ChildService().childrenNotifier.removeListener(_onChildrenChanged);
    _resumeSub?.cancel();
    super.dispose();
  }

  void _onActiveChildChanged() {
    if (!mounted) return;
    _listenToResumeMedis();
  }

  void _onChildrenChanged() {
    if (!mounted) return;
    _listenToResumeMedis();
  }

  Future<void> _init() async {
    await ChildService().loadChildrenForCurrentUser();
    if (mounted) _listenToResumeMedis();
  }

  void _listenToResumeMedis() {
    if (!mounted) return;

    final child = ChildService().activeChild;
    _activeChild = child;

    // Batalkan subscription sebelumnya
    _resumeSub?.cancel();

    if (child == null) {
      setState(() {
        _riwayatList = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() => _isLoading = true);

    final userId = UserService().currentUser.id;

    _resumeSub = ResumeMedisService()
        .streamResumeMedis(child: child, userId: userId.isEmpty ? null : userId)
        .listen(
      (resumes) {
        if (!mounted) return;
        setState(() {
          _riwayatList = resumes.map(_toRiwayat).toList();
          _isLoading = false;
          _errorMessage = null;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat data. Silakan coba lagi.';
        });
        debugPrint('[DaftarRiwayatPage] streamResumeMedis error: $e');
      },
    );
  }

  /// Konversi [ResumeMedisModel] ke [RiwayatKonsultasiModel] untuk tampilan kartu.
  RiwayatKonsultasiModel _toRiwayat(ResumeMedisModel r) {
    return RiwayatKonsultasiModel(
      id: r.id,
      doctorName: r.doctorName,
      doctorSpecialization: r.doctorSpecialization,
      doctorPhoto: r.doctorPhoto,
      childName: r.childName,
      childAge: r.childAgeAtConsultation,
      childGender: 'unknown',
      consultationDate: r.createdAt ?? DateTime.now(),
      formattedDate: r.consultationDate,
      status: r.status,
      complaint: r.complaintShort.isNotEmpty ? r.complaintShort : r.complaint,
      fullComplaint: r.complaint,
      summary: r.summary,
    );
  }

  /// Navigasi ke Halaman Detail Konsultasi dengan animasi transisi halus
  void _navigateToDetail(RiwayatKonsultasiModel riwayat) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DetailKonsultasiPage(riwayat: riwayat),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0.0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: RiwayatHeader(
          title: 'Riwayat Konsultasi',
          showBackButton: false,
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: _buildBody(),
      ),
      bottomNavigationBar: const PediaBottomNavBar(selectedIndex: 2),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF72A9F4)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
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
                onPressed: _listenToResumeMedis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF72A9F4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Coba Lagi',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_activeChild == null) {
      return _buildNoChildView();
    }

    if (_riwayatList.isEmpty) {
      return _buildEmptyView();
    }

    return _buildPopulatedView();
  }

  /// Tampilan ketika belum ada profil anak terdaftar
  Widget _buildNoChildView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.child_care_rounded,
                                size: 40,
                                color: Color(0xFF72A9F4),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada profil anak',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tambahkan profil anak di Beranda untuk melihat riwayat konsultasi.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildFooterIllustration(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Tampilan Empty State ketika belum terdapat riwayat konsultasi
  Widget _buildEmptyView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  if (_activeChild != null) _buildActiveChildChip(),
                  const Expanded(child: Center(child: RiwayatEmptyState())),
                  _buildFooterIllustration(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Tampilan Daftar Kartu Konsultasi ketika data tersedia
  Widget _buildPopulatedView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_activeChild != null) _buildActiveChildChip(),

                  const SizedBox(height: 8.0),

                  ..._riwayatList.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: RiwayatConsultationCard(
                        riwayat: item,
                        onTap: () => _navigateToDetail(item),
                      ),
                    );
                  }),

                  const Spacer(),
                  const SizedBox(height: 16.0),
                  _buildFooterIllustration(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Chip nama anak yang sedang aktif
  Widget _buildActiveChildChip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.child_care_rounded, size: 16, color: Color(0xFF72A9F4)),
          const SizedBox(width: 6),
          Text(
            'Anak: ',
            style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF64748B)),
          ),
          Text(
            _activeChild!.name,
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  /// Ilustrasi Footer Landscape Full-Bleed
  Widget _buildFooterIllustration() {
    return SizedBox(
      width: double.infinity,
      child: Image.asset(
        'assets/images/beranda_landscape_footer_fiks.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.bottomCenter,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 100,
          color: const Color(0xFFD1FAE5),
          alignment: Alignment.center,
          child: const Icon(
            Icons.park_outlined,
            size: 44,
            color: Color(0xFF34D399),
          ),
        ),
      ),
    );
  }
}
