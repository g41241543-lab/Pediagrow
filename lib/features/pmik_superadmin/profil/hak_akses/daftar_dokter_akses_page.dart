import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/doctor_service.dart';
import '../../../../core/services/staff_auth_service.dart';
import '../../../../models/doctor_model.dart';
import '../../../../models/staff_account_model.dart';
import 'tambah_dokter_akses_page.dart';
import 'edit_dokter_akses_page.dart';

/// Halaman kelola hak akses Dokter oleh Superadmin.
///
/// Menampilkan daftar dokter yang tersimpan di Firestore
/// (collection 'doctors' + 'staff_accounts').
/// Superadmin dapat:
/// - Melihat daftar dokter real-time dari Firestore.
/// - Menambah dokter baru (+ akun login) lewat [TambahDokterAksesPage].
/// - Mengedit/menonaktifkan dokter lewat [EditDokterAksesPage].
class DaftarDokterAksesPage extends StatefulWidget {
  const DaftarDokterAksesPage({super.key});

  @override
  State<DaftarDokterAksesPage> createState() => _DaftarDokterAksesPageState();
}

class _DaftarDokterAksesPageState extends State<DaftarDokterAksesPage> {
  final DoctorService _doctorService = DoctorService();
  final StaffAuthService _staffAuthService = StaffAuthService();

  // Cache: staffAccountId -> StaffAccount (untuk tahu email & status aktif)
  final Map<String, StaffAccount> _staffCache = {};
  bool _isLoadingStaff = false;

  @override
  void initState() {
    super.initState();
    // Mulai listen real-time
    _doctorService.doctorsNotifier;
    _loadStaffAccounts();
  }

  Future<void> _loadStaffAccounts() async {
    if (_isLoadingStaff) return;
    setState(() => _isLoadingStaff = true);
    try {
      final accounts = await _staffAuthService.getAllStaffAccounts();
      final map = <String, StaffAccount>{};
      for (final a in accounts) {
        if (a.role == StaffRole.dokter) {
          map[a.id] = a;
        }
      }
      if (mounted) {
        setState(() {
          _staffCache
            ..clear()
            ..addAll(map);
          _isLoadingStaff = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStaff = false);
    }
  }

  void _navigateToTambah() async {
    final currentEmail =
        _staffAuthService.currentStaff?.email ?? 'superadmin@pediagrow.com';

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TambahDokterAksesPage(
          createdByEmail: currentEmail,
        ),
      ),
    );

    // Refresh cache staff setelah kembali
    await _loadStaffAccounts();
  }

  void _navigateToEdit(DoctorModel doctor) async {
    final staff = _staffCache[doctor.staffAccountId];

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditDokterAksesPage(
          doctor: doctor,
          staffAccount: staff,
        ),
      ),
    );

    // Refresh cache staff setelah kembali
    await _loadStaffAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildHeader(context),
      ),
      body: SafeArea(
        top: false,
        child: ValueListenableBuilder<List<DoctorModel>>(
          valueListenable: _doctorService.doctorsNotifier,
          builder: (context, doctors, _) {
            if (_isLoadingStaff && doctors.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3985E7),
                ),
              );
            }

            if (doctors.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              color: const Color(0xFF3985E7),
              onRefresh: _loadStaffAccounts,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                itemCount: doctors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                itemBuilder: (context, index) {
                  final doctor = doctors[index];
                  final staff = _staffCache[doctor.staffAccountId];
                  return _buildDokterCard(doctor, staff);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToTambah,
        backgroundColor: const Color(0xFF3985E7),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.person_add_rounded),
        label: Text(
          'Tambah Dokter',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56.0,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36.0,
                    height: 36.0,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back,
                      size: 24.0,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    'Kelola Akses Dokter',
                    style: GoogleFonts.lato(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                // Tombol refresh manual
                GestureDetector(
                  onTap: _loadStaffAccounts,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36.0,
                    height: 36.0,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 22.0,
                      color: Color(0xFF64748B),
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

  // ─────────────────────────────────────────────────────────────
  // CARD DOKTER
  // ─────────────────────────────────────────────────────────────

  Widget _buildDokterCard(DoctorModel doctor, StaffAccount? staff) {
    final bool isActive = staff?.isActive ?? true;
    final String emailText = staff?.email ?? '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFFBFDBFE)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToEdit(doctor),
          splashColor: const Color(0xFF3985E7).withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFECF6FF)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF3985E7).withValues(alpha: 0.2)
                          : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildAvatar(doctor, isActive),
                ),

                const SizedBox(width: 14),

                // Info dokter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris nama + badge status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              doctor.name.isEmpty
                                  ? '(Nama belum diisi)'
                                  : doctor.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Badge Aktif / Nonaktif
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isActive ? 'Aktif' : 'Nonaktif',
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Spesialisasi
                      if (doctor.specialization.isNotEmpty)
                        Text(
                          doctor.specialization,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 12.5,
                            color: const Color(0xFF3985E7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                      const SizedBox(height: 4),

                      // Email akun login
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              emailText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),

                      // Pengalaman
                      Row(
                        children: [
                          const Icon(
                            Icons.business_center_outlined,
                            size: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${doctor.experienceYears} tahun pengalaman',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(DoctorModel doctor, bool isActive) {
    if (doctor.assetImagePath != null && doctor.assetImagePath!.isNotEmpty) {
      return Image.asset(
        doctor.assetImagePath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackAvatar(isActive),
      );
    }
    if (doctor.avatarUrl != null && doctor.avatarUrl!.isNotEmpty) {
      return Image.network(
        doctor.avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackAvatar(isActive),
      );
    }
    return _fallbackAvatar(isActive);
  }

  Widget _fallbackAvatar(bool isActive) {
    return Container(
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        size: 28,
        color: isActive ? const Color(0xFF3985E7) : const Color(0xFF94A3B8),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.medical_information_outlined,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Belum Ada Dokter',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol "Tambah Dokter" di bawah untuk mendaftarkan dokter baru ke sistem.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13.5,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
