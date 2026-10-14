import 'package:flutter/material.dart';

import '../../models/child_model.dart';

/// Reusable Widget Avatar Anak Resmi PediaGrow
///
/// Menampilkan ikon wajah anak yang seragam sesuai panduan:
/// - Jika Perempuan:
///   * Menggunakan ikon anak perempuan (rambut poni kemerahan, rona merah muda di pipi)
///   * Latar belakang Soft Pink / Merah Muda (#FFEEF0)
/// - Jika Laki-laki / Default:
///   * Menggunakan ikon anak laki-laki (rambut hitam rapi, tanpa rona merah di pipi)
///   * Latar belakang Soft Blue / Biru Muda (#EBF5FF)
class ChildAvatar extends StatelessWidget {
  final String? gender;
  final bool? isGirl;
  final ChildModel? child;
  final double size;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final EdgeInsetsGeometry? padding;

  const ChildAvatar({
    super.key,
    this.gender,
    this.isGirl,
    this.child,
    this.size = 40.0,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.padding,
  });

  /// Helper untuk mengecek apakah anak berjenis kelamin perempuan
  static bool isFemaleGender({String? gender, ChildModel? child, bool? isGirl}) {
    if (isGirl != null) return isGirl;
    final g = (gender ?? child?.gender ?? '').toLowerCase().trim();
    return g.contains('perempuan') ||
        g.contains('wanita') ||
        g.contains('female') ||
        g == 'p' ||
        g == 'pr';
  }

  /// Asset path sesuai gender anak
  static String assetPathFor({String? gender, ChildModel? child, bool? isGirl}) {
    final female = isFemaleGender(gender: gender, child: child, isGirl: isGirl);
    return female
        ? 'assets/images/baby_avatar_girl.png'
        : 'assets/images/baby_avatar_boy.png';
  }

  /// Warna background default sesuai gender anak
  static Color bgColorFor({String? gender, ChildModel? child, bool? isGirl}) {
    final female = isFemaleGender(gender: gender, child: child, isGirl: isGirl);
    return female ? const Color(0xFFFFEEF0) : const Color(0xFFEBF5FF);
  }

  /// Warna border halus default sesuai gender anak
  static Color borderColorFor({String? gender, ChildModel? child, bool? isGirl}) {
    final female = isFemaleGender(gender: gender, child: child, isGirl: isGirl);
    return female ? const Color(0xFFFBCFE8) : const Color(0xFFBFDBFE);
  }

  @override
  Widget build(BuildContext context) {
    final female = isFemaleGender(gender: gender, child: child, isGirl: isGirl);
    final assetPath = female
        ? 'assets/images/baby_avatar_girl.png'
        : 'assets/images/baby_avatar_boy.png';

    final effectiveBgColor = backgroundColor ??
        (female ? const Color(0xFFFFEEF0) : const Color(0xFFEBF5FF));

    final effectivePadding = padding ?? EdgeInsets.all(size * 0.12);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : (borderRadius ?? BorderRadius.circular(size * 0.25)),
        border: border,
      ),
      padding: effectivePadding,
      child: Center(
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback ke default baby avatar jika aset gagal dimuat
            return Image.asset(
              'assets/images/default_baby_avatar.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                female ? Icons.face_3_rounded : Icons.face_rounded,
                size: size * 0.65,
                color: female
                    ? const Color(0xFFEC4899)
                    : const Color(0xFF2A85FF),
              ),
            );
          },
        ),
      ),
    );
  }
}
