import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/doctor_service.dart';
import '../../core/services/local_push_service.dart';
import '../../core/services/staff_auth_service.dart';
import '../../models/doctor_model.dart';
import '../../models/staff_account_model.dart';
import '../../shared/widgets/illustration_forest_footer.dart';
import '../auth/auth_choice_page.dart';
import '../auth/terms_page.dart';
import '../pengguna/profil/tampilan_page.dart';
import '../pengguna/profil/tentang_aplikasi_page.dart';
import '../pengguna/profil/ubah_password_page.dart';
import '../pmik_superadmin/profil/hak_akses/edit_dokter_akses_page.dart';
import '../pmik_superadmin/profil/hak_akses/edit_pmik_akses_page.dart';

/// Halaman Menu Pengaturan untuk Staf (Dokter, PMIK Admin, PMIK Superadmin).
///
/// Mengikuti gaya visual Menu Profil Pengguna:
/// - Header 56dp dengan tombol Back dan Judul "Pengaturan"
/// - Daftar Menu:
///   1. Profil (Edit data profil mandiri tanpa hak akses)
///   2. Ubah Kata Sandi
///   3. Tampilan (Tema terang, gelap, sistem)
///   4. Tentang Aplikasi (Konten disesuaikan peran)
///   5. Syarat dan Ketentuan (Konten disesuaikan peran)
///   6. Keluar
/// - Footer ilustrasi alam/hutan di bawah layar.
class PengaturanStaffPage extends StatelessWidget {
  final StaffRole? staffRole;

  const PengaturanStaffPage({
    super.key,
    this.staffRole,
  });

  StaffRole get _effectiveRole =>
      staffRole ?? StaffAuthService().currentStaff?.role ?? StaffRole.dokter;

  void _navigateToEditProfil(BuildContext context) async {
    StaffAccount? staff = StaffAuthService().currentStaff;

    if (_effectiveRole == StaffRole.dokter) {
      DoctorModel? doc;
      if (staff != null) {
        doc = DoctorService().findDoctorForStaff(staff);
        if (doc == null && staff.id.isNotEmpty) {
          doc = await DoctorService().findDoctorByStaffAccountId(staff.id);
        }
        if (doc == null && staff.email.isNotEmpty) {
          doc = await DoctorService().findDoctorByEmail(staff.email);
        }
      }

      if (doc == null && DoctorService().currentDoctors.isNotEmpty) {
        doc = DoctorService().currentDoctors.first;
      }

      doc ??= DoctorModel(
        id: staff?.id ?? 'doc_current',
        staffAccountId: staff?.id ?? '',
        name: staff?.name ?? 'Dokter',
        specialization: 'Dokter Spesialis Anak',
        email: staff?.email,
        avatarUrl: staff?.avatarPath,
      );

      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditDokterAksesPage(
            doctor: doc!,
            staffAccount: staff,
            isSelfEdit: true,
          ),
        ),
      );
    } else {
      if (staff == null) {
        if (_effectiveRole == StaffRole.superadmin) {
          staff = await StaffAuthService().getSuperadminAccount();
        }
        staff ??= StaffAccount(
          id: _effectiveRole == StaffRole.superadmin ? 'superadmin' : 'pmik_admin',
          name: _effectiveRole == StaffRole.superadmin ? 'Superadmin' : 'PMIK Admin',
          role: _effectiveRole,
          email: '',
          passwordHash: '',
          createdBy: 'system',
          permissions: const {},
          createdAt: DateTime.now(),
        );
      }

      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditPmikAksesPage(
            staffAccount: staff!,
            isSelfEdit: true,
          ),
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1A2228) : Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                'Keluar dari Akun',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apakah Anda yakin ingin keluar dari akun ${_getRoleTitle()}?',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF2C363D),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                          StaffAuthService().logout();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const AuthChoicePage(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Keluar',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
    );
  }

  String _getRoleTitle() {
    switch (_effectiveRole) {
      case StaffRole.dokter:
        return 'Dokter';
      case StaffRole.admin:
        return 'PMIK Admin';
      case StaffRole.superadmin:
        return 'PMIK Superadmin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B1014) : Colors.white;
    final headerTextColor =
        isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000);
    final iconColor =
        isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228);
    final chevronColor =
        isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);
    final dividerColor =
        isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─── HEADER 56DP ───────────────────────────────────────────────
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 16.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.arrow_back,
                          color: headerTextColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Profil',
                      style: GoogleFonts.lato(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: headerTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Divider(height: 1, thickness: 1, color: dividerColor),

            // ─── DAFTAR MENU ───────────────────────────────────────────────
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(overscroll: false),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),

                            // 1. Profil
                            _buildMenuItem(
                              icon: Icons.person_outline,
                              title: 'Profil',
                              iconColor: iconColor,
                              textColor: headerTextColor,
                              chevronColor: chevronColor,
                              onTap: () => _navigateToEditProfil(context),
                            ),
                            _buildDivider(dividerColor),

                            // 2. Ubah Kata Sandi
                            _buildMenuItem(
                              icon: Icons.vpn_key_outlined,
                              title: 'Ubah Kata Sandi',
                              iconColor: iconColor,
                              textColor: headerTextColor,
                              chevronColor: chevronColor,
                              onTap: () async {
                                final res = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const UbahPasswordPage(),
                                  ),
                                );
                                if (res is String && context.mounted) {
                                  LocalPushService().show(
                                    title: 'PediaGrow',
                                    body: res,
                                    targetRole: _getPushRole(),
                                  );
                                }
                              },
                            ),
                            _buildDivider(dividerColor),

                            // 3. Tampilan
                            _buildMenuItem(
                              icon: Icons.palette_outlined,
                              title: 'Tampilan',
                              iconColor: iconColor,
                              textColor: headerTextColor,
                              chevronColor: chevronColor,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const TampilanPage(),
                                  ),
                                );
                              },
                            ),
                            _buildDivider(dividerColor),

                            // 4. Tentang Aplikasi
                            _buildMenuItem(
                              icon: Icons.info_outline,
                              title: 'Tentang Aplikasi',
                              iconColor: iconColor,
                              textColor: headerTextColor,
                              chevronColor: chevronColor,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TentangAplikasiPage(
                                      staffRole: _effectiveRole,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildDivider(dividerColor),

                            // 5. Syarat dan Ketentuan
                            _buildMenuItem(
                              icon: Icons.article_outlined,
                              title: 'Syarat dan Ketentuan',
                              iconColor: iconColor,
                              textColor: headerTextColor,
                              chevronColor: chevronColor,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TermsPage(
                                      staffRole: _effectiveRole,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildDivider(dividerColor),

                            // 6. Keluar
                            _buildMenuItem(
                              icon: Icons.logout_rounded,
                              title: 'Keluar',
                              iconColor: iconColor,
                              textColor: headerTextColor,
                              chevronColor: chevronColor,
                              onTap: () => _showLogoutDialog(context),
                            ),
                            _buildDivider(dividerColor),

                            const Spacer(),

                            // Footer Ilustrasi Alam Reusable
                            const IllustrationForestFooter(
                              fit: BoxFit.fitWidth,
                            ),
                          ],
                        ),
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
    );
  }

  PushRole _getPushRole() {
    switch (_effectiveRole) {
      case StaffRole.dokter:
        return PushRole.dokter;
      case StaffRole.admin:
        return PushRole.pmik;
      case StaffRole.superadmin:
        return PushRole.superadmin;
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color textColor,
    required Color chevronColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 22,
              color: chevronColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Divider(height: 1, thickness: 1, color: color),
    );
  }
}

