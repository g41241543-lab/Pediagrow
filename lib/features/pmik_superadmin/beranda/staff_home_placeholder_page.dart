import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/staff_auth_service.dart';
import '../../../models/doctor_permissions.dart';
import '../../../models/staff_account_model.dart';
import '../../auth/auth_choice_page.dart';
import 'beranda_superadmin_page.dart';

<<<<<<< HEAD
import 'data_anak/data_pasien_page.dart';
import 'data_anak/pilih_anak_button_sheet.dart';
import 'kelola_resep_mpasi/daftar_resep_mpasi_admin_page.dart';
import 'kelola_artikel/daftar_artikel_admin_page.dart';
import 'permainan/daftar_soal_permainan_page.dart';
import 'rekapitulasi/rekapitulasi_stunting_page.dart';
import '../konsultasi/konsultasi_superadmin_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import '../profil/profil_superadmin_page.dart';
import '../profil/hak_akses/hak_akses_page.dart';

/// Halaman Dashboard & Profil Staf (Dokter / PMIK) setelah login.
=======
import 'beranda_superadmin_page.dart';

/// Halaman sementara setelah staf berhasil login.
>>>>>>> 7ce746daae19543c2e5c6c8493406e73d74689a1
///
/// Menerapkan kontrol hak akses dokter secara ketat sesuai
/// pengaturan hak akses yang ditentukan oleh Superadmin.
class StaffHomePlaceholderPage extends StatefulWidget {
  final StaffAccount account;
  const StaffHomePlaceholderPage({super.key, required this.account});

  @override
  State<StaffHomePlaceholderPage> createState() =>
      _StaffHomePlaceholderPageState();
}

class _StaffHomePlaceholderPageState extends State<StaffHomePlaceholderPage> {
  late StaffAccount _account;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    if (_account.isSuperAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const BerandaSuperadminPage()),
          );
        }
      });
      return;
    }
    _refreshAccount();
  }

  Future<void> _refreshAccount() async {
    final updated =
        await StaffAuthService().getStaffAccountById(_account.id);
    if (updated != null && mounted) {
      setState(() {
        _account = updated;
      });
    }
  }

  void _logout(BuildContext context) {
    StaffAuthService().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthChoicePage()),
      (route) => false,
    );
  }

  void _handleFeatureTap(DoctorPermissionItem item) {
    final hasAccess = _account.hasPermission(item.key);
    if (!hasAccess) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Akses fitur "${item.label}" dinonaktifkan oleh Superadmin.',
                  style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      switch (item.key) {
        case 'rekapitulasi':
        case 'download_dataset_rekapitulasi':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const RekapitulasiStuntingPage(),
            ),
          );
          break;
        case 'data_pasien':
        case 'detail_pasien':
        case 'edit_resume_medis':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DataPasienPage(),
            ),
          );
          break;
        case 'ruang_obrolan':
        case 'konsultasi':
        case 'konfirmasi_konsultasi':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const KonsultasiSuperadminPage(),
            ),
          );
          break;
        case 'daftar_resep_mpasi':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DaftarResepMpasiAdminPage(),
            ),
          );
          break;
        case 'daftar_artikel_kesehatan':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DaftarArtikelAdminPage(),
            ),
          );
          break;
        case 'grafik_pengguna':
        case 'download_dataset_pengguna':
          PilihAnakBottomSheet.showForGrafik(context);
          break;
        case 'permainan':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DaftarSoalPermainanPage(),
            ),
          );
          break;
        case 'riwayat_konsultasi':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DaftarRiwayatKonsultasiAdminPage(),
            ),
          );
          break;
        case 'profil':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ProfilSuperadminPage(),
            ),
          );
          break;
        case 'hak_akses':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const HakAksesPage(),
            ),
          );
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fitur ${item.label} aktif'),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (account.role == StaffRole.superadmin || account.role == StaffRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BerandaSuperadminPage()),
        );
      });
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (Navigator.of(context).canPop()) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF0F172A),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          'Portal ${_account.role.label}',
                          style: GoogleFonts.lato(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const BerandaSuperadminPage(),
                              ),
                              (route) => false,
                            );
                          },
                          icon: const Icon(
                            Icons.home_rounded,
                            color: Color(0xFF3985E7),
                          ),
                          tooltip: 'Beranda Utama',
                        ),
                        IconButton(
                          onPressed: () => _logout(context),
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFDC2626),
                          ),
                          tooltip: 'Keluar',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: const Color(0xFF3985E7),
          onRefresh: _refreshAccount,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KARTU PROFIL STAF
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 10.0,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56.0,
                        height: 56.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 34.0,
                          color: Color(0xFF3985E7),
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _account.name,
                              style: GoogleFonts.lato(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              _account.email,
                              style: GoogleFonts.lato(
                                fontSize: 13.0,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6.0),
                                border: Border.all(
                                  color: const Color(0xFFA7F3D0),
                                ),
                              ),
                              child: Text(
                                'Role: ${_account.role.label} (Aktif)',
                                style: GoogleFonts.lato(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF065F46),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),

                // SECTION HAK AKSES & KONTROL DOKTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kontrol Hak Akses Fitur',
                      style: GoogleFonts.lato(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Diatur Superadmin',
                      style: GoogleFonts.lato(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3985E7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),

                // LIST 16 HAK AKSES
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 10.0,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: List.generate(
                      DoctorPermissions.allPermissions.length,
                      (index) {
                        final item = DoctorPermissions.allPermissions[index];
                        final isAllowed = _account.hasPermission(item.key);
                        final isLast = index ==
                            DoctorPermissions.allPermissions.length - 1;

                        return Column(
                          children: [
                            InkWell(
                              onTap: () => _handleFeatureTap(item),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isAllowed
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded,
                                      size: 20.0,
                                      color: isAllowed
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 12.0),
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: GoogleFonts.lato(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w600,
                                          color: isAllowed
                                              ? const Color(0xFF1E293B)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 3.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAllowed
                                            ? const Color(0xFFEFF6FF)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius:
                                            BorderRadius.circular(6.0),
                                      ),
                                      child: Text(
                                        isAllowed ? 'Aktif' : 'Dibatasi',
                                        style: GoogleFonts.lato(
                                          fontSize: 11.0,
                                          fontWeight: FontWeight.bold,
                                          color: isAllowed
                                              ? const Color(0xFF3985E7)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isLast)
                              const Divider(
                                height: 1.0,
                                thickness: 0.8,
                                color: Color(0xFFF1F5F9),
                                indent: 16.0,
                                endIndent: 16.0,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
