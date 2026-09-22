/// Model data untuk Resep MPASI pada aplikasi PediaGrow.
///
/// Data bersumber dari PMIK/Superadmin yang disimpan via [ResepMpasiService].
/// Model ini digunakan pada sisi pengguna (daftar_resep_page, detail_resep_page)
/// maupun pada sisi PMIK/Superadmin untuk input & pengelolaan resep.
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

  /// Cek apakah gambar berupa URL network HTTP/HTTPS
  bool get isNetworkImage {
    final img = displayImage;
    if (img == null) return false;
    return img.startsWith('http://') || img.startsWith('https://');
  }

  /// Factory dari Map (Mendukung skema MySQL dan SQLite lokal)
  factory ResepMpasiModel.fromMap(Map<String, dynamic> map) {
    List<String> splitLines(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      final str = raw.toString().trim();
      return str.isEmpty
          ? []
          : str
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
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

  // ---------------------------------------------------------------------------
  // 7 RESEP DEFAULT KEMENKES RI (STANDAR DATA PMIK SUPERADMIN)
  // ---------------------------------------------------------------------------

  static const List<ResepMpasiModel> defaultKemenkesRecipes = [
    // 1. Resep 1 (6-8 bulan)
    ResepMpasiModel(
      id: 1,
      judul: 'Bubur Singkong Isi Ikan dan Ayam dengan Saus Jeruk',
      kategoriUsia: '6-8 bulan',
      tanggal: '26 Agustus 2026',
      assetImagePath: 'assets/images/resep_1.png',
      penulis: 'Pego',
      energiKkal: 191.0,
      lemakGr: 9.0,
      proteinGr: 10.5,
      porsi: 3,
      bahan: [
        '75 gr singkong putih, rebus dan haluskan',
        '15 gr (2 sdm datar) daging ikan kembung, cincang halus',
        '15 gr daging ayam, cincang halus',
        '250 ml air kaldu ayam',
        '5 gr (1 sdt) minyak kelapa untuk menumis',
        '20 gr (2 sdm) bayam segar, potong halus',
        '1 lembar daun salam',
        '1 batang serai, geprek',
        '1 siung bawang merah halus',
        '1 siung bawang putih halus',
      ],
      bahanPelapis: [],
      buah: [
        '100 gr (sekitar 3 buah kecil) jeruk manis segar, peras dan ambil sarinya',
      ],
      caraMembuat: [
        'Panaskan minyak kelapa, tumis bumbu halus bersama daun salam dan serai hingga harum.',
        'Masukkan daging ayam dan ikan kembung cincang, aduk hingga berubah warna.',
        'Tambahkan air kaldu ayam dan singkong putih yang telah dihaluskan, aduk hingga tercampur rata.',
        'Masukkan potongan daun bayam, masak hingga semua bahan matang dan empuk.',
        'Angkat, saring halus atau haluskan dengan blender hingga tekstur lumat lembut sesuai usia 6-8 bulan.',
        'Sebelum disajikan selagi hangat, siramkan saus sari jeruk manis segar di atas bubur.',
      ],
    ),

    // 2. Resep 2 (6-8 bulan)
    ResepMpasiModel(
      id: 2,
      judul: 'Bubur Soto Ayam Santan',
      kategoriUsia: '6-8 bulan',
      tanggal: '26 Agustus 2026',
      assetImagePath: 'assets/images/resep_2.png',
      penulis: 'Pego',
      energiKkal: 175.0,
      lemakGr: 7.5,
      proteinGr: 9.0,
      porsi: 2,
      bahan: [
        '60 gr (6 sdm) nasi putih',
        '45 gr (4,5 sdm) daging ayam cincang',
        '30 gr (1 buah kecil) tahu putih, potong dadu kecil',
        '30 gr (3 sdm) labu siam, potong kecil-kecil',
        '15 gr (1,5 sdm) wortel, potong kecil-kecil',
        '30 ml (3 sdm) santan encer',
        '300 ml air kaldu ayam',
        '5 gr (1 sdm) minyak goreng untuk menumis',
        '1 lembar daun salam & 1 batang sereh geprek',
        '1 lembar daun jeruk',
        '1 siung bawang merah & 1 siung bawang putih (halus)',
        '1 cm kunyit & 1 cm jahe (halus)',
      ],
      bahanPelapis: [],
      buah: [
        '50 gr buah pepaya manis matang, haluskan',
      ],
      caraMembuat: [
        'Panaskan minyak, tumis bumbu halus bersama daun salam, sereh, dan daun jeruk hingga harum.',
        'Masukkan daging ayam cincang, tumis hingga berubah warna menjadi matang.',
        'Tambahkan air kaldu ayam dan santan, aduk rata dan didihkan perlahan.',
        'Masukkan nasi putih, tahu, labu siam, dan wortel. Masak hingga seluruh bahan empuk dan kuah menyusut.',
        'Angkat dan haluskan bubur soto dengan saringan kawat atau blender sampai bertekstur lumat halus.',
        'Sajikan hangat bersama puree buah pepaya sebagai pelengkap gizi harian si kecil.',
      ],
    ),

    // 3. Resep 3 (6-8 bulan)
    ResepMpasiModel(
      id: 3,
      judul: 'Puding Kentang Ayam dan Telur',
      kategoriUsia: '6-8 bulan',
      tanggal: '26 Agustus 2026',
      assetImagePath: 'assets/images/resep_3.png',
      penulis: 'Pego',
      energiKkal: 160.0,
      lemakGr: 6.0,
      proteinGr: 8.5,
      porsi: 3,
      bahan: [
        '100 gr kentang, kukus dan haluskan',
        '30 gr (3 sdm) daging ayam cincang',
        '10 gr (1 butir) telur puyuh, kocok lepas',
        '15 gr tahu, potong dadu kecil',
        '15 gr (1,5 sdm) wortel parut halus',
        '10 gr (1 sdm) labu kuning, kukus dan lumatkan',
        '15 ml santan kental',
        '50 ml air kaldu ayam',
        '1 batang sereh & 1 lembar daun salam',
        '1 sdm minyak kelapa untuk menumis',
        '2 siung bawang merah & 2 siung bawang putih (halus)',
      ],
      bahanPelapis: [],
      buah: [
        '50 gr buah alpukat matang, kerok lumat',
      ],
      caraMembuat: [
        'Panaskan minyak kelapa, tumis bumbu halus bersama daun salam dan sereh hingga harum.',
        'Masukkan daging ayam cincang, aduk hingga berubah warna.',
        'Masukkan kentang halus, labu kuning lumat, tahu, dan wortel parut. Aduk rata.',
        'Tuangkan santan dan air kaldu ayam, aduk rata hingga menyatu, lalu matikan api.',
        'Campurkan kocokan telur puyuh ke dalam tumisan bahan, aduk rata perlahan.',
        'Tuang adonan ke dalam wadah tahan panas yang diolesi sedikit minyak/mentega.',
        'Kukus selama kurang lebih 20 menit hingga puding matang padat dan lembut.',
        'Sajikan selagi hangat bersama puree alpukat segar.',
      ],
    ),

    // 4. Resep 4 (9-11 bulan)
    ResepMpasiModel(
      id: 4,
      judul: 'Nasi Tim Ikan Tuna Telur Puyuh',
      kategoriUsia: '9-11 bulan',
      tanggal: '26 Agustus 2026',
      assetImagePath: 'assets/images/resep_4.png',
      penulis: 'Pego',
      energiKkal: 200.0,
      lemakGr: 8.0,
      proteinGr: 12.0,
      porsi: 2,
      bahan: [
        '115 gr (12 sdm) nasi putih matang',
        '30 gr (1 potong kecil) ikan tuna segar, haluskan',
        '30 gr (3 butir) telur puyuh, rebus dan cincang',
        '15 gr wortel segar, parut halus',
        '10 gr buah tomat merah, buang biji dan potong kecil',
        '7,5 gr (1,5 sdt) minyak kelapa',
        '100 ml air kaldu ayam atau ikan',
        '1 siung bawang putih & 1 siung bawang merah, cincang halus',
      ],
      bahanPelapis: [],
      buah: [
        '60 gr buah pepaya matang, potong dadu kecil',
      ],
      caraMembuat: [
        'Siapkan mangkuk tahan panas khusus tim makanan bayi.',
        'Masukkan nasi putih, ikan tuna cincang halus, telur puyuh rebus cincang, dan minyak kelapa ke dalam mangkuk.',
        'Tambahkan parutan wortel, potongan tomat, bawang cincang, dan air kaldu.',
        'Aduk hingga seluruh bahan tercampur secara merata.',
        'Kukus (tim) adonan dalam kukusan selama 25-30 menit hingga beras sangat lembut dan matang.',
        'Angkat nasi tim dengan tekstur cincang lembut, lalu sajikan bersama potongan pepaya segar.',
      ],
    ),

    // 5. Resep 5 (9-11 bulan) - MILESTONE UTAMA
    ResepMpasiModel(
      id: 5,
      judul: 'Mie Kukus Telur Puyuh',
      kategoriUsia: '9-11 bulan',
      tanggal: '26 Agustus 2026',
      assetImagePath: 'assets/images/resep_5.png',
      penulis: 'Pego',
      energiKkal: 185.0,
      lemakGr: 7.0,
      proteinGr: 10.0,
      porsi: 2,
      bahan: [
        '85 gr mie kering khusus balita atau mie telur, rebus lunak dan potong pendek',
        '60 gr (6 butir) telur puyuh, rebus matang dan kupas',
        '50 gr (5 sdm) wortel segar, parut halus',
        '50 gr (5 sdm) keju cheddar, parut halus',
        '10 gr (1 batang) daun bawang, iris halus',
        '1 butir telur ayam, kocok lepas untuk pengikat adonan',
        '1 siung bawang putih & 1 siung bawang merah, haluskan',
        '1 sdt minyak kelapa untuk mengoles wadah cetakan kukus',
      ],
      bahanPelapis: [],
      buah: [
        '60 gr buah melon manis, potong dadu kecil lembut',
      ],
      caraMembuat: [
        'Rebus mie dalam air mendidih hingga lunak matang, tiriskan lalu potong pendek agar mudah dikunyah bayi 9-11 bulan.',
        'Campurkan mie rebus dengan wortel parut, keju parut, daun bawang, bumbu halus, dan telur ayam kocok hingga rata.',
        'Siapkan wadah atau cetakan tahan panas, olesi permukaan dalamnya tipis-tipis dengan minyak kelapa.',
        'Masukkan 1-2 sendok makan adonan mie ke dalam cetakan, lalu letakkan 1 butir telur puyuh rebus di bagian tengahnya.',
        'Tutup kembali bagian atas telur dengan sedikit adonan mie hingga tertata rapi.',
        'Kukus adonan dalam panci kukusan selama 15-20 menit hingga matang padat dan keju menyatu gurih.',
        'Angkat dan biarkan hangat, potong seukuran genggaman jari (finger food) lalu sajikan bersama potongan buah melon manis.',
      ],
    ),

    // 6. Resep 6 (9-11 bulan)
    ResepMpasiModel(
      id: 6,
      judul: 'Tim Bubur Manado Daging dan Udang',
      kategoriUsia: '9-11 bulan',
      tanggal: '26 Agustus 2026',
      assetImagePath: 'assets/images/resep_6.png',
      penulis: 'Pego',
      energiKkal: 210.0,
      lemakGr: 9.5,
      proteinGr: 13.0,
      porsi: 3,
      bahan: [
        '50 gr (5 sdm) nasi putih',
        '40 gr (4 sdm) daging sapi giling atau cincang halus',
        '30 gr (3 ekor) udang segar, kupas dan cincang halus',
        '40 gr (4 sdm) labu kuning manis, potong dadu kecil',
        '20 gr (2 sdm) jagung manis pipil muda, cincang kasar',
        '10 gr (1 sdm) bayam segar, iris halus',
        '10 gr (1 batang) daun bawang, iris halus',
        '150 ml air kaldu daging atau kaldu udang',
        '5 ml (1 sdt) minyak kelapa untuk menumis',
        '1 siung bawang merah & 1 siung bawang putih, cincang halus',
      ],
      bahanPelapis: [],
      buah: [
        '50 gr buah naga merah manis, potong kecil',
      ],
      caraMembuat: [
        'Panaskan minyak kelapa, tumis bawang merah dan bawang putih cincang hingga harum.',
        'Masukkan daging sapi cincang dan udang cincang, aduk hingga berubah warna dan matang gurih.',
        'Tambahkan air kaldu daging, nasi putih, potongan labu kuning, dan jagung manis cincang.',
        'Masak dengan api sedang sambil diaduk perlahan hingga labu melunak dan bubur mengental.',
        'Tambahkan irisan bayam dan daun bawang beberapa menit sebelum diangkat, masak hingga sayur empuk.',
        'Angkat bubur tim dengan tekstur cincang halus-sedang, lalu sajikan hangat bersama potongan buah naga merah.',
      ],
    ),

    // 7. Resep 7 (12-23 bulan)
    ResepMpasiModel(
      id: 7,
      judul: 'Nasi Soto Ayam Kuah Kuning',
      kategoriUsia: '12-23 bulan',
      tanggal: '26 Agustus 2026',
      assetImagePath: 'assets/images/resep_7.png',
      penulis: 'Pego',
      energiKkal: 230.0,
      lemakGr: 10.0,
      proteinGr: 14.0,
      porsi: 3,
      bahan: [
        '150 gr (15 sdm) nasi putih pulen hangat',
        '100 gr daging ayam fillet tanpa kulit, potong dadu kecil',
        '60 gr (6 butir) telur puyuh rebus, kupas',
        '10 gr (1 sdm) soun lunak, rendam air hangat dan potong pendek',
        '30 gr (3 sdm) tauge pendek segar, cuci bersih',
        '1 batang daun bawang & seledri, iris halus',
        '1 sdm minyak kelapa untuk menumis',
        '400 ml air kaldu ayam asli',
        '1 lembar daun salam, 1 batang serai geprek, 1 lembar daun jeruk',
        '2 siung bawang merah & 2 siung bawang putih (halus)',
        '1 cm kunyit bakar, 1/2 cm jahe, dan sejumput ketumbar bubuk (halus)',
      ],
      bahanPelapis: [],
      buah: [
        '1 buah jeruk manis segar, kupas dan potong juring kecil bebas biji',
      ],
      caraMembuat: [
        'Panaskan minyak kelapa, tumis bumbu halus bersama daun salam, daun jeruk, dan serai hingga matang harum.',
        'Masukkan potongan daging ayam fillet, aduk merata hingga ayam berubah warna kaku.',
        'Tuangkan air kaldu ayam asli, masak dengan api sedang hingga kuah mendidih dan sari ayam meresap sempurna.',
        'Masukkan tauge pendek, irisan daun bawang, dan seledri, masak sebentar selama 1 menit lalu matikan api.',
        'Di dalam mangkuk makan anak, susun nasi hangat, potongan soun, dan butiran telur puyuh rebus.',
        'Siramkan kuah soto kuning gurih beserta potongan ayam di atas nasi hangat.',
        'Sajikan selagi hangat bersama potongan buah jeruk manis segar sebagai penutup gizi seimbang.',
      ],
    ),

    // 8. Resep 8 (24+ bulan)
    ResepMpasiModel(
      id: 8,
      judul: 'Bubur Kacang Hijau Santan Pandan',
      kategoriUsia: '24+ bulan',
      tanggal: '26 Agustus 2026',
      assetImagePath: 'assets/images/resep_8.png',
      penulis: 'Pego',
      energiKkal: 220.0,
      lemakGr: 8.5,
      proteinGr: 9.0,
      porsi: 4,
      bahan: [
        '100 gr kacang hijau kupas, rendam 2 jam hingga lunak',
        '400 ml santan encer dari 1/2 butir kelapa',
        '200 ml air bersih',
        '2 lembar daun pandan segar, simpulkan',
        '30 gr (3 sdm) gula merah sisir halus',
        '1 sdt gula pasir (opsional sesuai selera)',
        'Sejumput garam laut halus',
        '30 ml santan kental untuk taburan sajian',
      ],
      bahanPelapis: [],
      buah: [
        '1 buah pisang ambon matang, potong dadu kecil',
      ],
      caraMembuat: [
        'Cuci bersih kacang hijau yang telah direndam, tiriskan dari air rendaman.',
        'Rebus kacang hijau bersama 200 ml air dalam panci hingga kacang pecah mekar dan empuk (sekitar 20-25 menit).',
        'Masukkan santan encer, daun pandan, gula merah, dan garam ke dalam rebusan kacang hijau.',
        'Aduk perlahan dengan api sedang agar santan tidak pecah, masak hingga bubur mengental dan aroma pandan meresap.',
        'Koreksi rasa, tambahkan gula pasir jika diperlukan, lalu matikan api.',
        'Tuang bubur ke dalam mangkuk saji anak, siramkan santan kental tipis di atasnya.',
        'Sajikan hangat atau suhu ruang bersama potongan pisang ambon manis sebagai lauk buah.',
      ],
    ),

    // 9. Resep 9 (6-8 bulan)
    ResepMpasiModel(
      id: 9,
      judul: 'Bubur Labu Kuning Ikan Salmon',
      kategoriUsia: '6-8 bulan',
      tanggal: '26 Agustus 2026',
      assetImagePath: 'assets/images/resep_9.png',
      penulis: 'Pego',
      energiKkal: 168.0,
      lemakGr: 7.5,
      proteinGr: 10.0,
      porsi: 2,
      bahan: [
        '80 gr labu kuning manis (butternut squash), potong dadu dan kukus lunak',
        '40 gr fillet ikan salmon segar tanpa duri, kukus hingga matang',
        '50 gr (5 sdm) tepung beras atau nasi pulen yang sudah ditim lunak',
        '150 ml ASI/susu formula cair atau air kaldu sayuran',
        '5 ml minyak zaitun atau minyak kelapa murni (EVCO)',
        '1/2 siung bawang putih kecil, haluskan (opsional, untuk 7 bulan ke atas)',
      ],
      bahanPelapis: [],
      buah: [
        '50 gr buah mangga harum manis matang, haluskan menjadi puree lembut',
      ],
      caraMembuat: [
        'Kukus potongan labu kuning selama 15 menit hingga sangat lunak dan mudah dihancurkan.',
        'Kukus fillet ikan salmon secara terpisah selama 8-10 menit hingga matang sempurna dan serpih.',
        'Haluskan labu kuning kukus dengan garpu atau blender hingga menjadi puree halus bebas gumpalan.',
        'Suwir ikan salmon kukus, periksa tidak ada sisa duri, lalu haluskan bersama labu kuning.',
        'Campurkan nasi tim atau tepung beras, tuangkan ASI/susu formula secara bertahap sambil diaduk.',
        'Masak di atas api kecil selama 3-5 menit sambil terus diaduk hingga bubur mengental rata.',
        'Tambahkan minyak zaitun untuk menambah kalori sehat, aduk rata, lalu haluskan kembali dengan saringan.',
        'Sajikan hangat bersama puree mangga harum segar di sisi mangkuk.',
      ],
    ),

    // 10. Resep 10 (12-23 bulan)
    ResepMpasiModel(
      id: 10,
      judul: 'Perkedel Tahu Tempe Wortel',
      kategoriUsia: '12-23 bulan',
      tanggal: '26 Agustus 2026',
      assetImagePath: 'assets/images/resep_10.png',
      penulis: 'Pego',
      energiKkal: 195.0,
      lemakGr: 9.0,
      proteinGr: 12.5,
      porsi: 3,
      bahan: [
        '100 gr tahu putih padat, haluskan',
        '75 gr tempe segar, kukus dan haluskan',
        '50 gr wortel segar, parut halus',
        '30 gr (3 sdm) tepung terigu serbaguna',
        '1 butir telur ayam ukuran sedang, kocok lepas',
        '15 gr daun seledri dan daun bawang, cincang halus',
        '2 siung bawang merah & 2 siung bawang putih, haluskan',
        '1/2 sdt ketumbar bubuk',
        'Sejumput garam dan lada putih halus',
        '3 sdm minyak kelapa untuk menggoreng atau memanggang',
      ],
      bahanPelapis: [],
      buah: [
        '1 buah tomat merah segar matang, potong kecil dan sajikan segar',
      ],
      caraMembuat: [
        'Campurkan tahu halus, tempe kukus halus, dan wortel parut ke dalam satu wadah besar.',
        'Masukkan tepung terigu, kocokan telur, seledri, daun bawang, dan bumbu halus. Aduk merata hingga adonan bisa dibentuk.',
        'Tambahkan ketumbar bubuk, garam, dan lada putih secukupnya sesuai selera anak.',
        'Ambil adonan satu sendok makan, bentuk bulat pipih atau oval seukuran genggaman anak.',
        'Panaskan minyak kelapa dalam wajan anti lengket dengan api sedang kecil.',
        'Goreng perkedel hingga kedua sisi berwarna kuning kecoklatan matang (sekitar 3-4 menit per sisi) atau panggang di oven 180°C selama 15 menit.',
        'Angkat, tiriskan di atas tisu dapur agar tidak terlalu berminyak.',
        'Sajikan hangat bersama potongan tomat segar sebagai pelengkap vitamin C alami.',
      ],
    ),
  ];
}
