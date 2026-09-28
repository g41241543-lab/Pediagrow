import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/child_model.dart';
import '../../../../shared/widgets/illustration_forest_footer.dart';
import '../../../Grafik_Pertumbuhan/models/growth_record_model.dart';
import '../../../Grafik_Pertumbuhan/services/growth_service.dart';
import '../../../Grafik_Pertumbuhan/services/zscore_calculator.dart';
import '../../../Grafik_Pertumbuhan/widgets/growth_stat_card.dart';
import '../../../Grafik_Pertumbuhan/widgets/kms_growth_chart.dart';

/// Halaman Grafik Pertumbuhan untuk POV Superadmin.
///
/// Identik dengan [PertumbuhanGrafikPage] (POV Pengguna), namun:
/// - Tidak ada tombol **Riwayat Pertumbuhan** di pojok kanan atas.
/// - Tidak ada tombol **"+ Data Pertumbuhan Baru"** di bagian bawah.
/// - Tidak ada link **"Konsultasikan dengan dokter"** di seksi status gizi.
class SuperadminGrafikPage extends StatefulWidget {
  final ChildModel child;

  const SuperadminGrafikPage({super.key, required this.child});

  @override
  State<SuperadminGrafikPage> createState() => _SuperadminGrafikPageState();
}

class _SuperadminGrafikPageState extends State<SuperadminGrafikPage> {
  ChartIndicatorType _activeIndicator = ChartIndicatorType.weight;

  @override
  Widget build(BuildContext context) {
    final isGirl =
        widget.child.gender.toLowerCase().contains('perempuan');
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
                // ─────────────────────────────────────────────────────────────
                // 1. HEADER FIXED
                // ─────────────────────────────────────────────────────────────
                _buildHeader(context, currentAgeFormatted),

                // ─────────────────────────────────────────────────────────────
                // 2. KONTEN SCROLLABLE + ILUSTRASI FIXED DI DASAR
                // ─────────────────────────────────────────────────────────────
                Expanded(
                  child: Stack(
                    children: [
                      // Ilustrasi landscape fixed di bagian dasar
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: IllustrationForestFooter(
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),

                      // Konten scrollable di atasnya
                      Positioned.fill(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),

                              // Keterangan "Terakhir diupdate: [tanggal]"
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: GrowthStatCardsRow(
                                  weightKg: latestRecord?.weightKg ??
                                      widget.child.weightKg,
                                  heightCm: latestRecord?.heightCm ??
                                      widget.child.heightCm,
                                  headCircumferenceCm:
                                      latestRecord?.headCircumferenceCm ??
                                          widget.child.headCircumferenceCm,
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
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Widget Grafik KMS WHO Interaktif
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

                              // ─────────────────────────────────────────────
                              // 3. BAR STATUS GIZI & DESKRIPSI
                              //    (tanpa link "Konsultasikan dengan dokter")
                              // ─────────────────────────────────────────────
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: _buildStatusGiziSection(
                                  statusGizi: statusGizi,
                                  statusColor: statusColor,
                                  statusBgColor: statusBgColor,
                                  statusDesc: statusDesc,
                                ),
                              ),

                              // Ruang dasar agar konten tidak tertutup ilustrasi
                              const SizedBox(height: 36),
                            ],
                          ),
                        ),
                      ),
                    ],
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
  // HEADER — tanpa tombol riwayat di pojok kanan atas
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
            // Tombol Back
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

            const SizedBox(width: 12),

            // Judul "Pertumbuhan" & Subtitle Nama Anak, Usia
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

            // TIDAK ADA tombol riwayat (berbeda dari POV Pengguna)
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BAR STATUS GIZI — tanpa link "Konsultasikan dengan dokter"
  // ===========================================================================
  Widget _buildStatusGiziSection({
    required String statusGizi,
    required Color statusColor,
    required Color statusBgColor,
    required String statusDesc,
  }) {
    final bool isNormal = statusGizi == 'Gizi Normal';
    final Color cardBorderColor =
        isNormal ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2);
    final Color descColor =
        isNormal ? const Color(0xFF1B4332) : const Color(0xFF7F1D1D);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: statusBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Status Gizi Solid
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

          // Deskripsi status gizi
          Text(
            statusDesc,
            style: GoogleFonts.lato(
              fontSize: 13,
              height: 1.5,
              color: descColor,
            ),
          ),

          // TIDAK ADA link "Konsultasikan dengan dokter" di sini
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPER — Format usia singkat "X Tahun Y Bulan"
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

    if (years <= 0) {
      return '$months Bulan';
    }
    return '$years Tahun $months Bulan';
  }
}
