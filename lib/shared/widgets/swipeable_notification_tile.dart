import 'package:flutter/material.dart';

/// Widget wrapper item notifikasi yang dapat digeser (swipe/slide ke kiri)
/// untuk memunculkan tombol hapus berwarna merah dengan ikon tempat sampah putih.
///
/// Spesifikasi:
/// - Mengikuti referensi screenshot pengguna (hanya opsi hapus merah, tanpa titik 3).
/// - Ketika digeser ke kiri, membuka tombol merah berlebar 76dp dengan ikon sampah.
/// - Mengetuk tombol merah akan memicu callback [onDelete].
/// - Mengetuk item saat terbuka akan menutup kembali geseran.
/// - Mengetuk item saat tertutup akan memicu callback [onTap].
class SwipeableNotificationTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const SwipeableNotificationTile({
    super.key,
    required this.child,
    required this.onDelete,
    this.onTap,
    this.backgroundColor,
  });

  @override
  State<SwipeableNotificationTile> createState() =>
      _SwipeableNotificationTileState();
}

class _SwipeableNotificationTileState extends State<SwipeableNotificationTile>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 76.0;

  late final AnimationController _controller;
  double _dragExtent = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent =
          (_dragExtent + details.primaryDelta!).clamp(-_actionWidth, 0.0);
      _controller.value = (-_dragExtent) / _actionWidth;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (velocity < -300 || _dragExtent < -(_actionWidth / 2)) {
      // Buka penuh aksi hapus
      _controller.animateTo(1.0, curve: Curves.easeOutCubic);
      _dragExtent = -_actionWidth;
    } else {
      // Tutup kembali
      _controller.animateTo(0.0, curve: Curves.easeOutCubic);
      _dragExtent = 0.0;
    }
  }

  void close() {
    if (_controller.value > 0) {
      _controller.animateTo(0.0, curve: Curves.easeOutCubic);
      _dragExtent = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ??
        (isDark ? const Color(0xFF0B1014) : Colors.white);

    return ClipRect(
      child: Stack(
        children: [
          // -------------------------------------------------------------
          // LATAR BELAKANG: Tombol Hapus Merah (Sisi Kanan)
          // -------------------------------------------------------------
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: _actionWidth,
                child: Material(
                  color: const Color(0xFFE53E3E), // Merah cerah seperti referensi
                  child: InkWell(
                    onTap: () {
                      close();
                      widget.onDelete();
                    },
                    child: const Center(
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------
          // KONTEN UTAMA NOTIFIKASI (Dapat Digeser)
          // -------------------------------------------------------------
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final offset = -_controller.value * _actionWidth;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: _handleDragUpdate,
              onHorizontalDragEnd: _handleDragEnd,
              onTap: () {
                if (_controller.value > 0.1) {
                  close();
                } else {
                  widget.onTap?.call();
                }
              },
              child: Container(
                color: bgColor,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
