import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/booking_service.dart';
import '../../../core/services/child_service.dart';
import '../../../core/services/resume_medis_service.dart';
import '../../../core/services/user_service.dart';
import '../../../models/booking_consultation_model.dart';
import '../../../models/child_model.dart';
import '../../../models/resume_medis_model.dart';
import '../../../models/riwayat_konsultasi_model.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';
import '../../../shared/widgets/illustration_forest_footer.dart';
import 'detail_konsultasi_page.dart';
import 'widgets/riwayat_consultation_card.dart';
import 'widgets/riwayat_empty_state.dart';
import 'widgets/riwayat_header.dart';

/// Halaman "Riwayat Konsultasi" Pengguna PediaGrow.
///
/// Mengambil data dari koleksi `resume_medis` di Firestore dan booking konsultasi aktif
/// berdasarkan anak yang dipilih pengguna secara interaktif.
class DaftarRiwayatPage extends StatefulWidget {
  final List<RiwayatKonsultasiModel>? initialRiwayatList;

  const DaftarRiwayatPage({super.key, this.initialRiwayatList});

  @override
  State<DaftarRiwayatPage> createState() => _DaftarRiwayatPageState();
}

class _DaftarRiwayatPageState extends State<DaftarRiwayatPage> {
  List<RiwayatKonsultasiModel> _riwayatList = [];
  bool _isLoading = true;
  String? _errorMessage;

  ChildModel? _activeChild;
  bool _showAllChildren = true;
  StreamSubscription<List<ResumeMedisModel>>? _resumeSub;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialRiwayatList != null) {
      _riwayatList = widget.initialRiwayatList!;
      _isLoading = false;
    } else {
      _init();
      ChildService().activeChildNotifier.addListener(_onActiveChildChanged);
      ChildService().childrenNotifier.addListener(_onChildrenChanged);
      BookingService().bookingsNotifier.addListener(_onBookingsChanged);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    if (widget.initialRiwayatList == null) {
      ChildService().activeChildNotifier.removeListener(_onActiveChildChanged);
      ChildService().childrenNotifier.removeListener(_onChildrenChanged);
      BookingService().bookingsNotifier.removeListener(_onBookingsChanged);
      _resumeSub?.cancel();
    }
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

  void _onBookingsChanged() {
    if (!mounted) return;
    _listenToResumeMedis();
  }

  Future<void> _init() async {
    await ChildService().loadChildrenForCurrentUser();
    if (mounted) _listenToResumeMedis();
  }

  void _selectChild(ChildModel? child) {
    setState(() {
      if (child == null) {
        _showAllChildren = true;
        _activeChild = null;
      } else {
        _showAllChildren = false;
        _activeChild = child;
        ChildService().setActiveChild(child);
      }
    });
    _listenToResumeMedis();
  }

  void _listenToResumeMedis() {
    if (!mounted) return;

    final registeredChildren = ChildService().children;
    if (!_showAllChildren && _activeChild == null && registeredChildren.isNotEmpty) {
      _activeChild = ChildService().activeChild ?? registeredChildren.first;
    }

    final targetChild = _showAllChildren ? null : _activeChild;

    // Batalkan subscription sebelumnya
    _resumeSub?.cancel();

    final userId = UserService().currentUser.id;

    if (targetChild == null && registeredChildren.isEmpty && userId.isEmpty) {
      setState(() {
        _riwayatList = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() => _isLoading = true);

    final streamChild = targetChild ??
        const ChildModel(id: '', name: '', gender: '', birthDate: null);

    _resumeSub = ResumeMedisService()
        .streamResumeMedis(
          child: streamChild,
          userId: userId.isEmpty ? null : userId,
        )
        .listen(
      (resumes) {
        if (!mounted) return;

        // 1. Filter resume medis secara akurat sesuai anak yang dipilih dan berstatus selesai
        final filteredResumes = resumes.where((r) {
          final isCompleted = r.status.toLowerCase().trim() == 'selesai';
          if (!isCompleted) return false;

          if (targetChild == null) return true;
          final matchesId = r.childId.isNotEmpty && r.childId == targetChild.id;
          final matchesName =
              r.childName.trim().toLowerCase() == targetChild.name.trim().toLowerCase();
          return matchesId || matchesName;
        }).toList();

        // 2. Ambil data dari BookingService untuk anak yang bersangkutan (hanya yang statusnya selesai)
        final allBookings = BookingService().bookingsNotifier.value;
        final filteredBookings = allBookings.where((b) {
          final isCompleted = b.status.toLowerCase().trim() == 'selesai';
          if (!isCompleted) return false;

          if (targetChild != null) {
            final matchesId =
                b.child.id.isNotEmpty && b.child.id == targetChild.id;
            final matchesName = b.child.name.trim().toLowerCase() ==
                targetChild.name.trim().toLowerCase();
            if (!matchesId && !matchesName) return false;
          }
          return true;
        }).toList();

        // 3. Konversi dan gabungkan, prioritaskan resume jika ada
        final combined = <RiwayatKonsultasiModel>[];
        final seenIds = <String>{};

        for (final r in filteredResumes) {
          final item = _toRiwayat(r);
          seenIds.add(item.id);
          combined.add(item);
        }

        for (final b in filteredBookings) {
          if (!seenIds.contains(b.id)) {
            seenIds.add(b.id);
            combined.add(_bookingToRiwayat(b));
          }
        }

        // Urutkan jadwal terbaru di paling atas
        combined.sort((a, b) => b.consultationDate.compareTo(a.consultationDate));

        setState(() {
          _riwayatList = combined;
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

  /// Konversi [BookingConsultationModel] ke [RiwayatKonsultasiModel]
  RiwayatKonsultasiModel _bookingToRiwayat(BookingConsultationModel b) {
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final dateStr =
        '${b.scheduledDate.day} ${months[b.scheduledDate.month]} ${b.scheduledDate.year}';
    final isDone = b.status.toLowerCase() == 'selesai';

    return RiwayatKonsultasiModel(
      id: b.id,
      doctorName: b.doctor.name,
      doctorSpecialization: b.doctor.specialization,
      doctorPhoto: b.doctor.avatarUrl ?? b.doctor.assetImagePath,
      childName: b.child.name,
      childAge: b.child.ageDescription.isNotEmpty
          ? b.child.ageDescription
          : '1 tahun',
      childGender: b.child.gender,
      consultationDate: b.scheduledDate,
      formattedDate: dateStr,
      status: b.status,
      complaint: (b.complaint != null && b.complaint!.trim().isNotEmpty)
          ? b.complaint!.trim()
          : 'Konsultasi kesehatan anak',
      fullComplaint: (b.complaint != null && b.complaint!.trim().isNotEmpty)
          ? b.complaint!.trim()
          : 'Konsultasi kesehatan anak',
      summary: isDone
          ? 'Konsultasi telah selesai dilaksanakan.'
          : 'Jadwal konsultasi: ${b.scheduledTimeSlot}. Menunggu sesi konsultasi bersama dokter.',
    );
  }

  /// Konversi [ResumeMedisModel] ke [RiwayatKonsultasiModel] untuk tampilan kartu.
  RiwayatKonsultasiModel _toRiwayat(ResumeMedisModel r) {
    return RiwayatKonsultasiModel(
      id: r.id,
      doctorId: r.doctorId,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1014) : Colors.white,
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
        child: _buildBody(isDark),
      ),
      bottomNavigationBar: const PediaBottomNavBar(selectedIndex: 2),
    );
  }

  Widget _buildBody(bool isDark) {
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
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
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

    final hasChildren = ChildService().children.isNotEmpty;
    if (widget.initialRiwayatList == null && !hasChildren && _activeChild == null) {
      return _buildNoChildView(isDark);
    }

    if (_riwayatList.isEmpty && _searchQuery.isEmpty) {
      return _buildEmptyView(isDark);
    }

    return _buildPopulatedView(isDark);
  }

  List<RiwayatKonsultasiModel> get _displayedRiwayatList {
    if (_searchQuery.trim().isEmpty) return _riwayatList;
    final q = _searchQuery.trim().toLowerCase();
    return _riwayatList.where((item) {
      final childMatch = item.childName.toLowerCase().contains(q);
      final docMatch = item.doctorName.toLowerCase().contains(q);
      final compMatch = item.complaint.toLowerCase().contains(q);
      final specMatch = item.doctorSpecialization.toLowerCase().contains(q);
      final dateMatch = item.formattedDate.toLowerCase().contains(q);
      return childMatch || docMatch || compMatch || specMatch || dateMatch;
    }).toList();
  }

  /// Tampilan ketika belum ada profil anak terdaftar
  Widget _buildNoChildView(bool isDark) {
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
                                color: isDark ? const Color(0xFF1A2228) : const Color(0xFFEFF6FF),
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
                                color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tambahkan profil anak di Beranda untuk melihat riwayat konsultasi.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
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
  Widget _buildEmptyView(bool isDark) {
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
                  _buildSearchBarAndFilter(isDark),
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
  Widget _buildPopulatedView(bool isDark) {
    final displayed = _displayedRiwayatList;

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
                  _buildSearchBarAndFilter(isDark),

                  const SizedBox(height: 10.0),

                  if (displayed.isEmpty)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: isDark
                                    ? const Color(0xFF8696A0)
                                    : const Color(0xFF9E9E9E),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada riwayat konsultasi yang cocok.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: isDark
                                      ? const Color(0xFF8696A0)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...displayed.map((item) {
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

  /// Search Bar dan Filter Kategori Anak (Identik dengan Desain Daftar Resep MPASI)
  Widget _buildSearchBarAndFilter(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Search Bar mirip Daftar Resep MPASI
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(20),
              border: isDark ? Border.all(color: const Color(0xFF2C363D)) : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF9E9E9E),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim());
                    },
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari riwayat konsultasi...',
                      hintStyle: GoogleFonts.lato(
                        fontSize: 14.5,
                        color: isDark ? const Color(0xFF667781) : const Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _searchFocusNode.unfocus();
                      setState(() => _searchQuery = '');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF8696A0) : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 2. Filter Kategori Anak (mirip Kategori Usia MPASI: pil rounded, 'Semua' lalu nama anak)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildMpasiStyleChip(
                label: 'Semua',
                isSelected: _showAllChildren,
                onTap: () => _selectChild(null),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              ...ChildService().children.map((child) {
                final isSelected = !_showAllChildren && _activeChild?.id == child.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildMpasiStyleChip(
                    label: child.name,
                    isSelected: isSelected,
                    onTap: () => _selectChild(child),
                    isDark: isDark,
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMpasiStyleChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                  : const Color(0xFFEFF6FF))
              : (isDark ? const Color(0xFF1A2228) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3985E7)
                : (isDark
                    ? const Color(0xFF2C363D)
                    : const Color(0xFFE9EDEF)),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? const Color(0xFF3985E7)
                : (isDark
                    ? const Color(0xFF8696A0)
                    : const Color(0xFF7F7F7F)),
          ),
        ),
      ),
    );
  }

  /// Ilustrasi Footer Landscape Full-Bleed
  Widget _buildFooterIllustration() {
    return const IllustrationForestFooter(fit: BoxFit.fitWidth);
  }
}
