import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/stunting_limit_service.dart';
import '../../models/child_model.dart';
import '../../shared/widgets/illustration_forest_footer.dart';
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
    final isGirl = widget.child.gender.toLowerCase().contains('perempuan');

    // Menghitung usia saat ini dalam format ringkas "X Tahun Y Bulan"
    final String currentAgeFormatted = _getShortAgeFormatted(widget.child);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
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

            // Status gizi berdasarkan BB/TB atau data pengukuran terbaru
            final String statusGizi = latestRecord?.statusGizi ?? 'Gizi Normal';
            final Color statusColor = ZScoreCalculator.getStatusColor(statusGizi);
            final Color statusBgColor =
                ZScoreCalculator.getStatusBgColor(statusGizi);
            final String statusDesc =
                ZScoreCalculator.getStatusDescription(statusGizi);

            return Column(
              children: [
                // -------------------------------------------------------------
                // 1. HEADER HALAMAN TETAP (Padding 56dp dari atas)
                // -------------------------------------------------------------
                _buildHeader(context, currentAgeFormatted),

                // -------------------------------------------------------------
                // 2. KONTEN UTAMA SCROLLABLE (Margin 16dp kiri & kanan)
                // -------------------------------------------------------------
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Keterangan "Terakhir diupdate: [tanggal]"
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 15,
                                color: Color(0xFF7F7F7F),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Terakhir diupdate: $lastUpdatedText',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF7F7F7F),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Tiga Kartu Statistik Ringkas Berdampingan
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: GrowthStatCardsRow(
                            weightKg: latestRecord?.weightKg ?? widget.child.weightKg,
                            heightCm: latestRecord?.heightCm ?? widget.child.heightCm,
                            headCircumferenceCm: latestRecord?.headCircumferenceCm ??
                                widget.child.headCircumferenceCm,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Judul "Grafik Pertumbuhan Anak"
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Grafik Pertumbuhan Anak',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Widget Grafik Pertumbuhan Interaktif (KMS Balita WHO)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: KmsGrowthChart(
                            records: recordsOldestFirst,
                            isGirl: isGirl,
                            activeIndicator: _activeIndicator,
                            onIndicatorChanged: (newInd) {
                              setState(() => _activeIndicator = newInd);
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // -----------------------------------------------------
                        // 3. BAR STATUS GIZI & DESKRIPSI
                        // -----------------------------------------------------
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildStatusGiziSection(
                            statusGizi: statusGizi,
                            statusColor: statusColor,
                            statusBgColor: statusBgColor,
                            statusDesc: statusDesc,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // -----------------------------------------------------
                        // 4. TOMBOL "+ Data Pertumbuhan Baru"
                        // Solid Blue #3985E7, lebar 350, tinggi 48, radius 17
                        // -----------------------------------------------------
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Center(
                            child: SizedBox(
                              width: 350,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () => _openAddMeasurement(context),
                                icon: const Icon(Icons.add,
                                    color: Colors.white, size: 20),
                                label: Text(
                                  '+ Data Pertumbuhan Baru',
                                  style: GoogleFonts.lato(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3985E7),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // -----------------------------------------------------
                        // 5. ILUSTRASI DEKORATIF FOOTER (Pohon, Rumput, Tenda)
                        // -----------------------------------------------------
                        const IllustrationForestFooter(
                          height: 110,
                          fit: BoxFit.cover,
                        ),
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
  // 1. HEADER HALAMAN
  // Jarak 56dp dari atas layar, tombol back 12dp dari kiri, judul 12dp setelahnya.
  // ===========================================================================
  Widget _buildHeader(BuildContext context, String ageFormatted) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.only(top: 56.0, bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tombol Back (posisi 12dp dari tepi kiri layar)
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xFF000000),
                  size: 24,
                ),
              ),
            ),

            // Jarak 12dp setelah tombol back
            const SizedBox(width: 12),

            // Judul "Pertumbuhan" & Subtitle Nama Anak, Usia (#7F7F7F)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pertumbuhan',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF000000),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.child.name}, $ageFormatted',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF7F7F7F),
                    ),
                  ),
                ],
              ),
            ),

            // Ikon Riwayat Berbentuk Panah Melingkar di Pojok Kanan Atas
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RiwayatPertumbuhanPage(child: widget.child),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFF1E293B),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. BAR STATUS GIZI, TEKS DESKRIPSI & LINK KONSULTASI DOKTER
  // ===========================================================================
  Widget _buildStatusGiziSection({
    required String statusGizi,
    required Color statusColor,
    required Color statusBgColor,
    required String statusDesc,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bar Status Gizi Dinamis
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusGizi == 'Gizi Normal'
                      ? Icons.check_circle_rounded
                      : Icons.warning_rounded,
                  color: statusColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  statusGizi,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Teks Deskripsi Penjelasan Status Gizi
          Text(
            statusDesc,
            style: GoogleFonts.lato(
              fontSize: 13,
              height: 1.5,
              color: const Color(0xFF475569),
            ),
          ),

          const SizedBox(height: 10),

          // Link Teks "Konsultasikan dengan dokter"
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
                Text(
                  'Konsultasikan dengan dokter',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3985E7),
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFF3985E7),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Color(0xFF3985E7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. NAVIGASI INPUT DATA PERTUMBUHAN BARU (CEK STUNTING / FORM INPUT)
  // ===========================================================================
  void _openAddMeasurement(BuildContext context) {
    // ── Cek Batas 2x per Bulan per Anak ───────────────────────────────────
    if (!StuntingLimitService().canCheck(widget.child.id)) {
      PediaBanner.showError(
        context,
        message:
            'Batas input data pertumbuhan 2x per bulan sudah tercapai untuk anak ini. Coba lagi bulan depan.',
      );
      return;
    }
    // ─────────────────────────────────────────────────────────────────────
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormCekStuntingPage(child: widget.child),
      ),
    );
  }

  /// Menghitung format usia singkat "X Tahun Y Bulan"
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

    if (years <= 0) {
      return '$months Bulan';
    }
    return '$years Tahun $months Bulan';
  }
}
