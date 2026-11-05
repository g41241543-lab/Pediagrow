import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dialog pemilih waktu dengan jam putar (wheel scroll picker)
/// bergaya drum roll / alarm smartphone (kolom J untuk jam dan M untuk menit).
Future<String?> showPediaWheelTimePicker({
  required BuildContext context,
  required String initialTime,
  String title = 'Atur Jam',
  String? subtitle,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => PediaWheelTimePickerDialog(
      initialTime: initialTime,
      title: title,
      subtitle: subtitle,
    ),
  );
}

class PediaWheelTimePickerDialog extends StatefulWidget {
  final String initialTime;
  final String title;
  final String? subtitle;

  const PediaWheelTimePickerDialog({
    super.key,
    required this.initialTime,
    required this.title,
    this.subtitle,
  });

  @override
  State<PediaWheelTimePickerDialog> createState() =>
      _PediaWheelTimePickerDialogState();
}

class _PediaWheelTimePickerDialogState
    extends State<PediaWheelTimePickerDialog> {
  late int _selectedHour;
  late int _selectedMinute;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  static const Color _primaryBlue = Color(0xFF0284C7);

  @override
  void initState() {
    super.initState();
    _parseInitialTime();
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController =
        FixedExtentScrollController(initialItem: _selectedMinute);
  }

  void _parseInitialTime() {
    int h = 8;
    int m = 30;
    try {
      final parts = widget.initialTime.trim().split(':');
      if (parts.isNotEmpty) {
        h = int.tryParse(parts[0]) ?? 8;
      }
      if (parts.length > 1) {
        m = int.tryParse(parts[1]) ?? 30;
      }
    } catch (_) {}
    _selectedHour = h.clamp(0, 23);
    _selectedMinute = m.clamp(0, 59);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E242B) : Colors.white;
    final textBlack = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014);
    final textGrey = isDark ? const Color(0xFF8696A0) : const Color(0xFF64748B);
    final highlightBg = isDark
        ? const Color(0xFF334155).withValues(alpha: 0.55)
        : const Color(0xFFF1F5F9);

    final hourStr = _selectedHour.toString().padLeft(2, '0');
    final minuteStr = _selectedMinute.toString().padLeft(2, '0');

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Judul Dialog
            Text(
              widget.title,
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textBlack,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle ?? 'Waktu terpilih: $hourStr:$minuteStr WIB',
              style: GoogleFonts.lato(
                fontSize: 13,
                color: textGrey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            // Header Kolom 'J' dan 'M'
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'J',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textGrey,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Center(
                    child: Text(
                      'M',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textGrey,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Area Jam Putar (Wheel Pickers)
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Highlight bar tengah untuk angka yang terpilih
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: highlightBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _primaryBlue.withValues(alpha: 0.2),
                        width: 1.2,
                      ),
                    ),
                  ),

                  // Dua Roda Putar: Jam (J) dan Menit (M)
                  Row(
                    children: [
                      // Roda Jam (00 - 23)
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: _hourController,
                          itemExtent: 44,
                          perspective: 0.003,
                          diameterRatio: 1.3,
                          squeeze: 1.15,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            final h = ((index % 24) + 24) % 24;
                            setState(() {
                              _selectedHour = h;
                            });
                            HapticFeedback.selectionClick();
                          },
                          childDelegate: ListWheelChildLoopingListDelegate(
                            children: List.generate(24, (i) {
                              final isSelected = i == _selectedHour;
                              return Center(
                                child: Text(
                                  i.toString().padLeft(2, '0'),
                                  style: GoogleFonts.lato(
                                    fontSize: isSelected ? 28 : 20,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? textBlack
                                        : textGrey.withValues(alpha: 0.55),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),

                      // Pemisah Titik Dua Tengah
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          ':',
                          style: GoogleFonts.lato(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _primaryBlue,
                          ),
                        ),
                      ),

                      // Roda Menit (00 - 59)
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: _minuteController,
                          itemExtent: 44,
                          perspective: 0.003,
                          diameterRatio: 1.3,
                          squeeze: 1.15,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            final m = ((index % 60) + 60) % 60;
                            setState(() {
                              _selectedMinute = m;
                            });
                            HapticFeedback.selectionClick();
                          },
                          childDelegate: ListWheelChildLoopingListDelegate(
                            children: List.generate(60, (i) {
                              final isSelected = i == _selectedMinute;
                              return Center(
                                child: Text(
                                  i.toString().padLeft(2, '0'),
                                  style: GoogleFonts.lato(
                                    fontSize: isSelected ? 28 : 20,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? textBlack
                                        : textGrey.withValues(alpha: 0.55),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Tombol Aksi: Batal & Selesai
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF2C363D)
                            : const Color(0xFFF1F5F9),
                        foregroundColor: isDark ? Colors.white : textBlack,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textGrey,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: _primaryBlue.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      onPressed: () {
                        final formatted =
                            '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';
                        Navigator.of(context).pop(formatted);
                      },
                      child: Text(
                        'Selesai',
                        style: GoogleFonts.lato(
                          fontSize: 14,
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
    );
  }
}

