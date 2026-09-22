import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/child_model.dart';
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
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

    try {
      final query = await _db
          .collection(_collection)
          .where('owner_id', isEqualTo: ownerId)
          .get();

      final loadedChildren = query.docs
          .map((doc) => ChildModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

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
    final childWithOwner = child.copyWith(ownerId: ownerId);

    try {
      final docRef = await _db
          .collection(_collection)
          .add(childWithOwner.toMap());
      final savedChild = childWithOwner.copyWith(id: docRef.id);

      final updatedList = List<ChildModel>.from(childrenNotifier.value)
        ..add(savedChild);
      childrenNotifier.value = updatedList;

      // Otomatis jadikan anak yang baru diinput ini sebagai yang aktif
      activeChildNotifier.value = savedChild;
    } catch (e) {
      debugPrint('[ChildService] addChild error: $e');
    }
  }

  /// Memperbarui data profil anak yang sudah ada (lokal + Firestore).
  Future<void> updateChild(ChildModel updatedChild) async {
    final current = childrenNotifier.value;
    final index = current.indexWhere((c) => c.id == updatedChild.id);
    if (index != -1) {
      final updatedList = List<ChildModel>.from(current);
      updatedList[index] = updatedChild;
      childrenNotifier.value = updatedList;

      if (activeChildNotifier.value?.id == updatedChild.id) {
        activeChildNotifier.value = updatedChild;
      }
    }

    try {
      await _db
          .collection(_collection)
          .doc(updatedChild.id)
          .update(updatedChild.toMap());
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

    try {
      await _db.collection(_collection).doc(id).delete();
    } catch (e) {
      debugPrint('[ChildService] deleteChild error: $e');
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
