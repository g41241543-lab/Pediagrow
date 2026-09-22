/// Model data untuk satu soal kuis dari bank soal JSON.
///
/// Field JSON yang digunakan:
/// - `id`: identifikasi unik soal
/// - `kategori`: topik soal (Nutrisi, Imunisasi, Stunting, dst.)
/// - `pertanyaan`: teks soal yang ditampilkan
/// - `jawaban_benar`: true jika jawaban benar = "Benar", false jika = "Salah"
/// - `penjelasan`: teks penjelasan yang ditampilkan pada halaman Feedback
class SoalModel {
  final int id;
  final String kategori;
  final String pertanyaan;
  final bool jawabanBenar;
  final String penjelasan;

  const SoalModel({
    required this.id,
    required this.kategori,
    required this.pertanyaan,
    required this.jawabanBenar,
    required this.penjelasan,
  });

  factory SoalModel.fromJson(Map<String, dynamic> json) {
    return SoalModel(
      id: json['id'] as int,
      kategori: json['kategori'] as String,
      pertanyaan: json['pertanyaan'] as String,
      jawabanBenar: json['jawaban_benar'] as bool,
      penjelasan: json['penjelasan'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kategori': kategori,
        'pertanyaan': pertanyaan,
        'jawaban_benar': jawabanBenar,
        'penjelasan': penjelasan,
      };

  @override
  String toString() =>
      'SoalModel(id: $id, kategori: $kategori, jawabanBenar: $jawabanBenar)';
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
