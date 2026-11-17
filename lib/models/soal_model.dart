/// Model data untuk satu soal kuis dari bank soal.
///
/// Field data yang digunakan:
/// - `id`: identifikasi unik soal (integer)
/// - `kategori`: topik soal (Stunting & Gizi, ASI & MPASI, Imunisasi & Kesehatan, Tumbuh Kembang, dst.)
/// - `pertanyaan`: teks pernyataan soal kuis
/// - `jawaban_benar`: true jika jawaban benar = "Benar", false jika = "Salah"
/// - `penjelasan`: pembahasan edukasi dan rujukan resmi
/// - `is_active`: status keaktifan soal (apakah bisa muncul di kuis User)
/// - `perlu_tinjauan`: penanda agar admin/PMIK meninjau ulang isi materi
/// - `created_at`: waktu pembuatan data
/// - `updated_at`: waktu pembaruan data
class SoalModel {
  final int id;
  final String kategori;
  final String pertanyaan;
  final bool jawabanBenar;
  final String penjelasan;
  final bool isActive;
  final bool perluTinjauan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SoalModel({
    required this.id,
    required this.kategori,
    required this.pertanyaan,
    required this.jawabanBenar,
    required this.penjelasan,
    this.isActive = true,
    this.perluTinjauan = false,
    this.createdAt,
    this.updatedAt,
  });

  SoalModel copyWith({
    int? id,
    String? kategori,
    String? pertanyaan,
    bool? jawabanBenar,
    String? penjelasan,
    bool? isActive,
    bool? perluTinjauan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SoalModel(
      id: id ?? this.id,
      kategori: kategori ?? this.kategori,
      pertanyaan: pertanyaan ?? this.pertanyaan,
      jawabanBenar: jawabanBenar ?? this.jawabanBenar,
      penjelasan: penjelasan ?? this.penjelasan,
      isActive: isActive ?? this.isActive,
      perluTinjauan: perluTinjauan ?? this.perluTinjauan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SoalModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      // Untuk Firestore Timestamp
      try {
        final dynamic dynVal = val;
        if (dynVal.toDate is Function) {
          return dynVal.toDate() as DateTime;
        }
      } catch (_) {}
      return null;
    }

    return SoalModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kategori: (json['kategori'] as String?)?.trim() ?? 'Umum',
      pertanyaan: (json['pertanyaan'] as String?)?.trim() ?? '',
      jawabanBenar: json['jawaban_benar'] == true ||
          json['jawaban_benar'] == 1 ||
          json['jawaban_benar'] == '1',
      penjelasan: (json['penjelasan'] as String?)?.trim() ?? '',
      isActive: json['is_active'] == null ||
          json['is_active'] == true ||
          json['is_active'] == 1,
      perluTinjauan: json['perlu_tinjauan'] == true ||
          json['perlu_tinjauan'] == 1,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kategori': kategori,
        'pertanyaan': pertanyaan,
        'jawaban_benar': jawabanBenar,
        'penjelasan': penjelasan,
        'is_active': isActive,
        'perlu_tinjauan': perluTinjauan,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'kategori': kategori,
        'pertanyaan': pertanyaan,
        'jawaban_benar': jawabanBenar,
        'penjelasan': penjelasan,
        'is_active': isActive,
        'perlu_tinjauan': perluTinjauan,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  @override
  String toString() =>
      'SoalModel(id: $id, kategori: $kategori, jawabanBenar: $jawabanBenar, isActive: $isActive)';
}

/// Model untuk menyimpan hasil jawaban satu soal dalam satu putaran kuis.
class HasilSoal {
  final SoalModel soal;

  /// null jika soal di-skip (timer habis).
  /// true jika jawaban pengguna = "Benar", false jika = "Salah".
  final bool? pilihanPengguna;

  const HasilSoal({
    required this.soal,
    required this.pilihanPengguna,
  });

  /// true jika soal di-skip karena waktu habis
  bool get diSkip => pilihanPengguna == null;

  /// true jika jawaban pengguna sesuai dengan jawabanBenar soal
  bool get benar =>
      !diSkip && pilihanPengguna == soal.jawabanBenar;
}
