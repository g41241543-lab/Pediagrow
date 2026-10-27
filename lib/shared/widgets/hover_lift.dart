import 'package:flutter/material.dart';

/// Widget yang menambahkan efek "terangkat" saat kursor diarahkan (desktop/web)
/// atau saat ditekan (mobile/touch). Bekerja lintas platform.
class HoverLift extends StatefulWidget {
  final Widget child;
  final double lift;
  final MouseCursor cursor;
  final BorderRadius? borderRadius;

  const HoverLift({
    super.key,
    required this.child,
    this.lift = 3.0,
    this.cursor = SystemMouseCursors.basic,
    this.borderRadius,
  });

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;
  bool _pressed = false;
  Offset? _pointerDownPos;

  bool get _isLifted => _hovered || _pressed;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(18.0);

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _isLifted ? -widget.lift : 0, 0),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _isLifted
            ? const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 16.0,
                  offset: Offset(0, 6),
                ),
              ]
            : const [],
      ),
      child: widget.child,
    );

    // MouseRegion untuk hover saat menggunakan mouse (web/desktop)
    content = MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) {
        if (mounted) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _hovered = false);
      },
      child: content,
    );

    // Listener untuk mendeteksi sentuhan di layar HP (touch/mobile)
    // Listener tidak memblokir InkWell atau gesture arena
    content = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _pointerDownPos = e.position;
        if (mounted) setState(() => _pressed = true);
      },
      onPointerMove: (e) {
        if (_pointerDownPos != null && _pressed) {
          final distance = (e.position - _pointerDownPos!).distance;
          if (distance > 10.0) {
            if (mounted) setState(() => _pressed = false);
          }
        }
      },
      onPointerUp: (_) {
        _pointerDownPos = null;
        if (mounted) setState(() => _pressed = false);
      },
      onPointerCancel: (_) {
        _pointerDownPos = null;
        if (mounted) setState(() => _pressed = false);
      },
      child: content,
    );

    return content;
  }
}
