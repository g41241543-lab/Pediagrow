import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget Pesan Cepat (Quick Messages) dengan tampilan menyerupai Grab Chat.
///
/// Menyediakan template pesan konsultasi medis siap pakai untuk:
/// - Pengguna (Orang Tua / Pasien): salam dinamis sesuai waktu, ucapan terima kasih,
///   konfirmasi pemahaman, pertanyaan aturan obat, pengiriman foto, dsb.
/// - Dokter: salam dinamis, penawaran bantuan, instruksi penanganan awal,
///   konfirmasi gejala anak, penegasan dosis obat & pemantauan faskes.
class PesanCepatWidget extends StatefulWidget {
  /// Apakah widget ini ditampilkan untuk dokter (true) atau pengguna (false).
  final bool isDoctor;

  /// Mode gelap aktif.
  final bool isDark;

  /// Callback saat template pesan dipilih untuk langsung dikirim.
  final ValueChanged<String> onSendMessage;

  /// Callback opsional jika pengguna ingin menyalin template ke kolom input pesan.
  final ValueChanged<String>? onSelectToInput;

  /// FocusNode input pesan untuk auto-collapse saat keyboard muncul.
  final FocusNode? focusNode;

  const PesanCepatWidget({
    super.key,
    required this.isDoctor,
    required this.isDark,
    required this.onSendMessage,
    this.onSelectToInput,
    this.focusNode,
  });

  @override
  State<PesanCepatWidget> createState() => _PesanCepatWidgetState();
}

class _PesanCepatWidgetState extends State<PesanCepatWidget> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant PesanCepatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      widget.focusNode?.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (widget.focusNode?.hasFocus == true && _isExpanded && mounted) {
      setState(() {
        _isExpanded = false;
      });
    }
  }

  /// Menghasilkan salam dinamis berdasarkan jam saat ini.
  String _getContextualGreeting() {
    final hour = DateTime.now().hour;
    String waktu = 'pagi';
    if (hour >= 11 && hour < 15) {
      waktu = 'siang';
    } else if (hour >= 15 && hour < 18) {
      waktu = 'sore';
    } else if (hour >= 18 || hour < 4) {
      waktu = 'malam';
    }

    if (widget.isDoctor) {
      return 'Halo, selamat $waktu. Ada yang bisa saya bantu terkait kondisi si kecil?';
    } else {
      return 'Selamat $waktu, Dokter.';
    }
  }

  /// Daftar template pesan cepat yang relevan untuk konsultasi medis anak.
  List<String> _getTemplates() {
    final greeting = _getContextualGreeting();
    final List<String> baseTemplates;

    if (widget.isDoctor) {
      baseTemplates = [
        greeting,
        'Halo, ada yang bisa saya bantu untuk si kecil?',
        'Sama-sama, semoga si kecil lekas sembuh dan sehat selalu ya.',
        'Apakah si kecil ada demam, batuk, muntah, atau keluhan lainnya saat ini?',
        'Sudah berapa hari gejala ini dialami oleh si kecil?',
        'Pastikan kebutuhan cairan dan nutrisi si kecil tetap tercukupi dengan baik ya.',
        'Obatnya diminum sesuai dosis anjuran ya. Pantau suhu anak secara berkala.',
        'Jika keluhan berlanjut dalam 2-3 hari, segera periksakan langsung ke faskes terdekat ya.',
        'Apakah ada pertanyaan lain atau keluhan tambahan yang ingin dikonsultasikan?',
      ];
    } else {
      baseTemplates = [
        greeting,
        'Halo Dokter.',
        'Terima kasih banyak, Dokter.',
        'Baik Dokter, sudah saya pahami.',
        'Bagaimana anjuran dosis dan aturan minum obatnya, Dokter?',
        'Apakah ada pantangan makanan atau aktivitas tertentu untuk anak saya?',
        'Apakah keluhan ini perlu segera diperiksakan langsung ke faskes/RS?',
      ];
    }

    // Pastikan tidak ada template ganda
    final result = <String>[];
    for (final item in baseTemplates) {
      if (!result.contains(item)) {
        result.add(item);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final templates = _getTemplates();

    final cardBg = isDark ? const Color(0xFF1E262C) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2C363D)
        : const Color(0xFFE2E8F0);
    final textPrimary = isDark
        ? const Color(0xFFE9EDEF)
        : const Color(0xFF1A202C);
    final textSecondary = isDark
        ? const Color(0xFF8696A0)
        : const Color(0xFF64748B);
    final dividerColor = isDark
        ? const Color(0xFF2C363D)
        : const Color(0xFFF1F5F9);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0x0A000000),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar Pesan Cepat (Tappable)
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Ikon Pesan Cepat Hijau Khas Grab
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B14F).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.quickreply_rounded,
                          color: Color(0xFF00B14F),
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Label Pesan Cepat
                    Text(
                      'Pesan Cepat',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Badge status kecil
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C363D)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${templates.length}',
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Hint aksi
                    Text(
                      _isExpanded ? 'Tutup' : 'Lihat opsi',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Chevron Arrow
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      color: textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Daftar Pesan Saat Diperluas (Expanded)
            if (_isExpanded) ...[
              Divider(height: 1, thickness: 0.8, color: dividerColor),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 190),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: templates.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, thickness: 0.8, color: dividerColor),
                  itemBuilder: (context, index) {
                    final item = templates[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onSendMessage(item);
                          setState(() {
                            _isExpanded = false;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item,
                                  style: GoogleFonts.lato(
                                    fontSize: 13,
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              if (widget.onSelectToInput != null) ...[
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: 'Salin ke kolom ketik',
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      widget.onSelectToInput!(item);
                                      setState(() {
                                        _isExpanded = false;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.north_west_rounded,
                                        size: 15,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
