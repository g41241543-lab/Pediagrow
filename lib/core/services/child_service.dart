import 'package:flutter/foundation.dart';

import '../../models/child_model.dart';
import 'api_service.dart';

/// Service singleton untuk mengelola data profil anak-anak pada aplikasi PediaGrow.
///
/// Menggunakan [ValueNotifier] agar penambahan, pembaruan, atau penghapusan anak
/// dapat didengar secara reaktif oleh widget UI (Beranda, Cek Stunting, Grafik, Konsultasi)
/// secara real-time tanpa memerlukan refresh manual.
class ChildService {
  static final ChildService _instance = ChildService._internal();
  factory ChildService() => _instance;
  ChildService._internal();

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

  /// Menambahkan profil anak baru
  void addChild(ChildModel child) {
    final updatedList = List<ChildModel>.from(childrenNotifier.value)
      ..add(child);
    childrenNotifier.value = updatedList;

    // Otomatis jadikan anak yang baru diinput ini sebagai yang aktif
    activeChildNotifier.value = child;
  }

  /// Memperbarui data profil anak yang sudah ada
  void updateChild(ChildModel updatedChild) {
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
  }

  /// Menghapus profil anak berdasarkan [id]
  void deleteChild(String id) {
    final updatedList = List<ChildModel>.from(childrenNotifier.value)
      ..removeWhere((c) => c.id == id);
    childrenNotifier.value = updatedList;

    if (activeChildNotifier.value?.id == id) {
      activeChildNotifier.value = updatedList.isNotEmpty
          ? updatedList.first
          : null;
    }
  }

  /// Mengganti anak yang sedang aktif dipilih
  void setActiveChild(ChildModel child) {
    activeChildNotifier.value = child;
  }

  /// Mengambil daftar profil anak dari database MySQL via API,
  /// lalu memperbarui [childrenNotifier] secara reaktif.
  Future<void> loadChildrenFromApi(int idOrangTua) async {
    try {
      final rawList = await ApiService.getChildren(idOrangTua);
      final loadedChildren = rawList
          .map((map) => ChildModel.fromMap(map))
          .toList();

      childrenNotifier.value = loadedChildren;

      // Pertahankan anak aktif jika masih ada di daftar baru,
      // kalau tidak, pilih anak pertama sebagai default.
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
      debugPrint('ChildService.loadChildrenFromApi error: $e');
    }
  }

  /// Mengatur ulang daftar anak (misal saat logout atau inisialisasi)
  void clear() {
    childrenNotifier.value = [];
    activeChildNotifier.value = null;
  }
}
