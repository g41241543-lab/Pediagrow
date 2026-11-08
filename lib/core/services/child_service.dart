import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/child_model.dart';
import 'storage_service.dart';
import 'user_service.dart';

/// Service singleton untuk mengelola data profil anak-anak pada aplikasi PediaGrow.
///
/// Menggunakan [ValueNotifier] agar penambahan, pembaruan, atau penghapusan anak
/// dapat didengar secara reaktif oleh widget UI (Beranda, Cek Stunting, Grafik, Konsultasi)
/// secara real-time. Data disimpan permanen di Firestore, collection 'children',
/// dan selalu dibatasi (scoped) hanya untuk pengguna yang sedang login.
class ChildService {
  static final ChildService _instance = ChildService._internal();
  factory ChildService() => _instance;
  ChildService._internal();

  static const String _collection = 'children';

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// State daftar profil anak yang terdaftar
  final ValueNotifier<List<ChildModel>> childrenNotifier =
      ValueNotifier<List<ChildModel>>([]);

  /// State profil anak yang sedang aktif dipilih
  final ValueNotifier<ChildModel?> activeChildNotifier =
      ValueNotifier<ChildModel?>(null);

  /// Mengambil semua daftar anak saat ini
  List<ChildModel> get children => childrenNotifier.value;

  /// Mengetahui apakah pengguna sudah memiliki minimal 1 profil anak
  bool get hasChildren => childrenNotifier.value.isNotEmpty;

  /// Mengambil profil anak yang sedang aktif dipilih
  ChildModel? get activeChild {
    if (activeChildNotifier.value != null) {
      return activeChildNotifier.value;
    }
    if (childrenNotifier.value.isNotEmpty) {
      return childrenNotifier.value.first;
    }
    return null;
  }

  /// Memuat semua profil anak milik pengguna yang SEDANG LOGIN dari Firestore.
  /// WAJIB dipanggil setelah login berhasil (email/password ATAU Google),
  /// supaya daftar anak yang ditampilkan sesuai pemiliknya masing-masing.
  Future<void> loadChildrenForCurrentUser() async {
    final ownerId = UserService().currentUser.id;
    if (ownerId.isEmpty) {
      // Belum ada pengguna login (masih tamu) -> kosongkan daftar
      childrenNotifier.value = [];
      activeChildNotifier.value = null;
      return;
    }

    final db = _db;
    if (db == null) return;

    try {
      final Map<String, ChildModel> childMap = {};

      final query = await db
          .collection(_collection)
          .where('owner_id', isEqualTo: ownerId)
          .get();

      for (final doc in query.docs) {
        childMap[doc.id] = ChildModel.fromMap({...doc.data(), 'id': doc.id});
      }

      // Query berdasarkan parent_ids (jika terhubung sebagai orang tua pendamping)
      try {
        final queryParents = await db
            .collection(_collection)
            .where('parent_ids', arrayContains: ownerId)
            .get();
        for (final doc in queryParents.docs) {
          childMap[doc.id] = ChildModel.fromMap({...doc.data(), 'id': doc.id});
        }
      } catch (e) {
        debugPrint('[ChildService] parent_ids query warning: $e');
      }

      // Query berdasarkan no_kk
      final userNoKk = UserService().currentUser.noKk;
      if (userNoKk != null && userNoKk.trim().isNotEmpty) {
        try {
          final queryKk = await db
              .collection(_collection)
              .where('no_kk', isEqualTo: userNoKk.trim())
              .get();
          for (final doc in queryKk.docs) {
            childMap[doc.id] = ChildModel.fromMap({...doc.data(), 'id': doc.id});
          }
        } catch (e) {
          debugPrint('[ChildService] no_kk query warning: $e');
        }
      }

      final loadedChildren = childMap.values.toList();



      childrenNotifier.value = loadedChildren;

      if (loadedChildren.isNotEmpty) {
        final currentActiveId = activeChildNotifier.value?.id;
        final stillExists = loadedChildren.any((c) => c.id == currentActiveId);
        activeChildNotifier.value = stillExists
            ? activeChildNotifier.value
            : loadedChildren.first;
      } else {
        activeChildNotifier.value = null;
      }
    } catch (e) {
      debugPrint('[ChildService] loadChildrenForCurrentUser error: $e');
    }
  }

  /// Menambahkan profil anak baru. Otomatis memberi `ownerId` sesuai
  /// pengguna yang sedang login, dan menyimpannya ke Firestore.
  Future<void> addChild(ChildModel child) async {
    final ownerId = UserService().currentUser.id;
    final String? photoUrl = child.photoUrl != null && child.photoUrl!.isNotEmpty
        ? await StorageService.toPersistableString(child.photoUrl)
        : null;
    final String? birthPhotoUrl = child.birthPhotoUrl != null && child.birthPhotoUrl!.isNotEmpty
        ? await StorageService.toPersistableString(child.birthPhotoUrl)
        : null;

    final currentParents = List<String>.from(child.parentIds);
    if (ownerId.isNotEmpty && !currentParents.contains(ownerId)) {
      currentParents.add(ownerId);
    }

    final childWithOwner = child.copyWith(
      parentIds: currentParents,
      ownerId: ownerId,
      photoUrl: photoUrl,
      birthPhotoUrl: birthPhotoUrl,
    );

    final db = _db;
    if (db == null) return;

    try {
      final docRef = await db
          .collection(_collection)
          .add({
            ...childWithOwner.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
          });
      final savedChild = childWithOwner.copyWith(id: docRef.id);

      final updatedList = List<ChildModel>.from(childrenNotifier.value)
        ..add(savedChild);
      childrenNotifier.value = updatedList;

      // Otomatis jadikan anak yang baru diinput ini sebagai yang aktif
      activeChildNotifier.value = savedChild;

      // Sinkronisasi otomatis No KK ke profil akun orang tua jika belum terisi
      if (savedChild.noKk != null && savedChild.noKk!.trim().isNotEmpty) {
        final currentNoKk = UserService().currentUser.noKk;
        if (currentNoKk == null || currentNoKk.trim() != savedChild.noKk!.trim()) {
          await UserService().updateNoKk(savedChild.noKk!.trim());
        }
      }
    } catch (e) {
      debugPrint('[ChildService] addChild error: $e');
    }
  }

  /// Memperbarui data profil anak yang sudah ada (lokal + Firestore).
  Future<void> updateChild(ChildModel updatedChild) async {
    final String? photoUrl = updatedChild.photoUrl != null && updatedChild.photoUrl!.isNotEmpty
        ? await StorageService.toPersistableString(updatedChild.photoUrl)
        : null;
    final String? birthPhotoUrl = updatedChild.birthPhotoUrl != null && updatedChild.birthPhotoUrl!.isNotEmpty
        ? await StorageService.toPersistableString(updatedChild.birthPhotoUrl)
        : null;

    final childToSave = updatedChild.copyWith(
      photoUrl: photoUrl,
      birthPhotoUrl: birthPhotoUrl,
    );

    final current = childrenNotifier.value;
    final index = current.indexWhere((c) => c.id == childToSave.id);
    if (index != -1) {
      final updatedList = List<ChildModel>.from(current);
      updatedList[index] = childToSave;
      childrenNotifier.value = updatedList;

      if (activeChildNotifier.value?.id == childToSave.id) {
        activeChildNotifier.value = childToSave;
      }
    }

    final db = _db;
    if (db == null) return;

    try {
      await db
          .collection(_collection)
          .doc(childToSave.id)
          .update(childToSave.toMap());
    } catch (e) {
      debugPrint('[ChildService] updateChild error: $e');
    }
  }

  /// Menghapus profil anak berdasarkan [id] (lokal + Firestore).
  Future<void> deleteChild(String id) async {
    final updatedList = List<ChildModel>.from(childrenNotifier.value)
      ..removeWhere((c) => c.id == id);
    childrenNotifier.value = updatedList;

    if (activeChildNotifier.value?.id == id) {
      activeChildNotifier.value = updatedList.isNotEmpty
          ? updatedList.first
          : null;
    }

    final db = _db;
    if (db == null) return;

    try {
      await db.collection(_collection).doc(id).delete();
    } catch (e) {
      debugPrint('[ChildService] deleteChild error: $e');
    }
  }

  /// Mencari apakah ada profil anak dengan No KK dan NIK (atau Nama & Tanggal Lahir)
  /// yang sudah terdaftar di Firestore untuk mencegah duplikasi data pasien.
  Future<ChildModel?> findExistingChild({
    required String noKk,
    String? nik,
    String? name,
    DateTime? birthDate,
  }) async {
    final cleanKk = noKk.trim();
    if (cleanKk.isEmpty) return null;

    final db = _db;
    if (db == null) return null;

    try {
      final query = await db
          .collection(_collection)
          .where('no_kk', isEqualTo: cleanKk)
          .get();

      if (query.docs.isEmpty) return null;

      final cleanNik = nik?.trim() ?? '';
      final cleanName = name?.trim().toLowerCase() ?? '';

      for (final doc in query.docs) {
        final existing = ChildModel.fromMap({...doc.data(), 'id': doc.id});

        // 1. Prioritas utama: jika NIK terisi dan sama persis
        if (cleanNik.isNotEmpty &&
            existing.nik != null &&
            existing.nik!.trim().isNotEmpty) {
          if (existing.nik!.trim() == cleanNik) {
            return existing;
          }
        }

        // 2. Jika Nama dan Tanggal Lahir cocok
        if (cleanName.isNotEmpty &&
            existing.name.trim().toLowerCase() == cleanName) {
          if (birthDate != null && existing.birthDate != null) {
            if (existing.birthDate!.year == birthDate.year &&
                existing.birthDate!.month == birthDate.month &&
                existing.birthDate!.day == birthDate.day) {
              return existing;
            }
          } else {
            return existing;
          }
        }
      }
    } catch (e) {
      debugPrint('[ChildService] findExistingChild error: $e');
    }
    return null;
  }

  /// Menautkan profil anak yang sudah ada ke akun pengguna saat ini
  /// (misal: Ibu menghubungkan akunnya ke data anak yang didaftarkan Ayah).
  Future<void> linkChildToCurrentUser(ChildModel existingChild) async {
    final currentUserId = UserService().currentUser.id;
    if (currentUserId.isEmpty) return;

    final db = _db;
    if (db == null) return;

    try {
      final updatedParents = List<String>.from(existingChild.parentIds);
      if (!updatedParents.contains(currentUserId)) {
        updatedParents.add(currentUserId);
      }

      await db.collection(_collection).doc(existingChild.id).update({
        'parent_ids': updatedParents,
      });

      final updatedChild = existingChild.copyWith(parentIds: updatedParents);

      // Perbarui state lokal
      final currentList = List<ChildModel>.from(childrenNotifier.value);
      final idx = currentList.indexWhere((c) => c.id == updatedChild.id);
      if (idx == -1) {
        currentList.add(updatedChild);
      } else {
        currentList[idx] = updatedChild;
      }
      childrenNotifier.value = currentList;
      activeChildNotifier.value = updatedChild;

      // Sinkronkan No KK ke profil akun pengguna jika ada
      if (existingChild.noKk != null && existingChild.noKk!.trim().isNotEmpty) {
        final currentNoKk = UserService().currentUser.noKk;
        if (currentNoKk == null || currentNoKk.trim() != existingChild.noKk!.trim()) {
          await UserService().updateNoKk(existingChild.noKk!.trim());
        }
      }
    } catch (e) {
      debugPrint('[ChildService] linkChildToCurrentUser error: $e');
      rethrow;
    }
  }

  /// Mengganti anak yang sedang aktif dipilih
  void setActiveChild(ChildModel child) {
    activeChildNotifier.value = child;
  }

  /// Mengatur ulang daftar anak (dipanggil saat logout).
  void clear() {
    childrenNotifier.value = [];
    activeChildNotifier.value = null;
  }
}
