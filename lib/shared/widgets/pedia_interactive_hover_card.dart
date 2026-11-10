import 'package:flutter/material.dart';

/// Card container yang memiliki border biru muda lembut (#BFDBFE) dan soft blue shadow secara default,
/// serta memberikan feedback interaktif berupa pengangkatan (-3px), border menyala biru (#3985E7),
/// dan latar beraksen biru muda (#F0F7FF) saat kursor diarahkan (hover di desktop/web)
/// maupun saat disentuh/ditekan (press di layar HP / touchscreen).
class PediaInteractiveHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? normalBorderColor;
  final Color? activeBorderColor;
  final Color? normalBgColor;
  final Color? activeBgColor;
  final double normalBorderWidth;
  final double activeBorderWidth;
  final double hoverOffset;
  final List<BoxShadow>? normalBoxShadow;
  final List<BoxShadow>? activeBoxShadow;

  const PediaInteractiveHoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.padding,
    this.margin,
    this.normalBorderColor,
    this.activeBorderColor,
    this.normalBgColor,
    this.activeBgColor,
    this.normalBorderWidth = 1.2,
    this.activeBorderWidth = 1.8,
    this.hoverOffset = -3.0,
    this.normalBoxShadow,
    this.activeBoxShadow,
  });

  @override
  State<PediaInteractiveHoverCard> createState() =>
      _PediaInteractiveHoverCardState();
}

class _PediaInteractiveHoverCardState extends State<PediaInteractiveHoverCard> {
  bool _isHovered = false;
  bool _isPressed = false;
  Offset? _pointerDownPos;

  bool get _isActive => _isHovered || _isPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF3985E7);
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

    final defaultBorder = isDark
        ? const Color(0xFF2C363D)
        : const Color(0xFFBFDBFE);
    final borderColor = _isActive
        ? (widget.activeBorderColor ?? primaryBlue)
        : (widget.normalBorderColor ?? defaultBorder);

    final defaultNormalBg = isDark
        ? const Color(0xFF1A2228)
        : Colors.white;
    final defaultActiveBg = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF0F7FF);
    final bgColor = _isActive
        ? (widget.activeBgColor ?? defaultActiveBg)
        : (widget.normalBgColor ?? defaultNormalBg);

    final defaultNormalShadow = [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : primaryBlue.withValues(alpha: 0.08),
        blurRadius: 10,
        spreadRadius: 0,
        offset: const Offset(0, 3),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
        blurRadius: 6,
        spreadRadius: 0,
        offset: const Offset(0, 1),
      ),
    ];

    final defaultActiveShadow = [
      BoxShadow(
        color: primaryBlue.withValues(alpha: isDark ? 0.35 : 0.20),
        blurRadius: 14,
        spreadRadius: 0,
        offset: const Offset(0, 5),
      ),
    ];

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      margin: widget.margin,
      transform: Matrix4.translationValues(
        0,
        _isActive ? widget.hoverOffset : 0,
        0,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        border: Border.all(
          color: borderColor,
          width: _isActive ? widget.activeBorderWidth : widget.normalBorderWidth,
        ),
        boxShadow: _isActive
            ? (widget.activeBoxShadow ?? defaultActiveShadow)
            : (widget.normalBoxShadow ?? defaultNormalShadow),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          splashColor: primaryBlue.withValues(alpha: 0.08),
          highlightColor: primaryBlue.withValues(alpha: 0.04),
          hoverColor: Colors.transparent,
          onTap: widget.onTap,
          child: Padding(
            padding: widget.padding ?? EdgeInsets.zero,
            child: widget.child,
          ),
        ),
      ),
    );

    // MouseRegion untuk hover mouse (Desktop / Web)
    content = MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      child: content,
    );

    // Listener untuk mendeteksi sentuhan di layar HP (Mobile / Touchscreen)
    content = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _pointerDownPos = e.position;
        if (mounted) setState(() => _isPressed = true);
      },
      onPointerMove: (e) {
        if (_pointerDownPos != null && _isPressed) {
          final distance = (e.position - _pointerDownPos!).distance;
          if (distance > 10.0) {
            if (mounted) setState(() => _isPressed = false);
          }
        }
      },
      onPointerUp: (_) {
        _pointerDownPos = null;
        if (mounted) setState(() => _isPressed = false);
      },
      onPointerCancel: (_) {
        _pointerDownPos = null;
        if (mounted) setState(() => _isPressed = false);
      },
      child: content,
    );

    return content;
  }
}

