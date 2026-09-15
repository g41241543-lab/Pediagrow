import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/growth_record_model.dart';
import '../services/zscore_calculator.dart';

/// Widget Grafik Pertumbuhan Anak interaktif dengan latar belakang
/// pita zona warna KMS Balita (WHO/Kemenkes RI) dan garis pertumbuhan riwayat anak.
class KmsGrowthChart extends StatefulWidget {
  final List<GrowthRecordModel> records; // Terurut termuda ke tertua
  final bool isGirl;
  final ChartIndicatorType activeIndicator;
  final ValueChanged<ChartIndicatorType> onIndicatorChanged;

  const KmsGrowthChart({
    super.key,
    required this.records,
    required this.isGirl,
    required this.activeIndicator,
    required this.onIndicatorChanged,
  });

  @override
  State<KmsGrowthChart> createState() => _KmsGrowthChartState();
}

class _KmsGrowthChartState extends State<KmsGrowthChart> {
  GrowthRecordModel? _selectedRecord;

  @override
  void didUpdateWidget(covariant KmsGrowthChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndicator != widget.activeIndicator) {
      _selectedRecord = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Toggle Tab 3 Pilihan: "Berat Badan", "Tinggi Badan", "Lingkar Kepala"
          _buildTabToggle(),

          const SizedBox(height: 12),

          // 2. Legend / Keterangan Pita Warna KMS
          _buildKmsLegend(),

          const SizedBox(height: 10),

          // 3. Area Kanvas Grafik KMS
          SizedBox(
            height: 240,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapUp: (details) => _handleTap(details, constraints.biggest),
                  child: CustomPaint(
                    size: constraints.biggest,
                    painter: _KmsChartPainter(
                      records: widget.records,
                      isGirl: widget.isGirl,
                      indicator: widget.activeIndicator,
                      selectedRecord: _selectedRecord,
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Detail Tooltip interaktif jika ada titik yang dipilih
          if (_selectedRecord != null) ...[
            const SizedBox(height: 10),
            _buildSelectedPointTooltip(_selectedRecord!),
          ],
        ],
      ),
    );
  }

  /// Toggle Tab 3 Pilihan: Berat Badan, Tinggi Badan, Lingkar Kepala
  Widget _buildTabToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'Berat Badan',
              indicator: ChartIndicatorType.weight,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTabButton(
              title: 'Tinggi Badan',
              indicator: ChartIndicatorType.height,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTabButton(
              title: 'Lingkar Kepala',
              indicator: ChartIndicatorType.headCircumference,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required ChartIndicatorType indicator,
  }) {
    final isActive = widget.activeIndicator == indicator;
    return GestureDetector(
      onTap: () => widget.onIndicatorChanged(indicator),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive
                ? const Color(0xFF3985E7)
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  /// Keterangan Pita Warna KMS Balita
  Widget _buildKmsLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          color: const Color(0xFF4ADE80), // Hijau normal
          label: 'Normal',
        ),
        const SizedBox(width: 14),
        _buildLegendItem(
          color: const Color(0xFFFBBF24), // Kuning waspada
          label: 'Waspada',
        ),
        const SizedBox(width: 14),
        _buildLegendItem(
          color: const Color(0xFFF87171), // Merah gizi buruk / BGM
          label: 'Gizi Buruk',
        ),
        const SizedBox(width: 14),
        _buildLegendItem(
          color: widget.isGirl
              ? const Color(0xFFEC4899)
              : const Color(0xFF2563EB),
          label: 'Anak',
          isLine: true,
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool isLine = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLine)
          Container(
            width: 14,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 11,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Tooltip bubble data titik pengukuran yang dipilih
  Widget _buildSelectedPointTooltip(GrowthRecordModel record) {
    double value;
    String unit;
    switch (widget.activeIndicator) {
      case ChartIndicatorType.weight:
        value = record.weightKg;
        unit = 'kg';
        break;
      case ChartIndicatorType.height:
        value = record.heightCm;
        unit = 'cm';
        break;
      case ChartIndicatorType.headCircumference:
        value = record.headCircumferenceCm;
        unit = 'cm';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${record.ageMonths} Bulan (${record.ageFormatted})',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                record.isBirthRecord
                    ? 'Pengukuran Saat Lahir'
                    : '${record.date.day}/${record.date.month}/${record.date.year}',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3985E7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${value.toStringAsFixed(1)} $unit',
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3985E7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(TapUpDetails details, Size size) {
    if (widget.records.isEmpty) return;

    final padding = _KmsChartPainter.chartPadding;
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;

    final yRange = _getYRange(widget.activeIndicator);
    final touchPos = details.localPosition;

    GrowthRecordModel? closest;
    double minDistance = 28.0; // Ambang batas radius tap

    for (final rec in widget.records) {
      final x = padding.left + (rec.ageMonths / 60.0) * chartWidth;
      final value = _getValue(rec, widget.activeIndicator);
      final normalizedY = (value - yRange.min) / (yRange.max - yRange.min);
      final y = padding.top + (1.0 - normalizedY.clamp(0.0, 1.0)) * chartHeight;

      final dist = (touchPos - Offset(x, y)).distance;
      if (dist < minDistance) {
        minDistance = dist;
        closest = rec;
      }
    }

    setState(() {
      _selectedRecord = closest;
    });
  }

  static double _getValue(GrowthRecordModel rec, ChartIndicatorType ind) {
    switch (ind) {
      case ChartIndicatorType.weight:
        return rec.weightKg;
      case ChartIndicatorType.height:
        return rec.heightCm;
      case ChartIndicatorType.headCircumference:
        return rec.headCircumferenceCm;
    }
  }

  static ({double min, double max}) _getYRange(ChartIndicatorType ind) {
    switch (ind) {
      case ChartIndicatorType.weight:
        return (min: 0.0, max: 24.0);
      case ChartIndicatorType.height:
        return (min: 40.0, max: 125.0);
      case ChartIndicatorType.headCircumference:
        return (min: 30.0, max: 55.0);
    }
  }
}

/// CustomPainter untuk menggambar kurva pita warna KMS Balita (WHO)
/// serta garis trend pertumbuhan anak
class _KmsChartPainter extends CustomPainter {
  final List<GrowthRecordModel> records;
  final bool isGirl;
  final ChartIndicatorType indicator;
  final GrowthRecordModel? selectedRecord;

  static const chartPadding = EdgeInsets.fromLTRB(36, 12, 16, 26);

  _KmsChartPainter({
    required this.records,
    required this.isGirl,
    required this.indicator,
    this.selectedRecord,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartLeft = chartPadding.left;
    final chartTop = chartPadding.top;
    final chartWidth = size.width - chartPadding.left - chartPadding.right;
    final chartHeight = size.height - chartPadding.top - chartPadding.bottom;
    final chartBottom = chartTop + chartHeight;
    final chartRight = chartLeft + chartWidth;

    final yRange = _KmsGrowthChartState._getYRange(indicator);

    // Ambil kurva WHO -3, -2, 0 (median), +2, +3 SD
    final curveM3 = ZScoreCalculator.getPercentileCurve(
      indicator: indicator,
      isGirl: isGirl,
      targetZ: -3.0,
    );
    final curveM2 = ZScoreCalculator.getPercentileCurve(
      indicator: indicator,
      isGirl: isGirl,
      targetZ: -2.0,
    );
    final curveMedian = ZScoreCalculator.getPercentileCurve(
      indicator: indicator,
      isGirl: isGirl,
      targetZ: 0.0,
    );
    final curveP2 = ZScoreCalculator.getPercentileCurve(
      indicator: indicator,
      isGirl: isGirl,
      targetZ: 2.0,
    );
    final curveP3 = ZScoreCalculator.getPercentileCurve(
      indicator: indicator,
      isGirl: isGirl,
      targetZ: 3.0,
    );

    // Helper konversi (bulan, nilai) -> (x, y) Canvas
    Offset toCanvasOffset(int month, double value) {
      final x = chartLeft + (month / 60.0) * chartWidth;
      final normalizedY =
          (value - yRange.min) / (yRange.max - yRange.min);
      final y = chartTop + (1.0 - normalizedY.clamp(0.0, 1.0)) * chartHeight;
      return Offset(x, y);
    }

    // -------------------------------------------------------------------------
    // 1. GAMBAR GRID & SUMBU X, Y
    // -------------------------------------------------------------------------
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.8;

    final textStyle = GoogleFonts.lato(
      fontSize: 9,
      color: const Color(0xFF94A3B8),
      fontWeight: FontWeight.w600,
    );

    // Garis horizontal sumbu Y
    final yTicks = _getYTicks(indicator);
    for (final tick in yTicks) {
      final normalizedY = (tick - yRange.min) / (yRange.max - yRange.min);
      final y = chartTop + (1.0 - normalizedY) * chartHeight;

      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);

      // Label teks sumbu Y
      final textSpan = TextSpan(
        text: tick.toInt().toString(),
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(chartLeft - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    // Garis vertikal sumbu X (bulan 0, 12, 24, 36, 48, 60)
    for (int m = 0; m <= 60; m += 12) {
      final x = chartLeft + (m / 60.0) * chartWidth;
      canvas.drawLine(Offset(x, chartTop), Offset(x, chartBottom), gridPaint);

      // Label teks sumbu X
      final textSpan = TextSpan(
        text: '$m',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartBottom + 6),
      );
    }

    // Label sumbu X di pojok kanan bawah
    final xLabelSpan = TextSpan(
      text: '(Bulan)',
      style: GoogleFonts.lato(
        fontSize: 8,
        color: const Color(0xFF64748B),
        fontWeight: FontWeight.bold,
      ),
    );
    final xLabelPainter = TextPainter(
      text: xLabelSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    xLabelPainter.paint(
      canvas,
      Offset(chartRight - xLabelPainter.width, chartBottom + 16),
    );

    // -------------------------------------------------------------------------
    // 2. GAMBAR PITA ZONA WARNA KMS (WHO/KEMENKES)
    // -------------------------------------------------------------------------

    // A. Zona Merah Bawah (Gizi Buruk / BGM: < -3 SD)
    final pathRedBottom = Path();
    pathRedBottom.moveTo(chartLeft, chartBottom);
    for (int m = 0; m <= 60; m++) {
      final pt = toCanvasOffset(m, curveM3[m]!);
      pathRedBottom.lineTo(pt.dx, pt.dy);
    }
    pathRedBottom.lineTo(chartRight, chartBottom);
    pathRedBottom.close();
    canvas.drawPath(
      pathRedBottom,
      Paint()..color = const Color(0xFFFFCDD2).withValues(alpha: 0.65),
    );

    // B. Zona Kuning Bawah (Waspada: -3 SD s/d -2 SD)
    _drawBand(
      canvas: canvas,
      lowerCurve: curveM3,
      upperCurve: curveM2,
      toCanvasOffset: toCanvasOffset,
      color: const Color(0xFFFFF59D).withValues(alpha: 0.70),
    );

    // C. Zona Hijau (Gizi Normal: -2 SD s/d +2 SD)
    _drawBand(
      canvas: canvas,
      lowerCurve: curveM2,
      upperCurve: curveP2,
      toCanvasOffset: toCanvasOffset,
      color: const Color(0xFFC8E6C9).withValues(alpha: 0.75),
    );

    // D. Zona Kuning Atas (Waspada Risiko Lebih: +2 SD s/d +3 SD)
    _drawBand(
      canvas: canvas,
      lowerCurve: curveP2,
      upperCurve: curveP3,
      toCanvasOffset: toCanvasOffset,
      color: const Color(0xFFFFF59D).withValues(alpha: 0.70),
    );

    // E. Garis Median (0 SD) — Putus-putus atau hijau lembut
    final medianPaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final medianPath = Path();
    for (int m = 0; m <= 60; m++) {
      final pt = toCanvasOffset(m, curveMedian[m]!);
      if (m == 0) {
        medianPath.moveTo(pt.dx, pt.dy);
      } else {
        medianPath.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(medianPath, medianPaint);

    // -------------------------------------------------------------------------
    // 3. GAMBAR TREND LINE PERTUMBUHAN ANAK (HISTORIS)
    // -------------------------------------------------------------------------
    if (records.isNotEmpty) {
      final genderColor = isGirl
          ? const Color(0xFFE83D84) // Pink cerah anak perempuan KMS
          : const Color(0xFF2563EB); // Biru cerah anak laki-laki KMS

      final linePaint = Paint()
        ..color = genderColor
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final trendPath = Path();
      final List<Offset> points = [];

      for (int i = 0; i < records.length; i++) {
        final rec = records[i];
        final val = _KmsGrowthChartState._getValue(rec, indicator);
        final pt = toCanvasOffset(rec.ageMonths, val);
        points.add(pt);

        if (i == 0) {
          trendPath.moveTo(pt.dx, pt.dy);
        } else {
          trendPath.lineTo(pt.dx, pt.dy);
        }
      }

      // Gambar garis sambung
      canvas.drawPath(trendPath, linePaint);

      // Gambar titik-titik (dots) di setiap pengukuran
      final dotFillPaint = Paint()..color = Colors.white;
      final dotBorderPaint = Paint()
        ..color = genderColor
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < points.length; i++) {
        final pt = points[i];
        final rec = records[i];
        final isSelected = selectedRecord?.id == rec.id;

        if (isSelected) {
          // Highlight circle di luar
          canvas.drawCircle(
            pt,
            8.0,
            Paint()..color = genderColor.withValues(alpha: 0.3),
          );
        }

        // Bulatan putih dengan border gender
        canvas.drawCircle(pt, isSelected ? 5.5 : 4.5, dotFillPaint);
        canvas.drawCircle(pt, isSelected ? 5.5 : 4.5, dotBorderPaint);
      }
    }
  }

  void _drawBand({
    required Canvas canvas,
    required Map<int, double> lowerCurve,
    required Map<int, double> upperCurve,
    required Offset Function(int, double) toCanvasOffset,
    required Color color,
  }) {
    final path = Path();
    for (int m = 0; m <= 60; m++) {
      final pt = toCanvasOffset(m, upperCurve[m]!);
      if (m == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    for (int m = 60; m >= 0; m--) {
      final pt = toCanvasOffset(m, lowerCurve[m]!);
      path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  List<double> _getYTicks(ChartIndicatorType ind) {
    switch (ind) {
      case ChartIndicatorType.weight:
        return [0, 4, 8, 12, 16, 20, 24];
      case ChartIndicatorType.height:
        return [40, 55, 70, 85, 100, 115, 125];
      case ChartIndicatorType.headCircumference:
        return [30, 35, 40, 45, 50, 55];
    }
  }

  @override
  bool shouldRepaint(covariant _KmsChartPainter oldDelegate) {
    return oldDelegate.records != records ||
        oldDelegate.isGirl != isGirl ||
        oldDelegate.indicator != indicator ||
        oldDelegate.selectedRecord != selectedRecord;
  }
}
