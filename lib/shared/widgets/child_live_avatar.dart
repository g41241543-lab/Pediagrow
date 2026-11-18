import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/child_service.dart';
import '../../core/services/storage_service.dart';
import '../../models/child_model.dart';
import 'child_avatar.dart';

/// Widget Avatar Anak Real-Time yang otomatis terhubung ke Firebase Firestore.
///
/// Fitur:
/// - Mengambil foto profil anak terkini dari Firebase Firestore secara otomatis.
/// - Prioritas foto:
///   1. `photoUrl` langsung yang dioper
///   2. Real-time dari [ChildService.childrenNotifier]
///   3. Query Firestore ke collection `children` (by `childId` atau `childName`)
/// - Mendukung URL Cloud Storage, Base64 Data URI, file lokal, maupun asset.
/// - Caching pintar dalam memori agar tidak membebani kuota Firestore.
/// - Fallback estetik ke [ChildAvatar] kartun resmi PediaGrow (sesuai gender).
class ChildLiveAvatar extends StatefulWidget {
  final String? childId;
  final String? childName;
  final String? photoUrl;
  final String? gender;
  final bool? isGirl;
  final double size;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final Border? border;

  const ChildLiveAvatar({
    super.key,
    this.childId,
    this.childName,
    this.photoUrl,
    this.gender,
    this.isGirl,
    this.size = 44.0,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.border,
  });

  /// Cache memori foto anak (Key: childId atau lowerName -> Value: photoUrl)
  static final Map<String, String> _photoCache = {};
  static final Set<String> _inFlightFetches = {};

  @override
  State<ChildLiveAvatar> createState() => _ChildLiveAvatarState();
}

class _ChildLiveAvatarState extends State<ChildLiveAvatar> {
  String? _fetchedPhotoUrl;

  @override
  void initState() {
    super.initState();
    _resolvePhoto();
  }

  @override
  void didUpdateWidget(covariant ChildLiveAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.photoUrl != oldWidget.photoUrl ||
        widget.childId != oldWidget.childId ||
        widget.childName != oldWidget.childName) {
      _resolvePhoto();
    }
  }

  void _resolvePhoto() {
    // 1. Jika photoUrl langsung sudah valid, tidak perlu fetch
    if (widget.photoUrl != null && widget.photoUrl!.trim().isNotEmpty) {
      return;
    }

    // 2. Cek cache memori
    final cacheKey = _getCacheKey();
    if (cacheKey != null && ChildLiveAvatar._photoCache.containsKey(cacheKey)) {
      _fetchedPhotoUrl = ChildLiveAvatar._photoCache[cacheKey];
      return;
    }

    // 3. Fetch asinkron dari Firestore
    _fetchFromFirestore();
  }

  String? _getCacheKey() {
    if (widget.childId != null && widget.childId!.trim().isNotEmpty) {
      return 'id:${widget.childId!.trim()}';
    }
    if (widget.childName != null && widget.childName!.trim().isNotEmpty) {
      return 'name:${widget.childName!.trim().toLowerCase()}';
    }
    return null;
  }

  Future<void> _fetchFromFirestore() async {
    final cacheKey = _getCacheKey();
    if (cacheKey == null) return;
    if (ChildLiveAvatar._inFlightFetches.contains(cacheKey)) return;

    ChildLiveAvatar._inFlightFetches.add(cacheKey);

    try {
      final db = FirebaseFirestore.instance;
      String? resolved;

      // A. Coba cari by childId
      if (widget.childId != null && widget.childId!.trim().isNotEmpty) {
        final doc = await db.collection('children').doc(widget.childId!.trim()).get();
        if (doc.exists && doc.data() != null) {
          resolved = _extractPhoto(doc.data()!);
        }
      }

      // B. Coba cari by childName jika belum ketemu
      if ((resolved == null || resolved.isEmpty) &&
          widget.childName != null &&
          widget.childName!.trim().isNotEmpty) {
        final query = await db
            .collection('children')
            .where('name', isEqualTo: widget.childName!.trim())
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          resolved = _extractPhoto(query.docs.first.data());
        }
      }

      if (resolved != null && resolved.isNotEmpty) {
        ChildLiveAvatar._photoCache[cacheKey] = resolved;
        if (widget.childId != null && widget.childId!.trim().isNotEmpty) {
          ChildLiveAvatar._photoCache['id:${widget.childId!.trim()}'] = resolved;
        }
        if (widget.childName != null && widget.childName!.trim().isNotEmpty) {
          ChildLiveAvatar._photoCache['name:${widget.childName!.trim().toLowerCase()}'] = resolved;
        }

        if (mounted) {
          setState(() {
            _fetchedPhotoUrl = resolved;
          });
        }
      }
    } catch (_) {
      // Abaikan error fetch background
    } finally {
      ChildLiveAvatar._inFlightFetches.remove(cacheKey);
    }
  }

  static String? _extractPhoto(Map<String, dynamic> data) {
    final raw = data['photo_url'] ??
        data['photoUrl'] ??
        data['avatar'] ??
        data['avatarPath'] ??
        data['foto'] ??
        data['foto_url'];
    if (raw != null && raw.toString().trim().isNotEmpty) {
      return raw.toString().trim();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ChildModel>>(
      valueListenable: ChildService().childrenNotifier,
      builder: (context, children, _) {
        // Cari dari notifier lokal jika ada
        ChildModel? matchedChild;
        if (widget.childId != null && widget.childId!.trim().isNotEmpty) {
          matchedChild = children
              .where((c) => c.id == widget.childId!.trim())
              .firstOrNull;
        }
        if (matchedChild == null &&
            widget.childName != null &&
            widget.childName!.trim().isNotEmpty) {
          final target = widget.childName!.trim().toLowerCase();
          matchedChild = children
              .where((c) => c.name.trim().toLowerCase() == target)
              .firstOrNull;
        }

        final livePhoto = (widget.photoUrl != null &&
                widget.photoUrl!.trim().isNotEmpty)
            ? widget.photoUrl!.trim()
            : (_fetchedPhotoUrl != null && _fetchedPhotoUrl!.trim().isNotEmpty)
                ? _fetchedPhotoUrl!.trim()
                : (matchedChild?.photoUrl != null &&
                        matchedChild!.photoUrl!.trim().isNotEmpty)
                    ? matchedChild.photoUrl!.trim()
                    : null;

        final effectiveGender =
            matchedChild?.gender ?? widget.gender ?? 'Laki-laki';
        final isFemale = ChildAvatar.isFemaleGender(
          gender: effectiveGender,
          isGirl: widget.isGirl,
        );

        final fallback = ChildAvatar(
          gender: effectiveGender,
          isGirl: isFemale,
          size: widget.size,
          shape: widget.shape,
          borderRadius: widget.borderRadius,
          border: widget.border,
        );

        if (livePhoto != null && livePhoto.isNotEmpty) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: widget.shape,
              borderRadius: widget.shape == BoxShape.circle
                  ? null
                  : (widget.borderRadius ?? BorderRadius.circular(widget.size * 0.25)),
              border: widget.border,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: StorageService.buildImageWidget(
              livePhoto,
              fit: BoxFit.cover,
              width: widget.size,
              height: widget.size,
              placeholder: fallback,
              errorWidget: fallback,
            ),
          );
        }

        return fallback;
      },
    );
  }
}
