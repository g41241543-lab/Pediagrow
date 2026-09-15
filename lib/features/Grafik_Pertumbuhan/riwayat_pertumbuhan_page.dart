import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/child_model.dart';
import 'detail_riwayat_pertumbuhan_page.dart';
import 'models/growth_record_model.dart';
import 'services/growth_service.dart';
import 'services/zscore_calculator.dart';

/// Halaman Riwayat Pertumbuhan Anak.
///
/// Menampilkan daftar seluruh entri pengukuran pertumbuhan anak,
/// diurutkan dari terbaru ke terlama. Tampilan per entri berupa kartu
/// yang identik dengan card pada halaman Lokasi Fasyankes.
class RiwayatPertumbuhanPage extends StatelessWidget {
  final ChildModel child;

  const RiwayatPertumbuhanPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // 1. HEADER TETAP (56dp dari atas layar)
            // -----------------------------------------------------------------
            _buildHeader(context),

            // -----------------------------------------------------------------
            // 2. DAFTAR KARTU RIWAYAT PENGUKURAN
            // -----------------------------------------------------------------
            Expanded(
              child: ValueListenableBuilder<Map<String, List<GrowthRecordModel>>>(
                valueListenable: GrowthService().recordsNotifier,
                builder: (context, _, __) {
                  final records =
                      GrowthService().getRecordsForChildNewestFirst(child.id);

                  if (records.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return _buildMeasurementCard(context, record);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER (Spacing 56dp, Tombol Back 12dp dari kiri, Judul 12dp setelahnya)
  // ===========================================================================
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.only(top: 56.0, bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tombol Kembali (12dp dari tepi kiri layar)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
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

            // Jarak 12dp setelah tombol kembali
            const SizedBox(width: 12),

            // Judul "Riwayat Pertumbuhan"
            Expanded(
              child: Text(
                'Riwayat Pertumbuhan',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF000000),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. KARTU PENGUKURAN (Tampilan Sama dengan Card Lokasi Fasyankes)
  // ===========================================================================
  Widget _buildMeasurementCard(BuildContext context, GrowthRecordModel record) {
    final statusColor = ZScoreCalculator.getStatusColor(record.statusGizi);
    final statusBgColor = ZScoreCalculator.getStatusBgColor(record.statusGizi);

    final dateStr = formatTanggalIndonesia(record.date);
    final headerDateAge = '$dateStr - ${record.ageFormatted}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DetailRiwayatPertumbuhanPage(
                  child: child,
                  record: record,
                ),
              ),
            );
          },
          splashColor: const Color(0xFF3985E7).withValues(alpha: 0.08),
          highlightColor: const Color(0xFF3985E7).withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card: Ikon Kalender Kecil + [tanggal] - X Tahun Y Bulan Z Hari + Badge Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        headerDateAge,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Badge Status Gizi Kecil
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        record.statusGizi,
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Garis pemisah halus
                Container(
                  width: double.infinity,
                  height: 1,
                  color: const Color(0xFFF1F5F9),
                ),

                const SizedBox(height: 12),

                // Tabel dengan Tiga Kolom: Berat, Tinggi, L. Kepala
                Row(
                  children: [
                    // Kolom 1: Berat
                    Expanded(
                      child: _buildMetricColumn(
                        label: 'Berat',
                        value: '${record.weightKg.toStringAsFixed(1)} kg',
                        icon: Icons.monitor_weight_outlined,
                        iconColor: const Color(0xFF0284C7),
                      ),
                    ),

                    // Divider vertikal
                    Container(
                      width: 1,
                      height: 36,
                      color: const Color(0xFFE2E8F0),
                    ),

                    // Kolom 2: Tinggi
                    Expanded(
                      child: _buildMetricColumn(
                        label: 'Tinggi',
                        value: '${record.heightCm.toStringAsFixed(1)} cm',
                        icon: Icons.straighten_outlined,
                        iconColor: const Color(0xFF16A34A),
                      ),
                    ),

                    // Divider vertikal
                    Container(
                      width: 1,
                      height: 36,
                      color: const Color(0xFFE2E8F0),
                    ),

                    // Kolom 3: L. Kepala
                    Expanded(
                      child: _buildMetricColumn(
                        label: 'L. Kepala',
                        value:
                            '${record.headCircumferenceCm.toStringAsFixed(1)} cm',
                        icon: Icons.face_outlined,
                        iconColor: const Color(0xFF9333EA),
                      ),
                    ),
                  ],
                ),

                if (record.isBirthRecord) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Color(0xFF3985E7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Data Awal Kelahiran',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3985E7),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricColumn({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 11,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              size: 56,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum Ada Riwayat Pengukuran',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Data hasil cek stunting atau pengukuran baru akan otomatis dicatat di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
