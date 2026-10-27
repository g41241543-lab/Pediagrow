import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Daftar Strata Pendidikan yang relevan dengan bidang kesehatan & medis di Indonesia.
const List<String> kStrataPendidikanList = [
  'SMA',
  'SMK Kesehatan',
  'DIII',
  'DIV',
  'S1',
  'Profesi',
  'S2',
  'Spesialis',
  'Sub Spesialis',
  'S3',
];

/// Daftar Program Studi (Prodi) untuk Dokter dengan tambahan Subspesialisasi lengkap.
const List<String> kProdiDokterList = [
  'Kedokteran Umum',
  'Profesi Dokter (dr.)',
  'Ilmu Kesehatan Anak (Sp.A)',
  'Subspesialis Alergi Imunologi Anak (Sp.A(K))',
  'Subspesialis Endokrinologi Anak (Sp.A(K))',
  'Subspesialis Gastrohepatologi Anak (Sp.A(K))',
  'Subspesialis Hematologi Onkologi Anak (Sp.A(K))',
  'Subspesialis Infeksi & Penyakit Tropis Anak (Sp.A(K))',
  'Subspesialis Kardiologi Anak (Sp.A(K))',
  'Subspesialis Nefrologi Anak (Sp.A(K))',
  'Subspesialis Neurologi Anak (Sp.A(K))',
  'Subspesialis Nutrisi & Penyakit Metabolik Anak (Sp.A(K))',
  'Subspesialis ERIA / Gawat Darurat Anak (Sp.A(K))',
  'Subspesialis Neonatologi / Perinatologi (Sp.A(K))',
  'Subspesialis Respirologi Anak (Sp.A(K))',
  'Subspesialis Tumbuh Kembang Pediatri Sosial (Sp.A(K))',
  'Subspesialis Citogenetika & Genetika Medis',
  'Ilmu Bedah Anak (Sp.BA)',
  'Obstetri & Ginekologi (Sp.OG)',
  'Ilmu Penyakit Dalam (Sp.PD)',
  'Ilmu Kesehatan Jiwa / Psikiatri Anak (Sp.KJ)',
  'Ilmu Kedokteran Fisik & Rehabilitasi Medis (Sp.KFR)',
  'Kesehatan Masyarakat (M.K.M)',
  'Ilmu Kedokteran Klinis (M.Ked.Klin)',
  'Ilmu Biomedik (M.Biomed)',
  'Doktor Ilmu Kedokteran (Dr.)',
];

/// Daftar Program Studi (Prodi) untuk PMIK & Tenaga Kesehatan Lainnya.
const List<String> kProdiPmikList = [
  'Rekam Medis & Informasi Kesehatan (RMIK)',
  'Manajemen Informasi Kesehatan (MIK)',
  'Administrasi Rumah Sakit (ARS)',
  'Sistem Informasi Kesehatan',
  'Informatika Medis',
  'Kesehatan Masyarakat (Kesmas)',
  'Epidemiologi Kesehatan',
  'Gizi Klinis / Ilmu Gizi',
  'Ilmu Keperawatan (S.Kep / Ners)',
  'Kebidanan (Bdn)',
  'Farmasi Klinis (Apt)',
  'Teknologi Laboratorium Medis (TLM)',
  'Teknologi Radiologi Pencitraan',
  'Manajemen Pelayanan Kesehatan',
];

/// Daftar Perguruan Tinggi, Universitas, Poltekkes, Politeknik, dan Institut di Indonesia.
const List<String> kUniversitasList = [
  'Universitas Jember',
  'Politeknik Negeri Jember',
  'Universitas Airlangga',
  'Universitas Brawijaya',
  'Universitas Indonesia',
  'Universitas Gadjah Mada',
  'Universitas Diponegoro',
  'Universitas Padjadjaran',
  'Universitas Sebelas Maret',
  'Universitas Hasanuddin',
  'Universitas Sumatera Utara',
  'Universitas Andalas',
  'Universitas Udayana',
  'Universitas Sriwijaya',
  'Universitas Riau',
  'Universitas Lampung',
  'Universitas Syiah Kuala',
  'Universitas Lambung Mangkurat',
  'Universitas Sam Ratulangi',
  'Universitas Mataram',
  'Poltekkes Kemenkes Surabaya',
  'Poltekkes Kemenkes Malang',
  'Poltekkes Kemenkes Semarang',
  'Poltekkes Kemenkes Yogyakarta',
  'Poltekkes Kemenkes Jakarta I',
  'Poltekkes Kemenkes Jakarta II',
  'Poltekkes Kemenkes Jakarta III',
  'Poltekkes Kemenkes Bandung',
  'Poltekkes Kemenkes Surakarta',
  'Poltekkes Kemenkes Denpasar',
  'Poltekkes Kemenkes Medan',
  'Poltekkes Kemenkes Makassar',
  'Politeknik Negeri Malang',
  'Institut Pertanian Bogor',
  'Institut Teknologi Bandung',
  'Institut Teknologi Sepuluh Nopember',
  'Universitas Islam Indonesia',
  'Universitas Muhammadiyah Surakarta',
  'Universitas Muhammadiyah Yogyakarta',
  'Universitas Muhammadiyah Malang',
  'Universitas Muhammadiyah Jember',
  'Universitas Katolik Indonesia Atma Jaya',
  'Universitas Tarumanagara',
  'Universitas Trisakti',
  'Universitas Pelita Harapan',
  'Universitas YARSI',
  'Universitas Kristen Maranatha',
  'Universitas Surabaya',
  'Universitas Hang Tuah Surabaya',
  'Universitas Ciputra',
  'STIKES dr. Soebandi Jember',
  'Universitas dr. Soebandi',
];

/// Controller data untuk satu entri riwayat pendidikan (Strata, Prodi, Univ).
class EducationEntry {
  final TextEditingController strataCtrl;
  final TextEditingController prodiCtrl;
  final TextEditingController univCtrl;

  EducationEntry({
    String strata = '',
    String prodi = '',
    String univ = '',
  })  : strataCtrl = TextEditingController(text: strata),
        prodiCtrl = TextEditingController(text: prodi),
        univCtrl = TextEditingController(text: univ);

  /// Menghasilkan format string tersimpan: "[Strata] [Prodi] - [Univ]"
  String toEducationString() {
    final s = strataCtrl.text.trim();
    final p = prodiCtrl.text.trim();
    final u = univCtrl.text.trim();

    final titleParts = <String>[];
    if (s.isNotEmpty) titleParts.add(s);
    if (p.isNotEmpty) titleParts.add(p);
    final prefix = titleParts.join(' ');

    if (prefix.isNotEmpty && u.isNotEmpty) {
      return '$prefix - $u';
    } else if (prefix.isNotEmpty) {
      return prefix;
    } else {
      return u;
    }
  }

  /// Parsing cerdas dari string tersimpan ke dalam EducationEntry
  factory EducationEntry.fromString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return EducationEntry();

    String strata = '';
    String prodi = '';
    String univ = '';

    String remaining = trimmed;
    if (remaining.contains(' - ')) {
      final splitHyphen = remaining.split(' - ');
      remaining = splitHyphen.first.trim();
      univ = splitHyphen.sublist(1).join(' - ').trim();
    } else if (remaining.contains(', ')) {
      final splitComma = remaining.split(', ');
      remaining = splitComma.first.trim();
      univ = splitComma.sublist(1).join(', ').trim();
    }

    // Identifikasi strata pendidikan
    for (final s in kStrataPendidikanList) {
      final upperS = s.toUpperCase();
      final upperR = remaining.toUpperCase();
      if (upperR == upperS ||
          upperR.startsWith('$upperS ') ||
          upperR.startsWith('$upperS-') ||
          upperR.startsWith('$upperS:')) {
        strata = s;
        remaining = remaining.substring(s.length).trim();
        if (remaining.startsWith('-') || remaining.startsWith(':')) {
          remaining = remaining.substring(1).trim();
        }
        break;
      }
    }

    prodi = remaining.trim();
    return EducationEntry(strata: strata, prodi: prodi, univ: univ);
  }

  void dispose() {
    strataCtrl.dispose();
    prodiCtrl.dispose();
    univCtrl.dispose();
  }
}

/// Widget Searchable Dropdown Field yang dapat diketik langsung
/// sekaligus dapat dipilih dari modal pencarian (searchable picker).
class SearchableDropdownField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final List<String> options;
  final ValueChanged<String>? onChanged;

  const SearchableDropdownField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.options,
    this.onChanged,
  });

  void _openSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchPickerSheet(
        title: label,
        hintText: 'Cari $label...',
        options: options,
        initialValue: controller.text,
        onSelected: (val) {
          controller.text = val;
          onChanged?.call(val);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                style: GoogleFonts.lato(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A2228),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: GoogleFonts.lato(
                    fontSize: 12.0,
                    color: const Color(0xFF8696A0),
                  ),
                ),
                onChanged: onChanged,
              ),
            ),
            GestureDetector(
              onTap: () => _openSearchDialog(context),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.0),
                child: Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20.0,
                  color: Color(0xFF8696A0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2.0),
        Container(
          height: 1.0,
          color: const Color(0xFFE9EDEF),
        ),
      ],
    );
  }
}

/// Modal Bottom Sheet pencarian dengan filter real-time
class _SearchPickerSheet extends StatefulWidget {
  final String title;
  final String hintText;
  final List<String> options;
  final String initialValue;
  final ValueChanged<String> onSelected;

  const _SearchPickerSheet({
    required this.title,
    required this.hintText,
    required this.options,
    required this.initialValue,
    required this.onSelected,
  });

  @override
  State<_SearchPickerSheet> createState() => _SearchPickerSheetState();
}

class _SearchPickerSheetState extends State<_SearchPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = List.from(widget.options);
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filtered = List.from(widget.options);
      } else {
        _filtered = widget.options
            .where((opt) => opt.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim();
    final hasExactMatch = _filtered.any((e) => e.toLowerCase() == query.toLowerCase());
    final isCustomApplicable = query.isNotEmpty && !hasExactMatch;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Header Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pilih ${widget.title}',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: const Color(0xFF6B7280),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 20, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      style: GoogleFonts.lato(fontSize: 13.5, color: const Color(0xFF111827)),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.hintText,
                        hintStyle: GoogleFonts.lato(fontSize: 13.5, color: const Color(0xFF9CA3AF)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchCtrl.clear(),
                      child: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF9CA3AF)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Opsi kustom jika teks pencarian belum ada di daftar
          if (isCustomApplicable)
            InkWell(
              onTap: () {
                widget.onSelected(query);
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: const Color(0xFFEFF6FF),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFF2B7AE8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Gunakan: "$query"',
                        style: GoogleFonts.lato(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2B7AE8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Daftar Pilihan
          Flexible(
            child: _filtered.isEmpty && !isCustomApplicable
                ? Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Center(
                      child: Text(
                        'Tidak ada hasil ditemukan.',
                        style: GoogleFonts.lato(color: const Color(0xFF9CA3AF), fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    itemBuilder: (context, idx) {
                      final item = _filtered[idx];
                      final isSelected = item.toLowerCase() == widget.initialValue.toLowerCase().trim();

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                        title: Text(
                          item,
                          style: GoogleFonts.lato(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFF2B7AE8) : const Color(0xFF1F2937),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded, color: Color(0xFF2B7AE8), size: 18)
                            : null,
                        onTap: () {
                          widget.onSelected(item);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

/// Widget Kartu Satu Entri Pendidikan (Strata, Prodi, Univ) sesuai contoh gambar pengguna.
class PendidikanTripletCard extends StatelessWidget {
  final EducationEntry entry;
  final bool isDokter;
  final VoidCallback? onRemove;
  final bool showRemove;

  const PendidikanTripletCard({
    super.key,
    required this.entry,
    this.isDokter = true,
    this.onRemove,
    this.showRemove = false,
  });

  @override
  Widget build(BuildContext context) {
    final prodiList = isDokter ? kProdiDokterList : kProdiPmikList;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ikon Topi Toga (seperti pada contoh gambar)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 20.0,
                color: Color(0xFF3985E7),
              ),
            ),
          ),
          const SizedBox(width: 12.0),

          // 3 Kolom Input Pendidikan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris 1: Strata Pendidikan (Kiri) & Prodi (Kanan)
                Row(
                  children: [
                    // Strata Pendidikan (SMA, DIII, DIV, S1, S2, S3, Spesialis, Sub Spesialis, dll)
                    Expanded(
                      flex: 4,
                      child: SearchableDropdownField(
                        controller: entry.strataCtrl,
                        label: 'Strata Pendidikan',
                        hint: 'Strata',
                        options: kStrataPendidikanList,
                      ),
                    ),
                    const SizedBox(width: 10.0),

                    // Program Studi (Prodi) dengan Subspesialis untuk Dokter
                    Expanded(
                      flex: 6,
                      child: SearchableDropdownField(
                        controller: entry.prodiCtrl,
                        label: isDokter ? 'Prodi & Subspesialis' : 'Program Studi',
                        hint: 'Program Studi / Subspesialis',
                        options: prodiList,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),

                // Baris 2: Universitas / Perguruan Tinggi / Poltekkes / Institut di Indonesia
                SearchableDropdownField(
                  controller: entry.univCtrl,
                  label: 'Universitas / Perguruan Tinggi',
                  hint: 'Universitas / Poltekkes / Institut',
                  options: kUniversitasList,
                ),
              ],
            ),
          ),

          // Tombol Hapus Entri (jika lebih dari 1)
          if (showRemove)
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(left: 8.0, top: 8.0),
                child: Icon(
                  Icons.remove_circle_outline_rounded,
                  size: 20.0,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
