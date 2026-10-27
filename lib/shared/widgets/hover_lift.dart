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

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(18.0);

    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) {
        if (mounted) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _hovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -widget.lift : 0, 0),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: _hovered
              ? const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 18.0,
                    offset: Offset(0, 8),
                  ),
                ]
              : const [],
        ),
        child: widget.child,
      ),
    );
  }
}
