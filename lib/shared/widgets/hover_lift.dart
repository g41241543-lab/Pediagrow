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

class _HoverLiftState extends State<HoverLift>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;

  bool get _isLifted => _hovered || _pressed;


  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(18.0);

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _isLifted ? -widget.lift : 0, 0),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _isLifted
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
    );

    // Tambahkan MouseRegion untuk hover di desktop/web/pointer
    content = MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: content,
    );

    // Tambahkan GestureDetector untuk efek sentuh di mobile
    content = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: content,
    );

    return content;
  }
}
