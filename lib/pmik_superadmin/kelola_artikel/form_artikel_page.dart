import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/artikel_service.dart';
import '../../../models/artikel_model.dart';
import '../../../shared/widgets/article_rich_text_editor.dart';
import '../../../shared/widgets/pedia_banner.dart';

/// Halaman Form Artikel PMIK Superadmin untuk mode "Tambah Artikel" dan "Ubah Artikel".
///
/// Satu file [FormArtikelPage] menangani dua kondisi:
/// - Mode **Tambah Artikel**: ketika [artikel] bernilai `null`. Seluruh form dimulai
///   dalam keadaan bersih/kosong, judul header "Tambah Artikel", dan menargetkan
///   operasi create/tambah artikel baru ke [ArtikelService].
/// - Mode **Ubah/Edit Artikel**: ketika [artikel] berisi objek [ArtikelModel]. Form
///   otomatis terisi dengan data artikel yang dipilih (foto, judul, nama penulis, tanggal,
///   dan seluruh isi artikel lengkap), judul header "Ubah Artikel", dan menargetkan operasi
///   update terhadap ID dokumen artikel tersebut tanpa membuat artikel baru.
class FormArtikelPage extends StatefulWidget {
  final ArtikelModel? artikel;

  const FormArtikelPage({super.key, this.artikel});

  /// Mengindikasikan apakah form sedang dalam mode Ubah/Edit Artikel
  bool get isEditMode => artikel != null;

  @override
  State<FormArtikelPage> createState() => _FormArtikelPageState();
}

class _FormArtikelPageState extends State<FormArtikelPage> {
  final _formKey = GlobalKey<FormState>();
  final ArtikelService _artikelService = ArtikelService();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _judulController;
  late final TextEditingController _penulisController;
  late final RichTextEditingController _isiController;

  final FocusNode _judulFocusNode = FocusNode();
  final FocusNode _penulisFocusNode = FocusNode();
  final FocusNode _isiFocusNode = FocusNode();

  String? _imagePath;
  bool _isSaving = false;
  String? _judulError;
  String? _isiError;

  // Konstanta warna sesuai standar desain PediaGrow
  static const Color _colorDarkGray = Color(0xFF7F7F7F);
  static const Color _colorLightGray = Color(0xFFC5C5C5);
  static const Color _colorPrimaryBlue = Color(0xFF3985E7);

  @override
  void initState() {
    super.initState();
    final item = widget.artikel;

    // Inisialisasi controller berdasarkan mode
    _judulController = TextEditingController(text: item?.judul ?? '');
    _penulisController = TextEditingController(text: item?.penulis ?? 'Pego');

    if (item != null) {
      // MODE UBAH: Isi otomatis foto dan seluruh konten artikel yang tersimpan
      _imagePath = item.displayImage;
      _isiController = RichTextEditingController(text: _buildInitialContent(item));
    } else {
      // MODE TAMBAH: Form bersih/kosong
      _imagePath = null;
      _isiController = RichTextEditingController();
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _penulisController.dispose();
    _isiController.dispose();
    _judulFocusNode.dispose();
    _penulisFocusNode.dispose();
    _isiFocusNode.dispose();
    super.dispose();
  }

  /// Menyusun konten teks awal untuk mode Ubah Artikel
  String _buildInitialContent(ArtikelModel item) {
    if (item.isiLengkap.isNotEmpty) {
      return item.isiLengkap;
    }

    // Jika artikel 1 ("Stunting"), sertakan teks lengkap sesuai referensi desain
    if (item.judul.toLowerCase() == 'stunting' || item.id == 'artikel_1') {
      return '''Deskripsi
Stunting merupakan suatu keadaan di mana tinggi badan anak lebih rendah dari rata-rata untuk usianya karena kekurangan nutrisi yang berlangsung dalam jangka waktu yang lama. Hal ini dapat disebabkan oleh kurangnya asupan gizi pada ibu selama kehamilan atau pada anak saat sedang dalam masa pertumbuhan.

Pengertian
Stunting adalah masalah kurang gizi kronis yang disebabkan oleh asupan gizi yang kurang dalam waktu cukup lama akibat pemberian makanan yang tidak sesuai dengan kebutuhan gizi. Stunting dapat terjadi mulai janin masih dalam kandungan dan baru nampak saat anak berusia dua tahun (Kementerian Kesehatan Republik Indonesia, 2016). Stunting dan kekurangan gizi lainnya yang terjadi pada 1.000 HPK tidak hanya menyebabkan hambatan pertumbuhan fisik dan meningkatkan kerentanan terhadap penyakit, tetapi juga mengancam perkembangan kognitif yang akan berpengaruh pada tingkat kecerdasan saat ini dan produktivitas anak di masa dewasanya.

Penyebab
Stunting terkait dengan banyak penyebab, antara lain akibat asupan gizi ibu dan anak, status kesehatan balita, ketahanan pangan, lingkungan sosial dan kesehatan, lingkungan pemukiman, kemiskinan, dan lain-lain (UNICEF, 2013; WHO, 2013).
Kekurangan gizi dalam waktu lama itu terjadi sejak janin dalam kandungan sampai awal kehidupan anak (1000 Hari Pertama Kehidupan). Penyebabnya karena rendahnya asupan vitamin dan mineral, dan buruknya keragaman pangan dan sumber protein hewani. Faktor ibu dan pola asuh yang kurang baik terutama pada perilaku dan praktik pemberian makan kepada anak juga menjadi penyebab anak stunting apabila ibu tidak memberikan asupan gizi yang cukup baik. Ibu yang masa remajanya kurang nutrisi, bahkan di masa kehamilan, dan laktasi akan sangat berpengaruh pada pertumbuhan tubuh dan otak anak.
Faktor lainnya yang menyebabkan stunting adalah terjadi infeksi pada ibu, kehamilan remaja, gangguan mental pada ibu, jarak kelahiran anak yang pendek, dan hipertensi. Selain itu, rendahnya akses terhadap pelayanan kesehatan termasuk akses sanitasi dan air bersih menjadi salah satu faktor yang sangat mempengaruhi pertumbuhan anak.

Diagnosis
Diagnosis stunting pertama-tama dilakukan dengan melakukan tanya jawab oleh petugas kesehatan seputaran asupan makan anak, riwayat pemberian ASI, riwayat kehamilan dan persalinan, serta lingkungan tempat tinggal anak. Setelah itu akan dilakukan pemeriksaan fisik berupa mengukur panjang atau tinggi badan, berat badan, lingkar kepala dan lingkar lengan anak. Seorang anak dapat di diagnosis stunting bila tinggi badannya berada di bawah garis merah (-2 SD) berdasarkan kurva pertumbuhan WHO.

Pencegahan
Stunting pada anak akan berlanjut hingga ia beranjak usia dewasa. Jadi sebelum stunting memberikan dampak pada tumbuh dan kembang anak secara menyeluruh, maka stunting harus dicegah. Upaya yang bisa dilakukan untuk pencegahan stunting yaitu:
• Pemberian pola asuh yang tepat
• Memberikan MPASI yang optimal
• Mengobati penyakit yang dialami anak
• Perhatikan kebersihan lingkungan
• Menerapkan hidup bersih keluarga

Pengobatan
Penanganan stunting dapat meliputi pengobatan penyakit penyebabnya, perbaikan nutrisi, pemberian suplemen, serta penerapan pola hidup bersih dan sehat. Yang dapat dilakukan adalah:
• Mengobati penyakit yang mendasari, misalnya memberikan obat-obatan antituberkulosis bila anak menderita TBC
• Memberikan nutrisi tambahan, berupa makanan yang kaya protein hewani, lemak, dan kalori
• Memberikan suplemen, berupa vitamin A, zinc, zat besi, kalsium dan yodium
• Menyarankan keluarga untuk memperbaiki sanitasi dan menerapkan perilaku hidup bersih dan sehat (PHBS), guna mencapai keluarga yang sehat.
Referensi: Kemenkes RI, 2022''';
    }

    final buffer = StringBuffer();
    if (item.deskripsi != null && item.deskripsi!.isNotEmpty) {
      buffer.writeln('Deskripsi');
      buffer.writeln(item.deskripsi);
      buffer.writeln();
    }
    if (item.pengertian != null && item.pengertian!.isNotEmpty) {
      buffer.writeln('Pengertian');
      buffer.writeln(item.pengertian);
      buffer.writeln();
    }
    buffer.writeln('Referensi: Kemenkes RI, 2022');
    return buffer.toString().trim();
  }

  /// Format nama bulan Indonesia untuk konsistensi tanggal artikel
  String _getNamaBulan(int bulan) {
    const namaBulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    if (bulan >= 1 && bulan <= 12) return namaBulan[bulan - 1];
    return '';
  }

  /// Menghasilkan format tanggal artikel (misal: "26 Agustus 2026")
  String _getTanggalArtikel() {
    if (widget.artikel != null && widget.artikel!.tanggal.isNotEmpty) {
      return widget.artikel!.tanggal;
    }
    final now = DateTime.now();
    return '${now.day} ${_getNamaBulan(now.month)} ${now.year}';
  }

  /// Modal pemilih sumber gambar (Kamera atau Galeri)
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Ubah Foto Artikel',
                  style: GoogleFonts.lato(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF6FF),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: _colorPrimaryBlue,
                      size: 24.0,
                    ),
                  ),
                  title: Text(
                    'Ambil Foto dari Kamera',
                    style: GoogleFonts.lato(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                const Divider(height: 1.0, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF6FF),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: _colorPrimaryBlue,
                      size: 24.0,
                    ),
                  ),
                  title: Text(
                    'Pilih Foto dari Galeri',
                    style: GoogleFonts.lato(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Mengambil foto melalui ImagePicker dan langsung memperbarui preview foto
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        PediaBanner.showError(
          context,
          message: 'Gagal memilih foto: $e',
        );
      }
    }
  }

  /// Ekstraksi ringkasan / deskripsi dari teks isi artikel
  String _extractDeskripsi(String fullText) {
    if (fullText.isEmpty) return '';
    final lines = fullText.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final clean = lines[i].trim();
      if (clean.toLowerCase().contains('deskripsi') && i + 1 < lines.length) {
        final next = lines[i + 1].trim();
        if (next.isNotEmpty) return next;
      }
    }
    // Fallback: baris teks bermakna pertama
    for (final line in lines) {
      final clean = line.trim();
      if (clean.isNotEmpty && !clean.toLowerCase().startsWith('deskripsi')) {
        return clean;
      }
    }
    return lines.first.trim();
  }

  /// Ekstraksi subkategori berdasarkan kata kunci artikel
  List<String> _extractSubKategori(String judul, String isi) {
    final combined = '$judul $isi'.toLowerCase();
    final result = <String>[];

    if (combined.contains('stunting')) {
      result.add('Stunting');
    }
    if (combined.contains('wasting')) {
      result.add('Wasting');
    }
    if (combined.contains('gizi') && !result.contains('Gizi')) {
      result.add('Gizi');
    }
    if (result.isEmpty) {
      if (widget.artikel != null && widget.artikel!.subKategori.isNotEmpty) {
        return widget.artikel!.subKategori;
      }
      result.add('Kesehatan Anak');
    }
    return result;
  }

  /// Menyimpan artikel (Update jika Mode Ubah, Tambah Baru jika Mode Tambah)
  Future<void> _handleSimpan() async {
    final judul = _judulController.text.trim();
    final isi = _isiController.text.trim();

    // 1. Validasi data wajib: judul & isi artikel
    bool hasError = false;
    setState(() {
      if (judul.isEmpty) {
        _judulError = 'Judul artikel wajib diisi';
        hasError = true;
      } else {
        _judulError = null;
      }

      if (isi.isEmpty) {
        _isiError = 'Isi artikel wajib diisi';
        hasError = true;
      } else {
        _isiError = null;
      }
    });

    if (hasError) {
      PediaBanner.showError(
        context,
        message: 'Mohon lengkapi judul dan isi artikel terlebih dahulu',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final penulis = _penulisController.text.trim().isNotEmpty
          ? _penulisController.text.trim()
          : (widget.artikel?.penulis ?? 'Pego');
      final tanggal = _getTanggalArtikel();
      final deskripsi = _extractDeskripsi(isi);
      final subKategori = _extractSubKategori(judul, isi);

      final resolvedImage = _imagePath ??
          (widget.artikel?.displayImage ?? 'assets/images/artikel_stunting.jpg');
      final isAsset = resolvedImage.startsWith('assets/');

      if (widget.isEditMode) {
        // ==========================================
        // KONDISI 1: MODE UBAH / EDIT ARTIKEL
        // ==========================================
        // Mempertahankan ID artikel yang sedang diedit agar hanya dokumen tersebut yang diperbarui
        final updatedArtikel = widget.artikel!.copyWith(
          id: widget.artikel!.id,
          judul: judul,
          penulis: penulis,
          tanggal: tanggal,
          kategori: widget.artikel!.kategori,
          subKategori: subKategori,
          deskripsi: deskripsi,
          pengertian: deskripsi,
          isiLengkap: isi,
          assetImagePath: isAsset ? resolvedImage : null,
          imageUrl: isAsset ? null : resolvedImage,
        );

        // Eksekusi update melalui ArtikelService terpusat
        await _artikelService.updateArtikel(updatedArtikel);
      } else {
        // ==========================================
        // KONDISI 2: MODE TAMBAH ARTIKEL BARU
        // ==========================================
        final newArtikel = ArtikelModel(
          judul: judul,
          penulis: penulis,
          tanggal: tanggal,
          kategori: 'Artikel',
          subKategori: subKategori,
          deskripsi: deskripsi,
          pengertian: deskripsi,
          isiLengkap: isi,
          assetImagePath: isAsset ? resolvedImage : null,
          imageUrl: isAsset ? null : resolvedImage,
        );

        // Eksekusi create melalui ArtikelService terpusat
        await _artikelService.tambahArtikel(newArtikel);
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      // Kembali ke halaman daftar artikel dengan membawa status berhasil
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      // Tampilkan pesan error jelas dan biarkan pengguna tetap di form untuk memperbaiki data
      PediaBanner.showError(
        context,
        message: 'Gagal menyimpan artikel: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Judul header otomatis membedakan mode
    final title = widget.isEditMode ? 'Ubah Artikel' : 'Tambah Artikel';
    final tanggal = _getTanggalArtikel();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (Tinggi 56dp, tombol back 12dp dari kiri, judul 12dp setelah back)
            _buildHeader(title),

            // 2. Konten Form Scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12.0),

                      // Area Foto Artikel dengan Border Putus-putus
                      _buildPhotoArea(),

                      const SizedBox(height: 8.0),

                      // Tombol Teks "Ubah Foto" Berwarna Biru
                      Center(
                        child: GestureDetector(
                          onTap: _showImagePickerOptions,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 4.0,
                            ),
                            child: Text(
                              'Ubah Foto',
                              style: GoogleFonts.lato(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: _colorPrimaryBlue,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12.0),

                      // Tanggal Artikel (Warna #C5C5C5)
                      Text(
                        tanggal,
                        style: GoogleFonts.lato(
                          fontSize: 13.0,
                          color: _colorLightGray,
                          fontWeight: FontWeight.normal,
                        ),
                      ),

                      const SizedBox(height: 16.0),

                      // Label & Field "Isi Judul" (Border Putus-putus)
                      Text(
                        'Isi Judul',
                        style: GoogleFonts.lato(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      _buildDashedInputField(
                        controller: _judulController,
                        focusNode: _judulFocusNode,
                        placeholder: 'Judul Artikel',
                        hasError: _judulError != null,
                        onChanged: (val) {
                          if (_judulError != null && val.trim().isNotEmpty) {
                            setState(() => _judulError = null);
                          }
                        },
                      ),
                      if (_judulError != null) ...[
                        const SizedBox(height: 4.0),
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            _judulError!,
                            style: GoogleFonts.lato(
                              fontSize: 12.0,
                              color: const Color(0xFFE53935),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16.0),

                      // Label & Field "Nama Penulis" (Border Putus-putus)
                      Text(
                        'Nama Penulis',
                        style: GoogleFonts.lato(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      _buildDashedInputField(
                        controller: _penulisController,
                        focusNode: _penulisFocusNode,
                        placeholder: 'Nama Penulis',
                      ),

                      const SizedBox(height: 20.0),

                      // Garis Pemisah Horizontal Tipis
                      const Divider(
                        height: 1.0,
                        thickness: 1.0,
                        color: Color(0xFFEEEEEE),
                      ),

                      const SizedBox(height: 20.0),

                      // Label & Field "Isi Artikel" dengan Toolbar Rich Text (Bold, Italic, Underline)
                      Row(
                        children: [
                          Text(
                            'Isi Artikel',
                            style: GoogleFonts.lato(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          const Text(
                            '*',
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      ArticleRichTextEditor(
                        controller: _isiController,
                        focusNode: _isiFocusNode,
                        placeholder: 'Tulis isi artikel di sini...',
                        hasError: _isiError != null,
                        minLines: 8,
                        onChanged: (val) {
                          if (_isiError != null && val.trim().isNotEmpty) {
                            setState(() => _isiError = null);
                          }
                        },
                      ),
                      if (_isiError != null) ...[
                        const SizedBox(height: 4.0),
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            _isiError!,
                            style: GoogleFonts.lato(
                              fontSize: 12.0,
                              color: const Color(0xFFE53935),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24.0),

                      // Tombol "Simpan" Berwarna Biru dengan Sudut Rounded
                      SizedBox(
                        width: double.infinity,
                        height: 48.0,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSimpan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _colorPrimaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22.0,
                                  height: 22.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Simpan',
                                  style: GoogleFonts.lato(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 28.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header kustom dengan tinggi 56dp di bawah SafeArea atas
  Widget _buildHeader(String title) {
    return Container(
      height: 56.0,
      width: double.infinity,
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Back (12dp dari tepi kiri)
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(24.0),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.arrow_back,
                    size: 24.0,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),

          // Judul Header (12dp setelah tombol back)
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Area Foto Persegi Panjang dengan Sudut Sedikit Membulat dan Border Putus-Putus
  Widget _buildPhotoArea() {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: DashedBorderContainer(
        radius: 12.0,
        height: 200.0,
        width: double.infinity,
        color: _colorDarkGray,
        strokeWidth: 1.2,
        dashWidth: 6.0,
        dashSpace: 4.0,
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: _imagePath != null && _imagePath!.isNotEmpty
              ? _buildImageWidget(_imagePath!)
              : const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 64.0,
                    color: _colorDarkGray,
                  ),
                ),
        ),
      ),
    );
  }

  /// Menampilkan gambar baik dari aset, file disk lokal, maupun URL remote
  Widget _buildImageWidget(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackPhotoIcon(),
      );
    }

    if (!kIsWeb && File(path).existsSync()) {
      return Image.file(
        File(path),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackPhotoIcon(),
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackPhotoIcon(),
      );
    }

    return _buildFallbackPhotoIcon();
  }

  Widget _buildFallbackPhotoIcon() {
    return const Center(
      child: Icon(
        Icons.image_outlined,
        size: 64.0,
        color: _colorDarkGray,
      ),
    );
  }

  /// Input single-line dengan border putus-putus rounded
  Widget _buildDashedInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    bool hasError = false,
    ValueChanged<String>? onChanged,
  }) {
    return DashedBorderContainer(
      radius: 10.0,
      height: 48.0,
      color: hasError ? const Color(0xFFE53935) : _colorDarkGray,
      strokeWidth: 1.0,
      dashWidth: 5.0,
      dashSpace: 3.5,
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          style: GoogleFonts.lato(
            fontSize: 14.0,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.lato(
              fontSize: 14.0,
              color: _colorDarkGray,
              fontWeight: FontWeight.normal,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  /// Area input multi-line berukuran besar untuk isi artikel (scrollable, tanpa overflow)
  Widget _buildDashedTextArea({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    bool hasError = false,
    ValueChanged<String>? onChanged,
  }) {
    return DashedBorderContainer(
      radius: 12.0,
      color: hasError ? const Color(0xFFE53935) : _colorDarkGray,
      strokeWidth: 1.0,
      dashWidth: 5.0,
      dashSpace: 3.5,
      padding: const EdgeInsets.all(14.0),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        maxLines: null,
        minLines: 8,
        keyboardType: TextInputType.multiline,
        style: GoogleFonts.lato(
          fontSize: 13.0,
          color: Colors.black,
          height: 1.35,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: GoogleFonts.lato(
            fontSize: 13.0,
            color: _colorDarkGray,
            fontWeight: FontWeight.normal,
            height: 1.35,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// Widget pembungkus kontainer dengan garis batas putus-putus (Dashed Border)
/// menggunakan CustomPainter murni tanpa dependensi pihak ketiga.
class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? backgroundColor;

  const DashedBorderContainer({
    super.key,
    required this.child,
    this.radius = 10.0,
    this.color = const Color(0xFF7F7F7F),
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.5,
    this.padding,
    this.width,
    this.height,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
      ),
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = math.min(dashWidth, metric.length - distance);
        dashedPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace;
}
