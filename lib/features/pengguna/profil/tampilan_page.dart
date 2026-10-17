import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/theme_service.dart';

/// Halaman pengaturan tampilan (tema) aplikasi PediaGrow.
///
/// Tiga pilihan tema:
/// 1. Default Sistem  — mengikuti pengaturan HP.
/// 2. Mode Terang     — tampilan cerah penuh.
/// 3. Mode Gelap      — tampilan gelap hemat baterai.
///
/// Pilihan yang diketuk langsung diterapkan ke seluruh aplikasi dan disimpan.
class TampilanPage extends StatelessWidget {
  const TampilanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final headerTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF000000);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER ────────────────────────────────────────────────────
            _buildHeader(context, headerTextColor, dividerColor),

            // ─── INTRO TEXT ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Pilih tema aplikasi sesuai kenyamanan Anda. '
                'Pratinjau menunjukkan tampilan tiap pilihan.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: subtitleColor,
                  height: 1.5,
                ),
              ),
            ),

            // ─── PILIHAN TEMA ───────────────────────────────────────────────
            Expanded(
              child: ValueListenableBuilder<AppThemeMode>(
                valueListenable: ThemeService().themeModeNotifier,
                builder: (context, currentMode, _) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _ThemeOptionCard(
                        mode: AppThemeMode.system,
                        currentMode: currentMode,
                        title: 'Default Sistem',
                        description:
                            'Mengikuti pengaturan tampilan perangkat Anda.',
                        preview: const _SystemPreview(),
                        isDark: isDark,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 12),
                      _ThemeOptionCard(
                        mode: AppThemeMode.light,
                        currentMode: currentMode,
                        title: 'Mode Terang',
                        description:
                            'Tampilan cerah, nyaman dipakai di siang hari.',
                        preview: const _PhonePreview(dark: false),
                        isDark: isDark,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 12),
                      _ThemeOptionCard(
                        mode: AppThemeMode.dark,
                        currentMode: currentMode,
                        title: 'Mode Gelap',
                        description:
                            'Nyaman di mata saat malam hari dan lebih hemat baterai.',
                        preview: const _PhonePreview(dark: true),
                        isDark: isDark,
                        colorScheme: colorScheme,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Color textColor,
    Color dividerColor,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 8.0,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: textColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tampilan',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: dividerColor),
      ],
    );
  }
}

// =============================================================================
// KARTU PILIHAN TEMA
// =============================================================================

class _ThemeOptionCard extends StatelessWidget {
  final AppThemeMode mode;
  final AppThemeMode currentMode;
  final String title;
  final String description;
  final Widget preview;
  final bool isDark;
  final ColorScheme colorScheme;

  const _ThemeOptionCard({
    required this.mode,
    required this.currentMode,
    required this.title,
    required this.description,
    required this.preview,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == currentMode;
    const accent = Color(0xFF3985E7);

    final cardBg = isSelected
        ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFECF6FF))
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

    final borderColor = isSelected
        ? accent
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    final titleColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final descColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return GestureDetector(
      onTap: () => ThemeService().setTheme(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pratinjau HP mini
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: preview,
            ),

            const SizedBox(width: 14),

            // Judul + deskripsi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: descColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Radio button
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accent : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  width: 2,
                ),
                color: isSelected ? accent : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PRATINJAU: DEFAULT SISTEM (kiri terang, kanan gelap)
// =============================================================================

class _SystemPreview extends StatelessWidget {
  const _SystemPreview();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 104,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            // Bagian kiri — terang
            Expanded(child: _PhonePreviewHalf(dark: false, isLeft: true)),
            // Bagian kanan — gelap
            Expanded(child: _PhonePreviewHalf(dark: true, isLeft: false)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PRATINJAU: SATU SISI (terang ATAU gelap) untuk Default Sistem
// =============================================================================

class _PhonePreviewHalf extends StatelessWidget {
  final bool dark;
  final bool isLeft;
  const _PhonePreviewHalf({required this.dark, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF0F172A) : Colors.white;
    final header = dark ? const Color(0xFF1565C0) : const Color(0xFF3985E7);
    final card = dark ? const Color(0xFF1E293B) : const Color(0xFFECF6FF);
    final line = dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status bar + header biru
          Container(
            height: 28,
            color: header,
          ),
          const SizedBox(height: 4),
          // Kartu kecil 1
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: line, width: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Kartu kecil 2
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: line, width: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Kartu kecil 3
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: line, width: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PRATINJAU: PENUH (terang ATAU gelap)
// =============================================================================

class _PhonePreview extends StatelessWidget {
  final bool dark;
  const _PhonePreview({required this.dark});

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF0F172A) : Colors.white;
    final header = dark ? const Color(0xFF1565C0) : const Color(0xFF3985E7);
    final card = dark ? const Color(0xFF1E293B) : const Color(0xFFECF6FF);
    final card2 = dark ? const Color(0xFF1A2744) : const Color(0xFFF0FDF4);
    final line = dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      width: 64,
      height: 104,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar biru
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: header,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          // Kartu 1
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Kartu 2
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: card2,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Kartu 3
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
