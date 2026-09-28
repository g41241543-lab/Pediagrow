/// Item hak akses dan permission untuk Dokter di PediaGrow.
class DoctorPermissionItem {
  final String key;
  final String label;
  final bool defaultValue;

  const DoctorPermissionItem({
    required this.key,
    required this.label,
    required this.defaultValue,
  });
}

/// Daftar 16 hak akses standar sesuai rancangan UI PediaGrow.
class DoctorPermissions {
  static const List<DoctorPermissionItem> allPermissions = [
    DoctorPermissionItem(
      key: 'rekapitulasi',
      label: 'Rekapitulasi',
      defaultValue: true,
    ),
    DoctorPermissionItem(
      key: 'download_dataset_rekapitulasi',
      label: 'Download Dataset Rekapitulasi',
      defaultValue: false,
    ),
    DoctorPermissionItem(
      key: 'data_pasien',
      label: 'Data Pasien',
      defaultValue: true,
    ),
    DoctorPermissionItem(
      key: 'detail_pasien',
      label: 'Detail Pasien',
      defaultValue: true,
    ),
    DoctorPermissionItem(
      key: 'edit_resume_medis',
      label: 'Edit Resume Medis',
      defaultValue: true,
    ),
    DoctorPermissionItem(
      key: 'ruang_obrolan',
      label: 'Ruang Obrolan',
      defaultValue: true,
    ),
    DoctorPermissionItem(
      key: 'daftar_resep_mpasi',
      label: 'Daftar Resep MPASI',
      defaultValue: false,
    ),
    DoctorPermissionItem(
      key: 'daftar_artikel_kesehatan',
      label: 'Daftar Artikel Kesehatan',
      defaultValue: false,
    ),
    DoctorPermissionItem(
      key: 'grafik_pengguna',
      label: 'Grafik Pengguna',
      defaultValue: true,
    ),
    DoctorPermissionItem(
      key: 'download_dataset_pengguna',
      label: 'Download Dataset Pengguna',
      defaultValue: false,
    ),
    DoctorPermissionItem(
      key: 'permainan',
      label: 'Permainan',
      defaultValue: false,
    ),
    DoctorPermissionItem(
      key: 'konsultasi',
      label: 'Konsultasi',
      defaultValue: true,
    ),
    DoctorPermissionItem(
      key: 'konfirmasi_konsultasi',
      label: 'Konfirmasi Konsultasi',
      defaultValue: true,
    ),
    DoctorPermissionItem(
      key: 'riwayat_konsultasi',
      label: 'Riwayat Konsultasi',
      defaultValue: true,
    ),
    DoctorPermissionItem(
      key: 'profil',
      label: 'Profil',
      defaultValue: true,
    ),
    DoctorPermissionItem(
      key: 'hak_akses',
      label: 'Hak Akses',
      defaultValue: false,
    ),
  ];

  /// Mengembalikan Map permission dengan nilai default
  static Map<String, bool> get defaultPermissions {
    return {
      for (final item in allPermissions) item.key: item.defaultValue,
    };
  }

  /// Memvalidasi atau melengkapi map permission yang ada
  static Map<String, bool> sanitize(Map<String, dynamic>? rawMap) {
    final Map<String, bool> result = {};
    for (final item in allPermissions) {
      if (rawMap != null && rawMap.containsKey(item.key)) {
        result[item.key] = rawMap[item.key] == true;
      } else {
        result[item.key] = item.defaultValue;
      }
    }
    return result;
  }
}
