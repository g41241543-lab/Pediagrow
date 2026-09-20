/// Model data untuk Resep MPASI pada aplikasi PediaGrow.
///
/// Data bersumber dari PMIK/Superadmin yang disimpan via [ResepMpasiService].
/// Model ini digunakan pada sisi pengguna (daftar_resep_page) maupun
/// pada sisi PMIK/Superadmin untuk input & pengelolaan resep.
class ResepMpasiModel {
  final int? id;
  final String judul;
  final String kategoriUsia; // '6-8 bulan' | '9-11 bulan' | '12-23 bulan'
  final String tanggal; // Format: 'dd MMMM yyyy', e.g. '26 Agustus 2026'
  final String? assetImagePath; // Lokal: 'assets/images/resep_x.png'
  final String? imageUrl; // Remote URL (untuk PMIK/Superadmin)
  final String? penulis;
  final double? energiKkal;
  final double? lemakGr;
  final double? proteinGr;
  final int? porsi;
  final List<String> bahan;
  final List<String> bahanPelapis;
  final List<String> buah;
  final List<String> caraMembuat;

  const ResepMpasiModel({
    this.id,
    required this.judul,
    required this.kategoriUsia,
    required this.tanggal,
    this.assetImagePath,
    this.imageUrl,
    this.penulis,
    this.energiKkal,
    this.lemakGr,
    this.proteinGr,
    this.porsi,
    this.bahan = const [],
    this.bahanPelapis = const [],
    this.buah = const [],
    this.caraMembuat = const [],
  });

  /// Gambar yang ditampilkan: prioritaskan assetImagePath, fallback imageUrl.
  String? get displayImage => assetImagePath ?? imageUrl;

  /// Factory dari Map (Mendukung skema MySQL dan SQLite lokal)
  factory ResepMpasiModel.fromMap(Map<String, dynamic> map) {
    List<String> splitLines(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      final str = raw.toString().trim();
      return str.isEmpty ? [] : str.split('\n').map((s) => s.trim()).toList();
    }

    String usia = (map['kategori_usia'] as String?) ?? '';
    if (usia.isEmpty && map['usia_min_bulan'] != null) {
      usia = '${map['usia_min_bulan']}-${map['usia_max_bulan']} Bulan';
    }
    if (usia.isEmpty) usia = 'Semua';

    final steps = splitLines(map['cara_membuat'] ?? map['langkah']);
    final ingredients = splitLines(map['bahan']);

    return ResepMpasiModel(
      id: (map['id'] as num?)?.toInt(),
      judul: (map['judul'] as String?) ?? '',
      kategoriUsia: usia,
      tanggal: (map['tanggal'] ?? map['dibuat_pada'])?.toString() ?? '',
      assetImagePath: map['asset_image_path'] as String?,
      imageUrl: (map['image_url'] ?? map['gambar_url'])?.toString(),
      penulis: (map['penulis'] as String?) ?? 'PediaGrow',
      energiKkal: (map['energi_kkal'] as num?)?.toDouble(),
      lemakGr: (map['lemak_gr'] as num?)?.toDouble(),
      proteinGr: (map['protein_gr'] as num?)?.toDouble(),
      porsi: (map['porsi'] as num?)?.toInt(),
      bahan: ingredients,
      bahanPelapis: splitLines(map['bahan_pelapis']),
      buah: splitLines(map['buah']),
      caraMembuat: steps,
    );
  }


  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'judul': judul,
      'kategori_usia': kategoriUsia,
      'tanggal': tanggal,
      'asset_image_path': assetImagePath,
      'image_url': imageUrl,
      'penulis': penulis,
      'energi_kkal': energiKkal,
      'lemak_gr': lemakGr,
      'protein_gr': proteinGr,
      'porsi': porsi,
      'bahan': bahan.join('\n'),
      'bahan_pelapis': bahanPelapis.join('\n'),
      'buah': buah.join('\n'),
      'cara_membuat': caraMembuat.join('\n'),
    };
  }

  ResepMpasiModel copyWith({
    int? id,
    String? judul,
    String? kategoriUsia,
    String? tanggal,
    String? assetImagePath,
    String? imageUrl,
    String? penulis,
    double? energiKkal,
    double? lemakGr,
    double? proteinGr,
    int? porsi,
    List<String>? bahan,
    List<String>? bahanPelapis,
    List<String>? buah,
    List<String>? caraMembuat,
  }) {
    return ResepMpasiModel(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      kategoriUsia: kategoriUsia ?? this.kategoriUsia,
      tanggal: tanggal ?? this.tanggal,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      penulis: penulis ?? this.penulis,
      energiKkal: energiKkal ?? this.energiKkal,
      lemakGr: lemakGr ?? this.lemakGr,
      proteinGr: proteinGr ?? this.proteinGr,
      porsi: porsi ?? this.porsi,
      bahan: bahan ?? this.bahan,
      bahanPelapis: bahanPelapis ?? this.bahanPelapis,
      buah: buah ?? this.buah,
      caraMembuat: caraMembuat ?? this.caraMembuat,
    );
  }
}
