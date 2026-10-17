import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/booking_service.dart';
import '../../../core/services/jadwal_dokter_service.dart';
import '../../../core/services/konsultasi_service.dart';
import '../../../core/services/staff_auth_service.dart';
import '../../../models/booking_consultation_model.dart';
import '../../../models/child_model.dart';
import '../../../models/konsultasi_session_model.dart';
import '../../../models/staff_account_model.dart';
import '../../../models/user_model.dart';
import '../beranda/data_pasien/detail_anak_page.dart';
import '../../pmik_superadmin/riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import '../beranda/beranda_dokter_page.dart';
import '../profil_dokter_page.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
const Color _colorNavBg = Color(0xFFF2EDED);
const Color _colorPrimaryBlue = Color(0xFF4A90D9);
const Color _colorTextBlack = Color(0xFF1E293B);
const Color _colorLabelGrey = Color(0xFF64748B);
const Color _colorCardBg = Color(0xFFFFFFFF);

/// Model data konsultasi untuk dokter.
class _KonsultasiItem {
  final String id;
  final String childName;
  final String childAge;
  final String childGender; // 'Laki-laki' | 'Perempuan'
  final String? childPhotoUrl;
  final String doctorName;
  final String status; // 'berlangsung' | 'jadwal'
  final String? scheduledDate;
  final String? scheduledTime;
  final String? sessionId;
  final String? parentName;
  final String? complaint;
  final double? weightKg;
  final double? heightCm;

  const _KonsultasiItem({
    required this.id,
    required this.childName,
    required this.childAge,
    required this.childGender,
    this.childPhotoUrl,
    required this.doctorName,
    required this.status,
    // ignore: unused_element_parameter
    this.scheduledDate,
    // ignore: unused_element_parameter
    this.scheduledTime,
    this.sessionId,
    this.parentName,
    this.complaint,
    this.weightKg,
    this.heightCm,
  });
}

// ─── Data Konsultasi: 100% Menggunakan Data Asli Firebase Firestore ─────────
final List<_KonsultasiItem> _mockBerlangsung = [];
final List<_KonsultasiItem> _mockJadwal = [];

/// Halaman Konsultasi untuk POV DOKTER.
///
/// Tampilan:
/// - Mengikuti standar tampilan PMIK Admin & Superadmin:
///   * Header 56dp tanpa tombol back, teks "Konsultasi" 22dp bold rata kiri
///   * TabBar underline indikator dengan badge jumlah interaktif
///   * Card bergaya seragam PMIK (border #BFDBFE, shadow lembut, rounded 16dp)
///   * Format jadwal di dalam kotak waktu & tanggal satu baris dengan ikon rapi
///   * Footer gambar lanskap terpadu
///   * Bottom Navigation bar yang konsisten dengan ikon lingkaran untuk tab aktif
///
/// Logika Khusus DOKTER:
/// 1. Baik tab "Sedang Berlangsung" maupun "Jadwal Konsultasi" HANYA menampilkan pasien
///    yang ditangani oleh dokter yang sedang login.
/// 2. Tombol "Masuk Ruang Chat" aktif dan langsung membuka chat konsultasi tanpa terkunci.
class KonsultasiDokterPage extends StatefulWidget {
  const KonsultasiDokterPage({super.key});

  @override
  State<KonsultasiDokterPage> createState() => _KonsultasiDokterPageState();
}

class _KonsultasiDokterPageState extends State<KonsultasiDokterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final int _selectedNavIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Returns true jika jadwal mock item ini belum lewat (tanggal & jam masih di depan sekarang).
  /// Format scheduledDate: "Senin, 20 Okt 2026", scheduledTime: "09:30"
  bool _isJadwalBelumLewat(_KonsultasiItem item) {
    final dateStr = item.scheduledDate;
    final timeStr = item.scheduledTime;
    if (dateStr == null || dateStr.isEmpty) return false;
    // Map bulan singkat Indonesia ke nomor
    const bulan = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'Mei': 5, 'Jun': 6,
      'Jul': 7, 'Agu': 8, 'Sep': 9, 'Okt': 10, 'Nov': 11, 'Des': 12,
    };
    // Contoh: "Senin, 20 Okt 2026"
    final parts = dateStr.replaceAll(',', '').split(' ');
    if (parts.length < 4) return false;
    final day = int.tryParse(parts[1]);
    final month = bulan[parts[2]];
    final year = int.tryParse(parts[3]);
    if (day == null || month == null || year == null) return false;

    int hour = 23, minute = 59;
    if (timeStr != null && timeStr.isNotEmpty) {
      final timeParts = timeStr.split(':');
      hour = int.tryParse(timeParts[0]) ?? 23;
      minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 59) : 59;
    }
    // Anggap jadwal berakhir 30 menit setelah waktu mulai
    final scheduledEnd = DateTime(year, month, day, hour, minute)
        .add(const Duration(minutes: 30));
    return DateTime.now().isBefore(scheduledEnd);
  }

  /// Masuk langsung ke halaman ruang obrolan data pasien anak tersebut
  void _openChatRoom(_KonsultasiItem item) {
    if (item.sessionId != null && item.sessionId!.isNotEmpty) {
      KonsultasiService.instance.mulaiSesi(item.sessionId!);
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailAnakPage(
          child: ChildModel(
            id: item.id,
            ownerId: '',
            name: item.childName,
            gender: item.childGender,
            birthDate: DateTime.now().subtract(const Duration(days: 365)),
            ageDescription: item.childAge,
            weightKg: item.weightKg,
            heightCm: item.heightCm,
            photoUrl: item.childPhotoUrl,
          ),
          user: UserModel(
            id: '',
            name: item.parentName ?? 'Orang Tua ${item.childName}',
            email: '',
          ),
          initialTabIndex: 1, // Masuk langsung ke tab Ruang Obrolan pada menu data pasien
        ),
      ),
    );
  }

  /// Masuk ke halaman ruang obrolan data pasien dari objek booking
  void _openChatRoomFromBooking(BookingConsultationModel booking) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailAnakPage(
          child: booking.child,
          user: UserModel(
            id: '',
            name: 'Orang Tua ${booking.child.name}',
            email: '',
          ),
          initialTabIndex: 1, // Masuk langsung ke tab Ruang Obrolan pada menu data pasien
        ),
      ),
    );
  }


  /// Mengecek apakah nama dokter pada booking/item cocok dengan dokter yang sedang login
  bool _isDoctorMatch(String targetDoctorName, String loggedInDoctorName) {
    if (loggedInDoctorName.isEmpty) return true;

    final targetLower = targetDoctorName.toLowerCase().trim();
    final loggedInLower = loggedInDoctorName.toLowerCase().trim();

    String extractKeyName(String name) {
      return name
          .toLowerCase()
          .replaceAll('dr.', '')
          .replaceAll('dr', '')
          .replaceAll('sp.a', '')
          .replaceAll('spa', '')
          .replaceAll('m.kes', '')
          .replaceAll('mkes', '')
          .replaceAll(',', '')
          .replaceAll('.', '')
          .trim();
    }

    final targetKey = extractKeyName(targetLower);
    final loggedInKey = extractKeyName(loggedInLower);

    if (targetKey.isEmpty || loggedInKey.isEmpty) return true;

    final targetWords = targetKey.split(' ').where((w) => w.length >= 3).toList();
    final loggedInWords = loggedInKey.split(' ').where((w) => w.length >= 3).toList();

    for (final tw in targetWords) {
      for (final lw in loggedInWords) {
        if (tw.contains(lw) || lw.contains(tw)) {
          return true;
        }
      }
    }

    return targetKey.contains(loggedInKey) || loggedInKey.contains(targetKey);
  }

  // ─── POPUP DETAIL JADWAL ──────────────────────────────────────────────────
  void _showJadwalDetailModal(_KonsultasiItem item) {
    final isFemale = item.childGender == 'Perempuan';
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
                _buildChildAvatar(
                  photoUrl: item.childPhotoUrl,
                  isFemale: isFemale,
                  size: 46,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.childName,
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _colorTextBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.childGender} • ${item.childAge}',
                        style: GoogleFonts.lato(
                          fontSize: 12.5,
                          color: _colorLabelGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(
                  'Terjadwal',
                  _colorPrimaryBlue,
                  const Color(0xFFEBF5FF),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.medical_services_rounded,
                  size: 16,
                  color: _colorPrimaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  item.doctorName,
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _colorTextBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: _colorPrimaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.scheduledDate ?? '-'} • ${item.scheduledTime ?? '-'}',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: _colorLabelGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _colorPrimaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _openChatRoom(item);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorPrimaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Buka Chat',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
    );
  }

  void _showBookingDetailModal(BookingConsultationModel booking) {
    final isFemale = booking.child.gender.toLowerCase().contains('perempuan');
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
                _buildChildAvatar(
                  photoUrl: booking.child.photoUrl,
                  isFemale: isFemale,
                  size: 46,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.child.name,
                        style: GoogleFonts.lato(
                          fontSize: 16,
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
                _buildStatusBadge(
                  booking.status,
                  _colorPrimaryBlue,
                  const Color(0xFFEBF5FF),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.medical_services_rounded,
                  size: 16,
                  color: _colorPrimaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  booking.doctor.name,
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _colorTextBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: _colorPrimaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  '${booking.formattedDate} • ${booking.scheduledTimeSlot}',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: _colorLabelGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _colorPrimaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _openChatRoomFromBooking(booking);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorPrimaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Buka Chat',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StaffAccount?>(
      valueListenable: StaffAuthService().currentStaffNotifier,
      builder: (context, currentStaff, _) {
        final loggedInDoctorName = currentStaff?.name.trim() ?? '';

        return StreamBuilder<List<KonsultasiSessionModel>>(
          stream: KonsultasiService.instance.streamSemuaSesiAktif(),
          builder: (context, sessionSnap) {
            final activeSessions = sessionSnap.data ?? [];
            final firestoreBerlangsung = activeSessions
                .where((s) => _isDoctorMatch(s.doctorName, loggedInDoctorName))
                .map((s) => _KonsultasiItem(
                      id: s.childId.isNotEmpty ? s.childId : s.id,
                      childName: s.childName,
                      childAge: s.childAge ?? '0 tahun',
                      childGender: s.childGender ?? 'Laki-laki',
                      childPhotoUrl: s.childPhotoUrl,
                      doctorName: s.doctorName,
                      status: 'berlangsung',
                      sessionId: s.id,
                      parentName: s.parentName,
                      complaint: s.keluhanAwal,
                      weightKg: s.weightKg,
                      heightCm: s.heightCm,
                    ))
                .toList();

            return ValueListenableBuilder<List<BookingConsultationModel>>(
              valueListenable: BookingService().bookingsNotifier,
              builder: (context, userBookings, _) {
                // Filter pasien berlangsung untuk dokter yang sedang login
                final filteredMockBerlangsung = _mockBerlangsung.where((item) {
                  return _isDoctorMatch(item.doctorName, loggedInDoctorName);
                }).toList();

                final filteredBerlangsung = [
                  ...firestoreBerlangsung,
                  ...filteredMockBerlangsung,
                ];

                // Filter jadwal booking untuk dokter yang sedang login
                // + otomatis filter jadwal yang sudah lewat (_isJadwalBelumLewat)
                final filteredMockJadwal = _mockJadwal.where((item) {
                  return _isDoctorMatch(item.doctorName, loggedInDoctorName) &&
                      _isJadwalBelumLewat(item);
                }).toList();

                final doctorAliases = currentStaff != null
                    ? JadwalDokterService().getDoctorIdAliases(currentStaff.id)
                    : <String>{};

                final filteredUserBookings = userBookings.where((b) {
                  if (b.isExpired) return false;
                  return _isDoctorMatch(b.doctor.name, loggedInDoctorName) ||
                      doctorAliases.contains(b.doctor.id) ||
                      (currentStaff != null && b.doctor.id == currentStaff.id);
                }).toList();

                final int berlangsungCount = filteredBerlangsung.length;
                final int jadwalCount =
                    filteredMockJadwal.length + filteredUserBookings.length;

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(56.0),
                child: _buildHeader(),
              ),
              body: SafeArea(
                top: false,
                bottom: false,
                child: Column(
                  children: [
                    _buildTabBar(berlangsungCount, jadwalCount),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSedangBerlangsungTab(
                            filteredBerlangsung,
                            loggedInDoctorName,
                          ),
                          _buildJadwalKonsultasiTab(
                            filteredMockJadwal,
                            filteredUserBookings,
                            loggedInDoctorName,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: _buildBottomNav(),
            );
          },
        );
      },
    );
  },
);
  }

  // ─── HEADER (Format PMIK: 56dp tanpa back button) ─────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Konsultasi',
                style: GoogleFonts.lato(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: _colorTextBlack,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── TAB BAR (Format PMIK: Underline indicator & Badge Count) ─────────────
  Widget _buildTabBar(int berlangsungCount, int jadwalCount) {
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
                const Text('Sedang Berlangsung'),
                const SizedBox(width: 6),
                _buildTabBadge(berlangsungCount, isFirstTab: true),
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
                _buildTabBadge(jadwalCount, isFirstTab: false),
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

  // ─── TAB 1: SEDANG BERLANGSUNG ─────────────────────────────────────────────
  Widget _buildSedangBerlangsungTab(
    List<_KonsultasiItem> items,
    String loggedInDoctorName,
  ) {
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildDoctorActiveBanner(loggedInDoctorName),
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 48,
                      ),
                      child: _buildEmptyState(
                        title: 'Belum Ada Sesi Konsultasi Aktif',
                        subtitle: loggedInDoctorName.isNotEmpty
                            ? 'Saat ini belum ada sesi konsultasi yang sedang berlangsung untuk $loggedInDoctorName.'
                            : 'Belum ada sesi konsultasi yang sedang berlangsung.',
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                    )
                  else
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: _buildBerlangsungCard(item),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Spacer(),
                  _buildFooterIllustration(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorActiveBanner(String doctorName) {
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
              Icons.chat_bubble_rounded,
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
                  'Sesi Konsultasi Pasien Aktif',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _colorPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sebagai dokter yang menangani, Anda dapat langsung masuk ke ruang obrolan untuk memberikan konsultasi medis.',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: _colorPrimaryBlue.withValues(alpha: 0.8),
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

  Widget _buildBerlangsungCard(_KonsultasiItem item) {
    final isFemale = item.childGender == 'Perempuan';
    return Container(
      decoration: BoxDecoration(
        color: _colorCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _colorPrimaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: _colorPrimaryBlue.withValues(alpha: 0.08),
          highlightColor: _colorPrimaryBlue.withValues(alpha: 0.04),
          hoverColor: _colorPrimaryBlue.withValues(alpha: 0.04),
          onTap: () => _openChatRoom(item),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    _buildChildAvatar(
                      photoUrl: item.childPhotoUrl,
                      isFemale: isFemale,
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.childName,
                                  style: GoogleFonts.lato(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _colorTextBlack,
                                  ),
                                ),
                              ),
                              _buildStatusBadge(
                                'Berlangsung',
                                const Color(0xFF10B981),
                                const Color(0xFFD1FAE5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                isFemale ? Icons.female : Icons.male,
                                size: 14,
                                color: isFemale
                                    ? const Color(0xFFEC4899)
                                    : const Color(0xFF3B82F6),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                item.childAge,
                                style: GoogleFonts.lato(
                                  fontSize: 12.5,
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
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
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
                        item.doctorName,
                        style: GoogleFonts.lato(
                          fontSize: 12.5,
                          color: _colorLabelGrey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _openChatRoom(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
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
                          'Masuk Ruang Chat',
                          style: GoogleFonts.lato(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }

  // ─── TAB 2: JADWAL KONSULTASI ──────────────────────────────────────────────
  Widget _buildJadwalKonsultasiTab(
    List<_KonsultasiItem> mockItems,
    List<BookingConsultationModel> userBookings,
    String loggedInDoctorName,
  ) {
    final bool hasAnyJadwal = mockItems.isNotEmpty || userBookings.isNotEmpty;

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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildScheduleBanner(loggedInDoctorName),
                  ),
                  const SizedBox(height: 12),
                  if (!hasAnyJadwal)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 48,
                      ),
                      child: _buildEmptyState(
                        title: 'Belum Ada Jadwal Booking',
                        subtitle: loggedInDoctorName.isNotEmpty
                            ? 'Saat ini belum ada pasien yang memesan jadwal konsultasi untuk $loggedInDoctorName.'
                            : 'Belum ada pasien yang memesan jadwal konsultasi.',
                        icon: Icons.event_busy_rounded,
                      ),
                    )
                  else ...[
                    ...userBookings.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: _buildUserBookingCard(booking),
                      ),
                    ),
                    ...mockItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: _buildJadwalCard(item),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Spacer(),
                  _buildFooterIllustration(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleBanner(String doctorName) {
    final title = doctorName.isNotEmpty
        ? 'Jadwal Booking Pasien — $doctorName'
        : 'Jadwal Booking Pasien';

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
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _colorPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hanya menampilkan pasien yang memiliki jadwal konsultasi dengan Anda.',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: _colorPrimaryBlue.withValues(alpha: 0.8),
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

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 36,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _colorTextBlack,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontSize: 13,
            color: _colorLabelGrey,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ─── JADWAL CARD (Format PMIK: Kotak tanggal & jam dalam satu baris) ────────
  Widget _buildJadwalCard(_KonsultasiItem item) {
    final isFemale = item.childGender == 'Perempuan';
    return Container(
      decoration: BoxDecoration(
        color: _colorCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _colorPrimaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: _colorPrimaryBlue.withValues(alpha: 0.08),
          highlightColor: _colorPrimaryBlue.withValues(alpha: 0.04),
          hoverColor: _colorPrimaryBlue.withValues(alpha: 0.04),
          onTap: () => _showJadwalDetailModal(item),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChildAvatar(
                      photoUrl: item.childPhotoUrl,
                      isFemale: isFemale,
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.childName,
                                  style: GoogleFonts.lato(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _colorTextBlack,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(
                                'Terjadwal',
                                _colorPrimaryBlue,
                                const Color(0xFFEBF5FF),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                isFemale ? Icons.female : Icons.male,
                                size: 14,
                                color: isFemale
                                    ? const Color(0xFFEC4899)
                                    : const Color(0xFF3B82F6),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                item.childAge,
                                style: GoogleFonts.lato(
                                  fontSize: 12.5,
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
              if (item.scheduledDate != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
                          size: 14,
                          color: _colorPrimaryBlue,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            item.scheduledDate!,
                            style: GoogleFonts.lato(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _colorPrimaryBlue,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: _colorPrimaryBlue,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.scheduledTime ?? '-',
                          style: GoogleFonts.lato(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: _colorPrimaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
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
                        item.doctorName,
                        style: GoogleFonts.lato(
                          fontSize: 12.5,
                          color: _colorLabelGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserBookingCard(BookingConsultationModel booking) {
    final isFemale = booking.child.gender.toLowerCase().contains('perempuan');
    return Container(
      decoration: BoxDecoration(
        color: _colorCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _colorPrimaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: _colorPrimaryBlue.withValues(alpha: 0.08),
          highlightColor: _colorPrimaryBlue.withValues(alpha: 0.04),
          hoverColor: _colorPrimaryBlue.withValues(alpha: 0.04),
          onTap: () => _showBookingDetailModal(booking),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  booking.child.name,
                                  style: GoogleFonts.lato(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _colorTextBlack,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(
                                booking.status,
                                _colorPrimaryBlue,
                                const Color(0xFFEBF5FF),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                isFemale ? Icons.female : Icons.male,
                                size: 14,
                                color: isFemale
                                    ? const Color(0xFFEC4899)
                                    : const Color(0xFF3B82F6),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${booking.child.gender} • ${booking.child.ageDescription}',
                                style: GoogleFonts.lato(
                                  fontSize: 12.5,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
                        size: 14,
                        color: _colorPrimaryBlue,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          booking.formattedDate,
                          style: GoogleFonts.lato(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _colorPrimaryBlue,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: _colorPrimaryBlue,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        booking.scheduledTimeSlot,
                        style: GoogleFonts.lato(
                          fontSize: 12.5,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
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
                        style: GoogleFonts.lato(
                          fontSize: 12.5,
                          color: _colorLabelGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── STATUS BADGE ─────────────────────────────────────────────────────────
  Widget _buildStatusBadge(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.lato(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  // ─── CHILD AVATAR ─────────────────────────────────────────────────────────
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          width: size,
          height: size,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Container(
              color: bgColor,
              child: Center(
                child: SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isFemale
                        ? const Color(0xFFEC4899)
                        : _colorPrimaryBlue,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (ctx, error, stack) => Container(
            color: bgColor,
            child: CustomPaint(
              painter: _BabyFacePainter(isGirl: isFemale),
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CustomPaint(painter: _BabyFacePainter(isGirl: isFemale)),
    );
  }

  // ─── FOOTER ILLUSTRATION (Format PMIK: Gambar Lanskap) ───────────────────
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

  // ─── BOTTOM NAVIGATION BAR (Format PMIK: Lingkaran Aktif & Transisi Halus) ─
  Widget _buildBottomNav() {
    const navItems = [
      _NavItem(icon: Icons.home_rounded, label: 'Beranda'),
      _NavItem(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
      _NavItem(icon: Icons.manage_search_rounded, label: 'Riwayat Konsultasi'),
      _NavItem(icon: Icons.person_rounded, label: 'Profil'),
    ];

    return Container(
      width: double.infinity,
      height: 68.0,
      decoration: const BoxDecoration(
        color: _colorNavBg,
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(navItems.length, (i) {
            final isSelected = i == _selectedNavIndex;
            final item = navItems[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => _onNavTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 68.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4.0,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            item.icon,
                            size: 22.0,
                            color: const Color(0xFF72A9F4),
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 11.0,
                                fontWeight: FontWeight.normal,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Icon(
                          item.icon,
                          size: 24.0,
                          color: const Color(0xFF9E9E9E),
                        ),
                        const SizedBox(height: 3.0),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                fontSize: 11.0,
                                fontWeight: FontWeight.normal,
                                color: const Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    Widget targetPage;
    switch (index) {
      case 0:
        targetPage = const BerandaDokterPage();
        break;
      case 2:
        targetPage = const DaftarRiwayatKonsultasiAdminPage();
        break;
      case 3:
        targetPage = const ProfilDokterPage();
        break;
      default:
        return;
    }
    final isLeft = index < _selectedNavIndex;
    final beginOffset = Offset(isLeft ? -0.25 : 0.25, 0.0);
    final route = PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, _, _) => targetPage,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
    if (index == 0) {
      Navigator.of(context).pushAndRemoveUntil(route, (r) => false);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }
}

// ─── Helper types ─────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

/// Painter wajah bayi lucu — fallback jika foto profil anak tidak tersedia.
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

    // Lingkaran kepala
    final headRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(headRect, 0, math.pi * 2, false, strokePaint);

    // Poni rambut
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

    // Mata
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

    // Pipi kemerahan
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

    // Senyuman
    final smilePath = Path();
    smilePath.moveTo(cx - r * 0.35, cy + r * 0.18);
    smilePath.quadraticBezierTo(
      cx,
      cy + r * 0.62,
      cx + r * 0.35,
      cy + r * 0.18,
    );
    canvas.drawPath(smilePath, strokePaint);

    // Hiasan pita untuk anak perempuan
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
