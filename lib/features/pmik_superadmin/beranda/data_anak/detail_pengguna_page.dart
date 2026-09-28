import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/child_model.dart';
import '../../../../models/user_model.dart';
import '../../../../shared/widgets/illustration_forest_footer.dart';

import 'detail_anak_page.dart';

/// Halaman Detail Pengguna untuk POV Superadmin.
///
/// Menampilkan:
/// - Header fixed 56dp dengan tombol kembali & judul "Detail Pengguna".
/// - Card biodata pengguna: nama, email, jenis kelamin, tanggal lahir,
///   provinsi, kota/kabupaten, kecamatan, dan kelurahan/desa.
/// - Card "Data Anak" berisi list profil anak (avatar di kiri, nama & usia, tanda >)
///   yang dapat diklik untuk navigasi ke halaman [DetailAnakPage].
/// - Tanpa navigation bar di bagian bawah.
class DetailPenggunaPage extends StatefulWidget {
  final UserModel user;

  const DetailPenggunaPage({super.key, required this.user});

  @override
  State<DetailPenggunaPage> createState() => _DetailPenggunaPageState();
}

class _DetailPenggunaPageState extends State<DetailPenggunaPage> {
  // ──────────────────────────────────────────────────────────────
  // Konstanta Warna (konsisten dengan desain superadmin)
  // ──────────────────────────────────────────────────────────────
  static const Color _colorPrimaryBlue = Color(0xFF2B7AE8);
  static const Color _colorTableBorder = Color(0xFFE2E8F0);
  static const Color _colorLabelGrey = Color(0xFF64748B);
  static const Color _colorTextBlack = Color(0xFF1E293B);

  // ──────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── 1. Header Fixed 56dp ───────────────────────────────
            _buildFixedHeader(),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

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

                            // ── Tabel Biodata Pengguna ─────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _buildBiodataTable(),
                            ),

                            const SizedBox(height: 20),

                            // ── Tabel Daftar Anak ──────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _buildChildrenTable(),
                            ),

                            const SizedBox(height: 20),

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
    return Container(
      width: double.infinity,
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.only(left: 12, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.arrow_back, color: Colors.black, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Detail Pengguna',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // CARD DATA ORANG TUA (PENGGUNA)
  // Layout identik dengan gambar: Card ber-border lembut, icon kotak
  // biru muda di header, divider tipis, dan list key-value tebal.
  // ──────────────────────────────────────────────────────────────
  Widget _buildBiodataTable() {
    final u = widget.user;

    final rows = <_TableRow>[
      _TableRow('Nama Lengkap', u.name.isNotEmpty ? u.name : '-'),
      _TableRow('Email', u.email.isNotEmpty ? u.email : '-'),
      _TableRow('Jenis Kelamin', _formatGender(u.gender)),
      _TableRow('Tanggal Lahir', _formatDate(u.birthDate)),
      _TableRow('Provinsi', u.province?.isNotEmpty == true ? u.province! : '-'),
      _TableRow('Kota / Kabupaten', u.city?.isNotEmpty == true ? u.city! : '-'),
      _TableRow(
        'Kecamatan',
        u.district?.isNotEmpty == true ? u.district! : '-',
      ),
      _TableRow(
        'Kelurahan / Desa',
        u.subDistrict?.isNotEmpty == true ? u.subDistrict! : '-',
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E4FF), width: 1.5),
        boxShadow: const [
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
                  color: const Color(0xFFEBF3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: _colorPrimaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Data Pengguna',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _colorTextBlack,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Baris-baris Data Key-Value
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _buildKeyValueRow(rows[i].label, rows[i].value),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _colorLabelGrey,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _colorTextBlack,
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  // CARD DATA ANAK (data dari Firestore 'children')
  // Menampilkan judul "Data Anak" beserta list anak:
  // - Profil di kiri (avatar)
  // - Nama dan Usia di tengah
  // - Tanda > di samping kanan
  // - Klik card anak menuju ke DetailAnakPage
  // ──────────────────────────────────────────────────────────────
  Widget _buildChildrenTable() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('children').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildChildrenLoadingSkeleton();
        }

        if (snapshot.hasError) {
          return _buildChildrenErrorState();
        }

        final docs = snapshot.data?.docs ?? [];
        final userId = widget.user.id.trim();
        final userEmail = widget.user.email.trim().toLowerCase();

        final children = <ChildModel>[];

        for (final doc in docs) {
          final data = doc.data();
          final rawOwner = (data['owner_id'] ??
                  data['ownerId'] ??
                  data['userId'] ??
                  data['user_id'] ??
                  data['parentId'] ??
                  data['parent_id'] ??
                  '')
              .toString()
              .trim();

          bool isMatch = false;
          if (userId.isNotEmpty && rawOwner == userId) {
            isMatch = true;
          } else if (userEmail.isNotEmpty &&
              rawOwner.toLowerCase() == userEmail) {
            isMatch = true;
          }

          if (isMatch) {
            children.add(ChildModel.fromMap({...data, 'id': doc.id}));
          }
        }

        if (children.isEmpty) {
          return _buildNoChildrenState();
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD6E4FF), width: 1.5),
            boxShadow: const [
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
              // Header: Icon kotak biru + Judul "Data Anak" + Jumlah anak
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.face_rounded,
                      color: _colorPrimaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Data Anak',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _colorTextBlack,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF3FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${children.length} Anak',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _colorPrimaryBlue,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFF1F5F9),
              ),

              // List Card Anak
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                _buildChildListItem(children[i]),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildChildListItem(ChildModel child) {
    final ageText = _formatChildAge(child);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetailAnakPage(child: child, user: widget.user),
            ),
          );
        },
        splashColor: _colorPrimaryBlue.withValues(alpha: 0.08),
        highlightColor: _colorPrimaryBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profil di kiri
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCEEFF),
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildChildAvatar(child.photoUrl),
              ),
              const SizedBox(width: 14),

              // Nama dan Usia di tengah
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name.isNotEmpty ? child.name : '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _colorTextBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ageText,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: _colorLabelGrey,
                      ),
                    ),
                  ],
                ),
              ),

              // Tanda > di samping kanan
              const Icon(
                Icons.chevron_right_rounded,
                size: 26,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // STATE KOSONG / ERROR / LOADING untuk tabel anak
  // ──────────────────────────────────────────────────────────────
  Widget _buildNoChildrenState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorTableBorder, width: 1),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.child_care_rounded,
            size: 40,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 10),
          Text(
            'Belum Ada Data Anak',
            style: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _colorTextBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pengguna ini belum mendaftarkan profil anak di aplikasi.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 13, color: _colorLabelGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenLoadingSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorTableBorder, width: 1),
      ),
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
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

  Widget _buildChildrenErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorTableBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 22,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(width: 8),
          Text(
            'Gagal memuat data anak.',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // HELPER — avatar anak
  // ──────────────────────────────────────────────────────────────
  Widget _buildChildAvatar(String? imagePath) {
    final fallback = Image.asset(
      'assets/images/default_baby_avatar.png',
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.face_rounded, size: 20, color: _colorPrimaryBlue),
      ),
    );
    if (imagePath == null || imagePath.trim().isEmpty) return fallback;
    final trimmed = imagePath.trim();

    if (trimmed.startsWith('data:image')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final b64 = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        return Image.memory(
          base64Decode(b64.trim()),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      } catch (_) {}
    }
    if (trimmed.startsWith('/9j/') || trimmed.startsWith('iVBORw0KGgo')) {
      try {
        return Image.memory(
          base64Decode(trimmed),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      } catch (_) {}
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (trimmed.startsWith('assets/')) {
      return Image.asset(
        trimmed,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    try {
      final file = File(trimmed);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      }
    } catch (_) {}
    return fallback;
  }

  // ──────────────────────────────────────────────────────────────
  // HELPER — Format data
  // ──────────────────────────────────────────────────────────────
  String _formatGender(String? gender) {
    if (gender == null || gender.trim().isEmpty) return '-';
    final g = gender.toLowerCase().trim();
    if (g == 'l' || g == 'laki-laki' || g == 'male' || g == 'laki') {
      return 'Laki-laki';
    }
    if (g == 'p' || g == 'perempuan' || g == 'female' || g == 'wanita') {
      return 'Perempuan';
    }
    return gender;
  }

  String _formatShortDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatChildAge(ChildModel child) {
    if (child.birthDate != null) {
      final bDate = child.birthDate!;
      final now = DateTime.now();
      int years = now.year - bDate.year;
      int months = now.month - bDate.month;
      int days = now.day - bDate.day;

      if (days < 0) {
        months -= 1;
        final lastDayPrevMonth = DateTime(now.year, now.month, 0);
        days += lastDayPrevMonth.day;
      }
      if (months < 0) {
        years -= 1;
        months += 12;
      }
      if (years < 0) years = 0;
      if (months < 0) months = 0;
      if (days < 0) days = 0;

      if (years == 0 && months == 0) {
        return '$days hari';
      } else if (years == 0) {
        return days > 0 ? '$months bulan $days hari' : '$months bulan';
      } else {
        return months > 0 ? '$years tahun $months bulan' : '$years tahun';
      }
    }

    if (child.ageDescription.isNotEmpty) {
      return child.ageDescription;
    }

    return '-';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return '-';
    try {
      // Coba parse format ISO (YYYY-MM-DD atau Timestamp string)
      final dt = DateTime.parse(dateStr.trim());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Helper classes
// ─────────────────────────────────────────────────────────────────────────────

class _TableRow {
  final String label;
  final String value;
  const _TableRow(this.label, this.value);
}
