import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/stunting_limit_service.dart';
import '../../models/child_model.dart';
import '../../shared/widgets/illustration_forest_footer.dart';
import '../../shared/widgets/pedia_bottom_nav_bar.dart';
import '../../shared/widgets/pedia_banner.dart';
import '../pengguna/konsultasi/daftar_dokter_page.dart';
import '../pengguna/cek_stunting/form_cek_stunting_page.dart';
import 'models/growth_record_model.dart';
import 'riwayat_pertumbuhan_page.dart';
import 'services/growth_service.dart';
import 'services/zscore_calculator.dart';
import 'widgets/growth_stat_card.dart';
import 'widgets/kms_growth_chart.dart';

/// Halaman Utama Pertumbuhan (Grafik) per anak.
///
/// Menyajikan visualisasi grafik KMS Balita resmi WHO/Kemenkes,
/// kartu statistik ringkas, bar status gizi, link konsultasi dokter,
/// dan tombol input data pertumbuhan baru.
///
/// Layout mengikuti pola struktur halaman Cek Stunting (FormCekStuntingPage):
/// - Scaffold.bottomNavigationBar: PediaBottomNavBar (selectedIndex: -1)
/// - SafeArea(bottom: false)
/// - Column:
///   1. Header fixed 56dp (_buildHeader)
///   2. Expanded -> SingleChildScrollView(physics: ClampingScrollPhysics()) -> Column:
///      - Konten (statistik BB/TB, grafik KMS WHO, kartu status gizi, tombol tambah)
///      - SizedBox(height: 24)
///      - Footer ilustrasi landscape (IllustrationForestFooter)
class PertumbuhanGrafikPage extends StatefulWidget {
  final ChildModel child;

  const PertumbuhanGrafikPage({super.key, required this.child});

  @override
  State<PertumbuhanGrafikPage> createState() => _PertumbuhanGrafikPageState();
}

class _PertumbuhanGrafikPageState extends State<PertumbuhanGrafikPage> {
  ChartIndicatorType _activeIndicator = ChartIndicatorType.weight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGirl = widget.child.gender.toLowerCase().contains('perempuan');

    // Format usia singkat "X Tahun Y Bulan"
    final String currentAgeFormatted = _getShortAgeFormatted(widget.child);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1014) : Colors.white,
      // ── NAVBAR BAWAH FIXED ─────────────────────────────────────────────
      // Identik dengan Beranda & halaman lain. selectedIndex: -1 agar tidak
      // ada tab yang menyala (sama seperti Cek Stunting, Resep MPASI, dll).
      bottomNavigationBar: const PediaBottomNavBar(selectedIndex: -1),
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<Map<String, List<GrowthRecordModel>>>(
          valueListenable: GrowthService().recordsNotifier,
          builder: (context, recordsMap, _) {
            final recordsOldestFirst =
                GrowthService().getRecordsForChildOldestFirst(widget.child.id);
            final latestRecord =
                GrowthService().getLatestRecord(widget.child.id);

            // Tanggal pengukuran terakhir
            final String lastUpdatedText = latestRecord != null
                ? formatTanggalIndonesia(latestRecord.date)
                : (widget.child.birthDate != null
                    ? formatTanggalIndonesia(widget.child.birthDate!)
                    : 'Hari ini');

            // Status gizi berdasarkan data pengukuran terbaru
            final String statusGizi =
                latestRecord?.statusGizi ?? 'Gizi Normal';
            final Color statusColor =
                ZScoreCalculator.getStatusColor(statusGizi);
            final Color statusBgColor =
                ZScoreCalculator.getStatusBgColor(statusGizi);
            final String statusDesc =
                ZScoreCalculator.getStatusDescription(statusGizi);

            return Column(
              children: [
                // -----------------------------------------------------------
                // 1. HEADER TETAP (Tinggi 56dp, sama persis dengan Cek Stunting)
                // -----------------------------------------------------------
                _buildHeader(context, currentAgeFormatted, isDark),

                // -----------------------------------------------------------
                // 2. KONTEN SCROLLABLE + ILUSTRASI MENYATU DALAM SATU LAYOUT
                //
                // Pola identik 100% dengan FormCekStuntingPage:
                //   Expanded → SingleChildScrollView(ClampingScrollPhysics)
                //     → Column:
                //         - Subjudul & Kartu Statistik
                //         - Grafik KMS Balita WHO & Legenda
                //         - Card Status Gizi
                //         - Tombol "+ Data Pertumbuhan Baru"
                //         - SizedBox(height: 24)
                //         - Ilustrasi Footer Landscape (_buildFooterLandscapeIllustration)
                // -----------------------------------------------------------
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),

                        // Keterangan "Terakhir diupdate: [tanggal]"
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 15,
                                color: isDark
                                    ? const Color(0xFF8696A0)
                                    : const Color(0xFF7F7F7F),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Terakhir diupdate: $lastUpdatedText',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? const Color(0xFF8696A0)
                                      : const Color(0xFF7F7F7F),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Dua Kartu Statistik Ringkas (BB & TB)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0),
                          child: GrowthStatCardsRow(
                            weightKg: latestRecord?.weightKg ??
                                widget.child.weightKg,
                            heightCm: latestRecord?.heightCm ??
                                widget.child.heightCm,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Judul "Grafik Pertumbuhan Anak"
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0),
                          child: Text(
                            'Grafik Pertumbuhan Anak',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFE9EDEF)
                                  : const Color(0xFF0B1014),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Widget Grafik KMS Balita WHO (interaktif)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0),
                          child: KmsGrowthChart(
                            records: recordsOldestFirst,
                            isGirl: isGirl,
                            activeIndicator: _activeIndicator,
                            onIndicatorChanged: (newInd) {
                              setState(
                                  () => _activeIndicator = newInd);
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Bar Status Gizi & Deskripsi
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0),
                          child: _buildStatusGiziSection(
                            statusGizi: statusGizi,
                            statusColor: statusColor,
                            statusBgColor: statusBgColor,
                            statusDesc: statusDesc,
                            isDark: isDark,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Tombol "+ Data Pertumbuhan Baru"
                        // Solid Blue #3985E7, lebar 350, tinggi 48, radius 17
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0),
                          child: Center(
                            child: SizedBox(
                              width: 350,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _openAddMeasurement(context),
                                icon: const Icon(Icons.add,
                                    color: Colors.white, size: 20),
                                label: Text(
                                  'Data Pertumbuhan Baru',
                                  style: GoogleFonts.lato(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF3985E7),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(17),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Ilustrasi Footer Landscape (Menempel ke Nav Bar)
                        _buildFooterLandscapeIllustration(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER HALAMAN TETAP (Tinggi 56dp)
  //
  // Mengikuti standar header Cek Stunting & halaman lainnya:
  // Tombol Back 12dp dari kiri, judul "Grafik Pertumbuhan" 12dp setelahnya,
  // dan ikon riwayat di sebelah kanan.
  // ===========================================================================
  Widget _buildHeader(
      BuildContext context, String ageFormatted, bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      color: isDark ? const Color(0xFF0B1014) : Colors.white,
      padding: const EdgeInsets.only(left: 12.0, right: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Back (12dp dari tepi kiri layar)
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back,
                color: isDark
                    ? const Color(0xFFE9EDEF)
                    : const Color(0xFF000000),
                size: 24,
              ),
            ),
          ),

          // Jarak 12dp setelah tombol back
          const SizedBox(width: 12),

          // Judul "Grafik Pertumbuhan" & Subtitle nama anak, usia
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Grafik Pertumbuhan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFE9EDEF)
                        : const Color(0xFF000000),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.child.name}, $ageFormatted',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: isDark
                        ? const Color(0xFF8696A0)
                        : const Color(0xFF7F7F7F),
                  ),
                ),
              ],
            ),
          ),

          // Ikon Riwayat (lingkaran abu-abu di pojok kanan)
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      RiwayatPertumbuhanPage(child: widget.child),
                ),
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A2228)
                    : const Color(0xFFE9EDEF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.history_rounded,
                color: isDark
                    ? const Color(0xFFE9EDEF)
                    : const Color(0xFF1A2228),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FOOTER ILUSTRASI LANDSCAPE (PERSIS SAMA DENGAN CEK STUNTING)
  // ===========================================================================
  Widget _buildFooterLandscapeIllustration() {
    return const IllustrationForestFooter(fit: BoxFit.fitWidth);
  }

  // ===========================================================================
  // 2. SECTION STATUS GIZI (Bar + Deskripsi + Link Konsultasi)
  // ===========================================================================
  Widget _buildStatusGiziSection({
    required String statusGizi,
    required Color statusColor,
    required Color statusBgColor,
    required String statusDesc,
    required bool isDark,
  }) {
    final bool isNormal = statusGizi == 'Gizi Normal';
    final Color cardBorderColor = isDark
        ? (isNormal
            ? const Color(0xFF047857)
            : const Color(0xFFB91C1C))
        : (isNormal
            ? const Color(0xFFC8E6C9)
            : const Color(0xFFFFCDD2));
    final Color descColor = isDark
        ? (isNormal
            ? const Color(0xFFA7F3D0)
            : const Color(0xFFFECACA))
        : (isNormal
            ? const Color(0xFF1B4332)
            : const Color(0xFF7F1D1D));
    final Color effectiveBgColor = isDark
        ? (isNormal
            ? const Color(0xFF064E3B).withValues(alpha: 0.3)
            : const Color(0xFF7F1D1D).withValues(alpha: 0.3))
        : statusBgColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: isDark ? 0.04 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge status gizi (solid color)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isNormal
                      ? Icons.check_circle_rounded
                      : Icons.warning_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  statusGizi,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Deskripsi penjelasan status gizi
          Text(
            statusDesc,
            style: GoogleFonts.lato(
              fontSize: 13,
              height: 1.5,
              color: descColor,
            ),
          ),

          const SizedBox(height: 10),

          // Link "Konsultasikan dengan dokter →"
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DaftarDokterPage(),
                ),
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'Konsultasikan dengan dokter',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      decoration: TextDecoration.underline,
                      decorationColor: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: statusColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. NAVIGASI INPUT DATA PERTUMBUHAN BARU
  // ===========================================================================
  void _openAddMeasurement(BuildContext context) {
    // Cek batas 2× per bulan per anak
    if (!StuntingLimitService().canCheck(widget.child.id)) {
      PediaBanner.showError(
        context,
        message:
            'Batas input data pertumbuhan 2x per bulan sudah tercapai untuk anak ini. Coba lagi bulan depan.',
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormCekStuntingPage(child: widget.child),
      ),
    );
  }

  // ===========================================================================
  // HELPER: Format usia singkat "X Tahun Y Bulan"
  // ===========================================================================
  String _getShortAgeFormatted(ChildModel child) {
    if (child.birthDate == null) return child.ageDescription;
    final now = DateTime.now();
    final birth = child.birthDate!;

    int years = now.year - birth.year;
    int months = now.month - birth.month;
    if (now.day < birth.day) months -= 1;
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    if (years <= 0) return '$months Bulan';
    return '$years Tahun $months Bulan';
  }
}
