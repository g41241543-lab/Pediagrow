import 'dart:convert';

/// Model representasi data Artikel Kesehatan pada aplikasi PediaGrow.
///
/// Model ini dirancang fleksibel untuk:
/// - Pengambilan data dari database lokal (SQLite) maupun remote REST API / PMIK backend.
/// - Manajemen konten oleh role PMIK (Admin & Superadmin).
/// - Penampilan data dinamis pada halaman daftar dan halaman detail artikel pengguna.
class ArtikelModel {
  final int? id;
  final String judul;
  final String kategori; // Default: 'Artikel'
  final List<String> subKategori; // contoh: ['Apa itu Stunting?'] atau ['Stunting', 'Wasting']
  final String tanggal; // Format tampilan: '26 Agustus 2026'
  final String? assetImagePath; // Path aset lokal
  final String? imageUrl; // URL remote jika diupload oleh PMIK
  final String penulis; // Profil PMIK/Admin, contoh: 'Pego'
  final String? deskripsi;
  final String? pengertian;
  final String isiLengkap; // Teks lengkap atau konten dinamis tambahan

  const ArtikelModel({
    this.id,
    required this.judul,
    this.kategori = 'Artikel',
    this.subKategori = const [],
    required this.tanggal,
    this.assetImagePath,
    this.imageUrl,
    this.penulis = 'Pego',
    this.deskripsi,
    this.pengertian,
    this.isiLengkap = '',
  });

  /// Mengembalikan gambar yang akan ditampilkan.
  /// Memprioritaskan gambar aset lokal, lalu URL remote.
  String? get displayImage =>
      (assetImagePath != null && assetImagePath!.isNotEmpty)
          ? assetImagePath
          : ((imageUrl != null && imageUrl!.isNotEmpty) ? imageUrl : null);

  /// Apakah gambar merupakan aset lokal
  bool get isAssetImage =>
      assetImagePath != null &&
      assetImagePath!.isNotEmpty &&
      assetImagePath!.startsWith('assets/');

  /// Konversi dari Map SQLite / Database lokal
  factory ArtikelModel.fromMap(Map<String, dynamic> map) {
    List<String> parseSubKategori(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          return raw.split(',').map((e) => e.trim()).toList();
        }
      }
      return [];
    }

    final image = (map['image_url'] ?? map['gambar_url'] ?? map['asset_image_path']) as String?;
    final dateStr = (map['tanggal'] ?? map['dibuat_pada'])?.toString() ?? '';
    final summary = (map['deskripsi'] ?? map['ringkasan'] ?? map['pengertian']) as String?;
    final fullContent = (map['isi_lengkap'] ?? map['isi'] ?? summary) as String? ?? '';

    return ArtikelModel(
      id: (map['id'] as num?)?.toInt(),
      judul: (map['judul'] as String?) ?? '',
      kategori: (map['kategori'] as String?) ?? 'Artikel',
      subKategori: parseSubKategori(map['sub_kategori']),
      tanggal: dateStr,
      assetImagePath: map['asset_image_path'] as String?,
      imageUrl: image,
      penulis: (map['penulis'] as String?) ?? 'Pego',
      deskripsi: summary,
      pengertian: (map['pengertian'] as String?) ?? summary,
      isiLengkap: fullContent,
    );
  }


  /// Konversi ke Map SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'judul': judul,
      'kategori': kategori,
      'sub_kategori': jsonEncode(subKategori),
      'tanggal': tanggal,
      'asset_image_path': assetImagePath,
      'image_url': imageUrl,
      'penulis': penulis,
      'deskripsi': deskripsi,
      'pengertian': pengertian,
      'isi_lengkap': isiLengkap,
    };
  }

  /// Konversi dari JSON (REST API / Firebase)
  factory ArtikelModel.fromJson(Map<String, dynamic> json) =>
      ArtikelModel.fromMap(json);

  /// Konversi ke JSON
  Map<String, dynamic> toJson() => toMap();

  ArtikelModel copyWith({
    int? id,
    String? judul,
    String? kategori,
    List<String>? subKategori,
    String? tanggal,
    String? assetImagePath,
    String? imageUrl,
    String? penulis,
    String? deskripsi,
    String? pengertian,
    String? isiLengkap,
  }) {
    return ArtikelModel(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      kategori: kategori ?? this.kategori,
      subKategori: subKategori ?? this.subKategori,
      tanggal: tanggal ?? this.tanggal,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      penulis: penulis ?? this.penulis,
      deskripsi: deskripsi ?? this.deskripsi,
      pengertian: pengertian ?? this.pengertian,
      isiLengkap: isiLengkap ?? this.isiLengkap,
    );
  }

  /// Data awal/seed default sesuai acuan desain referensi PediaGrow
  static const List<ArtikelModel> seedArticles = [
    ArtikelModel(
      id: 1,
      judul: 'Stunting',
      kategori: 'Artikel',
      subKategori: ['Apa itu Stunting?'],
      tanggal: '26 Agustus 2026',
      assetImagePath: 'assets/images/artikel_stunting.jpg',
      penulis: 'Pego',
      deskripsi:
          'Stunting merupakan suatu keadaan di mana tinggi badan anak lebih rendah dari rata-rata untuk usianya karena kekurangan nutrisi yang berlangsung dalam jangka waktu yang lama. Hal ini dapat disebabkan oleh kurangnya asupan gizi pada ibu selama kehamilan atau pada anak saat sedang dalam masa pertumbuhan.',
      pengertian:
          'Stunting adalah masalah kurang gizi kronis yang disebabkan oleh asupan gizi yang kurang dalam waktu cukup lama akibat pemberian makanan yang tidak sesuai dengan kebutuhan gizi. Stunting dapat terjadi mulai janin masih dalam kandungan dan baru nampak saat anak berusia dua tahun (Kementerian Kesehatan Republik Indonesia, 2016). Stunting dan kekurangan gizi lainnya yang terjadi pada 1.000 HPK tidak hanya menyebabkan hambatan pertumbuhan fisik dan meningkatkan kerentanan terhadap penyakit, tetapi juga mengancam perkembangan kognitif yang akan berpengaruh pada tingkat kecerdasan saat ini dan produktivitas anak di masa dewasanya.',
      isiLengkap: '',
    ),
    ArtikelModel(
      id: 2,
      judul:
          'Selain Stunting, Wasting Juga Salah Satu Bentuk Masalah Gizi Anak yang Perlu Diwaspadai',
      kategori: 'Artikel',
      subKategori: ['Stunting', 'Wasting'],
      tanggal: '26 Agustus 2026',
      assetImagePath: 'assets/images/artikel_wasting.jpg',
      penulis: 'Pego',
      deskripsi:
          'Wasting merupakan kondisi ketika berat badan anak menurun drastis hingga berada di bawah rentang normal untuk tinggi badannya. Kondisi ini menunjukkan adanya penurunan berat badan secara akut dan parah yang memerlukan penanganan segera.',
      pengertian:
          'Wasting (gizi kurang akut) sering kali dipicu oleh asupan makanan yang sangat kurang dalam periode singkat, penyakit infeksi seperti diare berat, atau kombinasi keduanya. Anak dengan wasting memiliki risiko morbiditas yang meningkat bila tidak segera ditangani secara medis dan pemenuhan nutrisi adekuat.',
      isiLengkap: '',
    ),
    ArtikelModel(
      id: 3,
      judul: 'Keluarga Bebas Stunting',
      kategori: 'Artikel',
      subKategori: ['Stunting'],
      tanggal: '26 Agustus 2026',
      assetImagePath: 'assets/images/artikel_keluarga_bebas_stunting.jpg',
      penulis: 'Pego',
      deskripsi:
          'Mewujudkan keluarga bebas stunting dimulai dari pemenuhan gizi seimbang sejak masa kehamilan hingga anak berusia dua tahun, serta didukung oleh sanitasi lingkungan yang higienis.',
      pengertian:
          'Program Keluarga Bebas Stunting berfokus pada intervensi gizi spesifik dan sensitif, termasuk pemantauan rutin tumbuh kembang balita di Posyandu/Fasyankes, edukasi MPASI bergizi, dan pola asuh keluarga yang responsif terhadap kesehatan anak.',
      isiLengkap: '',
    ),
  ];
}
