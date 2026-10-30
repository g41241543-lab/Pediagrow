import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../models/user_model.dart';
import '../../../../shared/widgets/illustration_forest_footer.dart';

/// Halaman Data Orangtua untuk POV Superadmin.
///
/// Menampilkan:
/// - Header fixed 56dp dengan tombol kembali & judul "Data Orangtua".
/// - Card profil orang tua dengan avatar foto / inisial, nama, email, dan status akun.
/// - Card biodata lengkap orang tua: nama, email, nomor telepon, jenis kelamin,
///   tanggal lahir, provinsi, kota/kabupaten, kecamatan, dan kelurahan/desa.
/// - Sesuai instruksi: list anak di bawahnya sudah tidak ditampilkan lagi.
class DetailPenggunaPage extends StatefulWidget {
  final UserModel user;

  const DetailPenggunaPage({super.key, required this.user});

  @override
  State<DetailPenggunaPage> createState() => _DetailPenggunaPageState();
}

class _DetailPenggunaPageState extends State<DetailPenggunaPage> {
  static const Color _colorPrimaryBlue = Color(0xFF2B7AE8);
  static const Color _colorLabelGrey = Color(0xFF667781);
  static const Color _colorTextBlack = Color(0xFF1A2228);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1014) : const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── 1. Header Fixed 56dp ───────────────────────────────
            _buildFixedHeader(),

            // ── 2. Konten Scrollable ──────────────────────────────
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
                            const SizedBox(height: 16),

                            // ── Card Profil Header Orang Tua ─────────
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildProfileHeaderCard(),
                            ),

                            const SizedBox(height: 16),

                            // ── Tabel Biodata Lengkap Orang Tua ──────
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildBiodataTable(),
                            ),

                            const SizedBox(height: 24),

                            // Spacer agar ilustrasi menempel di dasar
                            const Spacer(),

                            // Ilustrasi footer landscape
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
      bottomNavigationBar: null,
    );
  }

  // ──────────────────────────────────────────────────────────────
  // HEADER FIXED 56dp
  // ──────────────────────────────────────────────────────────────
  Widget _buildFixedHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 56,
      color: isDark ? const Color(0xFF0B1014) : Colors.white,
      padding: const EdgeInsets.only(left: 12, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back,
                color: isDark ? const Color(0xFFE9EDEF) : Colors.black,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Data Orangtua',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // CARD PROFIL HEADER ORANG TUA
  // Menampilkan avatar, nama besar, email, dan chip status terdaftar
  // ──────────────────────────────────────────────────────────────
  Widget _buildProfileHeaderCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final u = widget.user;
    final initialLetter = u.name.isNotEmpty ? u.name[0].toUpperCase() : 'O';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFD6E4FF),
          width: 1.5,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: _colorPrimaryBlue.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar Orang Tua
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242E35) : const Color(0xFFEBF3FF),
              shape: BoxShape.circle,
              border: Border.all(
                color: _colorPrimaryBlue.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: u.avatarPath != null && u.avatarPath!.trim().isNotEmpty
                ? StorageService.buildImageWidget(
                    u.avatarPath,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    placeholder: Center(
                      child: Text(
                        initialLetter,
                        style: GoogleFonts.lato(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _colorPrimaryBlue,
                        ),
                      ),
                    ),
                    errorWidget: Center(
                      child: Text(
                        initialLetter,
                        style: GoogleFonts.lato(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _colorPrimaryBlue,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      initialLetter,
                      style: GoogleFonts.lato(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _colorPrimaryBlue,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          // Info Teks Orang Tua
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.name.isNotEmpty ? u.name : 'Orang Tua Pasien',
                  style: GoogleFonts.lato(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  u.email.isNotEmpty ? u.email : '-',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF8696A0) : _colorLabelGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Badge Terdaftar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF2E7D32),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Orang Tua Terdaftar',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // CARD DATA ORANG TUA (PENGGUNA)
  // ──────────────────────────────────────────────────────────────
  Widget _buildBiodataTable() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final u = widget.user;

    final rows = <_TableRowData>[
      _TableRowData(
        icon: Icons.person_outline_rounded,
        label: 'Nama Lengkap',
        value: u.name.isNotEmpty ? u.name : '-',
      ),
      _TableRowData(
        icon: Icons.email_outlined,
        label: 'Email',
        value: u.email.isNotEmpty ? u.email : '-',
      ),
      _TableRowData(
        icon: Icons.phone_outlined,
        label: 'Nomor Telepon',
        value: u.phone?.isNotEmpty == true ? u.phone! : '-',
      ),
      _TableRowData(
        icon: Icons.wc_outlined,
        label: 'Jenis Kelamin',
        value: _formatGender(u.gender),
      ),
      _TableRowData(
        icon: Icons.calendar_today_outlined,
        label: 'Tanggal Lahir',
        value: _formatDate(u.birthDate),
      ),
      _TableRowData(
        icon: Icons.map_outlined,
        label: 'Provinsi',
        value: u.province?.isNotEmpty == true ? u.province! : '-',
      ),
      _TableRowData(
        icon: Icons.location_city_outlined,
        label: 'Kota / Kabupaten',
        value: u.city?.isNotEmpty == true ? u.city! : '-',
      ),
      _TableRowData(
        icon: Icons.holiday_village_outlined,
        label: 'Kecamatan',
        value: u.district?.isNotEmpty == true ? u.district! : '-',
      ),
      _TableRowData(
        icon: Icons.home_work_outlined,
        label: 'Kelurahan / Desa',
        value: u.subDistrict?.isNotEmpty == true ? u.subDistrict! : '-',
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFD6E4FF),
          width: 1.5,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: Icon kotak biru + Judul
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF242E35)
                      : const Color(0xFFEBF3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: _colorPrimaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Biodata Orangtua',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
          ),
          const SizedBox(height: 14),

          // Baris-baris Data Key-Value
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 10),
              Divider(
                height: 1,
                thickness: 0.7,
                color: isDark
                    ? const Color(0xFF242E35)
                    : const Color(0xFFF1F5F9),
              ),
              const SizedBox(height: 10),
            ],
            _buildRowItem(rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildRowItem(_TableRowData item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          item.icon,
          size: 18,
          color: _colorPrimaryBlue.withValues(alpha: 0.75),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 125,
          child: Text(
            item.label,
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF8696A0) : _colorLabelGrey,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.value,
            style: GoogleFonts.lato(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  // HELPER FORMATTING
  // ──────────────────────────────────────────────────────────────
  String _formatGender(String? g) {
    if (g == null || g.trim().isEmpty) return '-';
    final l = g.toLowerCase().trim();
    if (l == 'l' || l == 'laki-laki' || l == 'pria') return 'Laki-laki';
    if (l == 'p' || l == 'perempuan' || l == 'wanita') return 'Perempuan';
    return g;
  }

  String _formatDate(String? d) {
    if (d == null || d.trim().isEmpty) return '-';
    try {
      final dt = DateTime.parse(d);
      const months = [
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
        'Desember',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return d;
    }
  }
}

class _TableRowData {
  final IconData icon;
  final String label;
  final String value;

  _TableRowData({
    required this.icon,
    required this.label,
    required this.value,
  });
}
