import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Komponen Notifikasi Banner Melayang di Bagian Atas Layar PediaGrow.
///
/// Tampilan dan perilaku diselaraskan 100% dengan banner notifikasi ketika
/// Profil Ibu berhasil disimpan:
/// - Posisi: Melayang di bagian atas layar (top: 62dp / tepat di bawah status bar / header).
/// - Bentuk & Radius: Rounded 17dp dengan tinggi 56dp (atau menyesuaikan panjang teks).
/// - Warna: Biru utama `#3985E7` (atau merah `#E53E3E` untuk error/peringatan).
/// - Shadow: Drop shadow lembut dengan warna banner (alpha 35%, blur 10, offset y=4).
/// - Typography: Font Lato, 14sp, Bold, Putih `#FFFFFF`.
/// - Aksi: Ikon tombol silang [Icons.close] hitam `#000000` di sebelah kanan untuk menutup seketika.
/// - Otomatis tertutup halus setelah durasi yang ditentukan atau saat di-swipe ke atas.
class PediaBanner {
  static OverlayEntry? _currentEntry;
  static _PediaBannerWidgetState? _currentState;

  /// Menampilkan notifikasi banner melayang di atas layar.
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
  }) {
    // Sembunyikan banner yang sedang aktif terlebih dahulu agar tidak menumpuk
    hide();

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final bannerColor = backgroundColor ??
        (isError ? const Color(0xFFE53E3E) : const Color(0xFF3985E7));

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return _PediaBannerWidget(
          message: message,
          color: bannerColor,
          duration: duration,
          onDispose: () {
            if (_currentEntry == entry) {
              _currentEntry = null;
              _currentState = null;
            }
          },
          onDismiss: onDismiss,
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// Menampilkan notifikasi banner sukses (warna biru utama #3985E7)
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
  }) {
    show(
      context,
      message: message,
      isError: false,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  /// Menampilkan notifikasi banner error / peringatan (warna merah #E53E3E)
  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
  }) {
    show(
      context,
      message: message,
      isError: true,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  /// Menutup banner yang sedang aktif secara halus
  static void hide() {
    _currentState?.dismiss();
    _currentEntry?.remove();
    _currentEntry = null;
    _currentState = null;
  }
}

class _PediaBannerWidget extends StatefulWidget {
  final String message;
  final Color color;
  final Duration duration;
  final VoidCallback onDispose;
  final VoidCallback? onDismiss;

  const _PediaBannerWidget({
    required this.message,
    required this.color,
    required this.duration,
    required this.onDispose,
    this.onDismiss,
  });

  @override
  State<_PediaBannerWidget> createState() => _PediaBannerWidgetState();
}

class _PediaBannerWidgetState extends State<_PediaBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    PediaBanner._currentState = this;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _slideAnimation = Tween<double>(begin: -80.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward();

    // Timer penutupan otomatis
    _autoDismissTimer = Timer(widget.duration, () {
      dismiss();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animController.dispose();
    widget.onDispose();
    super.dispose();
  }

  void dismiss() {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    _autoDismissTimer?.cancel();

    _animController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
        PediaBanner._currentEntry?.remove();
        PediaBanner._currentEntry = null;
        PediaBanner._currentState = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 62.0,
      left: 16.0,
      right: 16.0,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            // Swipe ke atas untuk menutup seketika
            if (details.primaryDelta != null && details.primaryDelta! < -4) {
              dismiss();
            }
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Teks Pesan (Lato 14sp, Bold, Putih #FFFFFF)
                  Expanded(
                    child: Text(
                      widget.message,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFFFFF),
                        height: 1.25,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Tombol Silang Penutup (Icons.close, 20px, Hitam #000000)
                  InkWell(
                    onTap: dismiss,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
