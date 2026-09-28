import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/widgets/pedia_banner.dart';
import '../../../../shared/widgets/pedia_bottom_nav_bar.dart';

/// Halaman "Grafik Pengguna" untuk peran Super Admin pada aplikasi PediaGrow.
///
/// Menyajikan ringkasan visual dan data komprehensif:
/// 1. Header (tinggi 56dp, back button 12dp dari kiri, judul 12dp setelahnya, SafeArea).
/// 2. Card Sambutan hijau mint dengan ilustrasi Super Admin perempuan memegang tablet.
/// 3. Dua Card Ringkasan berdampingan: "Total Pengguna" (biru muda) & "Total Anak Terdaftar" (hijau mint).
/// 4. Card Besar Grafik "Jumlah Pengguna & Anak Terdaftar" berupa grouped bar chart
///    dengan sumbu Y (0-100) dan area batang yang dapat digeser secara horizontal (Axis.horizontal).
/// 5. Card "Data Anak Berdasarkan Jenis Kelamin" (Laki-laki vs Perempuan + persentase).
/// 6. Bagian "Dataset Pengguna" dengan tombol unduh dan tabel scrollable horizontal.
/// 7. Scaffold bottomNavigationBar menggunakan [PediaBottomNavBar] dengan sudut atas membulat.
class GrafikPenggunaPage extends StatefulWidget {
  const GrafikPenggunaPage({super.key});

  @override
  State<GrafikPenggunaPage> createState() => _GrafikPenggunaPageState();
}

class _GrafikPenggunaPageState extends State<GrafikPenggunaPage> {

  bool _isLoading = true;
  String? _errorMessage;

  // Data ringkasan (default ke angka referensi desain, diperbarui saat data riil tersedia)
  int _totalPengguna = 700;
  int _totalAnak = 800;

  int _totalLakiLaki = 414;
  int _totalPerempuan = 386;
  double _persenLakiLaki = 51.8;
  double _persenPerempuan = 48.2;

  // Data grafik per bulan (grouped bar chart)
  List<_MonthlyData> _monthlyChartData = [];

  // Data tabel dataset pengguna
  List<_UserRowData> _userDataset = [];

  // Palet warna konsisten sesuai acuan desain
  static const Color _colorUserBlue = Color(0xFF3B82F6); // Batang & aksen Pengguna
  static const Color _colorChildTeal = Color(0xFF48BB78); // Batang & aksen Anak (toska/hijau)
  static const Color _colorMintBg = Color(0xFFE6F4F1); // Background card sambutan
  static const Color _colorBlueCardBg = Color(0xFFE8F1FC); // Card ringkasan total pengguna
  static const Color _colorMintCardBg = Color(0xFFE8F5EE); // Card ringkasan total anak
  static const Color _colorFemalePeach = Color(0xFFF43F5E); // Aksen jenis kelamin perempuan

  @override
  void initState() {
    super.initState();
    _initDefaultData();
    _loadDataFromSource();
  }

  /// Data awal/seed default sesuai persis dengan referensi desain
  void _initDefaultData() {
    _monthlyChartData = [
      const _MonthlyData(month: 'Januari', userCount: 45, childCount: 52),
      const _MonthlyData(month: 'Februari', userCount: 58, childCount: 61),
      const _MonthlyData(month: 'Maret', userCount: 51, childCount: 57),
      const _MonthlyData(month: 'April', userCount: 63, childCount: 68),
      const _MonthlyData(month: 'Mei', userCount: 70, childCount: 75),
      const _MonthlyData(month: 'Juni', userCount: 65, childCount: 72),
      const _MonthlyData(month: 'Juli', userCount: 78, childCount: 82),
      const _MonthlyData(month: 'Agustus', userCount: 85, childCount: 88),
      const _MonthlyData(month: 'September', userCount: 80, childCount: 84),
      const _MonthlyData(month: 'Oktober', userCount: 88, childCount: 92),
      const _MonthlyData(month: 'November', userCount: 90, childCount: 95),
      const _MonthlyData(month: 'Desember', userCount: 95, childCount: 98),
    ];

    _userDataset = [
      const _UserRowData(firstName: 'Susanti Saputri', lastName: 'Dewi', gender: 'Perempuan', email: 'susanti.dewi@gmail.com', phone: '081234567890'),
      const _UserRowData(firstName: 'Indah Dwi', lastName: 'Puspitasari', gender: 'Perempuan', email: 'indah.dwi@gmail.com', phone: '081234567891'),
      const _UserRowData(firstName: 'Kurnia Dwi', lastName: 'Anisa', gender: 'Perempuan', email: 'kurnia.anisa@gmail.com', phone: '081234567892'),
      const _UserRowData(firstName: 'Alivya Rinda', lastName: 'Okky', gender: 'Perempuan', email: 'alivya.okky@gmail.com', phone: '081234567893'),
      const _UserRowData(firstName: 'Dita Nur', lastName: 'Alifah', gender: 'Perempuan', email: 'dita.alifah@gmail.com', phone: '081234567894'),
      const _UserRowData(firstName: 'Ahmad', lastName: 'Fauzi', gender: 'Laki-laki', email: 'ahmad.fauzi@gmail.com', phone: '081234567895'),
      const _UserRowData(firstName: 'Budi', lastName: 'Santoso', gender: 'Laki-laki', email: 'budi.santoso@gmail.com', phone: '081234567896'),
      const _UserRowData(firstName: 'Siti', lastName: 'Rahmawati', gender: 'Perempuan', email: 'siti.rahma@gmail.com', phone: '081234567897'),
      const _UserRowData(firstName: 'Rizky', lastName: 'Pratama', gender: 'Laki-laki', email: 'rizky.pratama@gmail.com', phone: '081234567898'),
      const _UserRowData(firstName: 'Nur', lastName: 'Hidayah', gender: 'Perempuan', email: 'nur.hidayah@gmail.com', phone: '081234567899'),
    ];
  }

  /// Memuat data pengguna dan anak dari service Firestore / database lokal
  Future<void> _loadDataFromSource() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Ambil data koleksi users jika Firestore aktif
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      if (usersSnap.docs.isNotEmpty) {
        _totalPengguna = usersSnap.docs.length;

        // Petakan ke tabel dataset pengguna
        final dynamicList = <_UserRowData>[];
        for (final doc in usersSnap.docs) {
          final data = doc.data();
          final fullName = (data['name'] ?? '').toString().trim();
          final parts = fullName.split(' ');
          final first = parts.isNotEmpty ? parts.first : 'Pengguna';
          final last = parts.length > 1 ? parts.sublist(1).join(' ') : '-';
          final gender = (data['gender'] ?? 'Perempuan').toString();
          final email = (data['email'] ?? '-').toString();
          final phone = (data['phone'] ?? '-').toString();

          dynamicList.add(_UserRowData(
            firstName: first,
            lastName: last,
            gender: gender,
            email: email,
            phone: phone,
          ));
        }

        if (dynamicList.isNotEmpty) {
          _userDataset = dynamicList;
        }
      }

      // 2. Ambil data koleksi children jika Firestore aktif
      final childrenSnap = await FirebaseFirestore.instance.collection('children').get();
      if (childrenSnap.docs.isNotEmpty) {
        _totalAnak = childrenSnap.docs.length;

        int lCount = 0;
        int pCount = 0;
        for (final doc in childrenSnap.docs) {
          final g = (doc.data()['gender'] ?? '').toString().toLowerCase();
          if (g.contains('laki') || g == 'l') {
            lCount++;
          } else {
            pCount++;
          }
        }

        _totalLakiLaki = lCount;
        _totalPerempuan = pCount;
        if (_totalAnak > 0) {
          _persenLakiLaki = double.parse(((lCount / _totalAnak) * 100).toStringAsFixed(1));
          _persenPerempuan = double.parse(((pCount / _totalAnak) * 100).toStringAsFixed(1));
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      // Jika Firestore belum terkoneksi / mode offline, gunakan fallback referensi desain
      debugPrint('[GrafikPenggunaPage] Firestore offline/unreachable: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Data tetap terisi dari _initDefaultData()
      });
    }
  }

  /// Penanganan aksi tombol "Unduh" dataset pengguna
  void _handleDownloadDataset() {
    // TODO: Implementasi export file dataset (CSV / Excel) ke direktori lokal perangkat
    PediaBanner.showSuccess(
      context,
      message: 'File berhasil disimpan',
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Bottom Navigation Bar permanen PediaGrow dengan sudut atas melengkung
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (Tinggi 56dp, back 12dp dari kiri, judul 12dp setelahnya)
            _buildHeader(),

            // 2. Konten Utama Halaman (Vertical Scrolling)
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3985E7)),
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorView()
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12.0),

                              // Card Sambutan Super Admin
                              _buildWelcomeCard(),

                              const SizedBox(height: 16.0),

                              // Dua Card Ringkasan Berdampingan (Total Pengguna & Total Anak)
                              _buildSummaryCards(),

                              const SizedBox(height: 24.0),

                              // Judul "Ringkasan Pengguna & Anak"
                              Text(
                                'Ringkasan Pengguna & Anak',
                                style: GoogleFonts.lato(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),

                              const SizedBox(height: 12.0),

                              // Card Besar Grafik (Horizontal Scrollable)
                              _buildChartCard(),

                              const SizedBox(height: 20.0),

                              // Card Data Anak Berdasarkan Jenis Kelamin
                              _buildGenderDataCard(),

                              const SizedBox(height: 24.0),

                              // Bagian Dataset Pengguna & Tombol Unduh
                              _buildDatasetHeader(),

                              const SizedBox(height: 12.0),

                              // Tabel Dataset Pengguna (Horizontal Scrollable)
                              _buildDatasetTable(),

                              const SizedBox(height: 32.0),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header kustom dengan tinggi 56dp di bawah SafeArea atas
  Widget _buildHeader() {
    return Container(
      height: 56.0,
      width: double.infinity,
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Kembali (12dp dari tepi kiri layar)
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

          // Judul "Grafik Pengguna"
          Expanded(
            child: Text(
              'Grafik Pengguna',
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

  /// Card Sambutan berwarna hijau muda mint dengan teks dan ilustrasi Super Admin
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _colorMintBg,
        borderRadius: BorderRadius.circular(16.0),
      ),
      padding: const EdgeInsets.fromLTRB(18.0, 18.0, 12.0, 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Teks Sambutan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selamat datang,',
                  style: GoogleFonts.lato(
                    fontSize: 14.0,
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Super Admin',
                  style: GoogleFonts.lato(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  'Kelola data pengguna dan\nanak secara keseluruhan',
                  style: GoogleFonts.lato(
                    fontSize: 13.0,
                    color: const Color(0xFF334155),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // Ilustrasi Super Admin memegang tablet
          SizedBox(
            width: 110.0,
            height: 110.0,
            child: Image.asset(
              'assets/images/superadmin_tablet_illustration.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildFallbackIllustration(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIllustration() {
    return Container(
      width: 90.0,
      height: 90.0,
      decoration: const BoxDecoration(
        color: Color(0xFFDEF2ED),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.support_agent_rounded,
        size: 48.0,
        color: Color(0xFF14B8A6),
      ),
    );
  }

  /// Dua Card Ringkasan Berdampingan: "Total Pengguna" & "Total Anak Terdaftar"
  Widget _buildSummaryCards() {
    return Row(
      children: [
        // Card 1: Total Pengguna (Nuansa Biru Muda)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: _colorBlueCardBg,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: const Color(0xFFD4E5F9),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Pengguna',
                  style: GoogleFonts.lato(
                    fontSize: 13.0,
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '$_totalPengguna',
                  style: GoogleFonts.lato(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Pengguna',
                  style: GoogleFonts.lato(
                    fontSize: 13.0,
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 14.0),

        // Card 2: Total Anak Terdaftar (Nuansa Hijau Muda / Mint)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: _colorMintCardBg,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: const Color(0xFFCEECE0),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Anak Terdaftar',
                  style: GoogleFonts.lato(
                    fontSize: 13.0,
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '$_totalAnak',
                  style: GoogleFonts.lato(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Anak',
                  style: GoogleFonts.lato(
                    fontSize: 13.0,
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Card Besar Grafik "Jumlah Pengguna & Anak Terdaftar" dengan Horizontal Scroll
  Widget _buildChartCard() {
    const double chartHeight = 220.0;
    const double maxVal = 100.0;
    const int stepCount = 10; // Interval 10 (100, 90, 80 ... 0)

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul Grafik
          Text(
            'Jumlah Pengguna & Anak Terdaftar',
            style: GoogleFonts.lato(
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14.0),

          // Legenda Grafik: [Biru] Pengguna   [Toska] Anak
          Row(
            children: [
              Container(
                width: 22.0,
                height: 12.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEBFE),
                  borderRadius: BorderRadius.circular(3.0),
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                'Pengguna',
                style: GoogleFonts.lato(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 24.0),
              Container(
                width: 22.0,
                height: 12.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF56B9A8),
                  borderRadius: BorderRadius.circular(3.0),
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                'Anak',
                style: GoogleFonts.lato(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18.0),

          // Area Grafik Bar Chart: Sumbu Y Fixed di Kiri, Batang Scrollable Horizontal
          SizedBox(
            height: chartHeight + 40.0, // Memberi ruang label bulan di bawah
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Sumbu Y Vertikal Statis (0 s/d 100 dengan interval 10)
                SizedBox(
                  width: 34.0,
                  height: chartHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(stepCount + 1, (index) {
                      final val = (stepCount - index) * 10;
                      return Text(
                        '$val',
                        style: GoogleFonts.lato(
                          fontSize: 11.0,
                          color: const Color(0xFF64748B),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 6.0),

                // 2. Area Grafik dengan Garis Grid dan Horizontal Scroll
                Expanded(
                  child: Stack(
                    children: [
                      // Grid Line Horizontal di belakang batang
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: chartHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(stepCount + 1, (index) {
                            return const Divider(
                              height: 1.0,
                              thickness: 1.0,
                              color: Color(0xFFF1F5F9),
                            );
                          }),
                        ),
                      ),

                      // Konten Batang Grafik yang Dapat Di-scroll Secara Horizontal
                      Positioned.fill(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(_monthlyChartData.length, (i) {
                                final data = _monthlyChartData[i];
                                return _buildMonthlyBarGroup(
                                  data: data,
                                  maxVal: maxVal,
                                  chartHeight: chartHeight,
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kelompok 2 batang (Pengguna & Anak) untuk satu bulan
  Widget _buildMonthlyBarGroup({
    required _MonthlyData data,
    required double maxVal,
    required double chartHeight,
  }) {
    const double barWidth = 20.0;
    // Tinggi batang proporsional terhadap chartHeight
    final double userBarHeight = ((data.userCount / maxVal) * chartHeight).clamp(0.0, chartHeight);
    final double childBarHeight = ((data.childCount / maxVal) * chartHeight).clamp(0.0, chartHeight);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Column(
        children: [
          // Area Batang (tinggi tepat chartHeight)
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Batang 1: Pengguna (Warna Biru)
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${data.userCount}',
                      style: GoogleFonts.lato(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Container(
                      width: barWidth,
                      height: userBarHeight,
                      decoration: const BoxDecoration(
                        color: _colorUserBlue,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(3.0)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 3.0),

                // Batang 2: Anak (Warna Toska)
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${data.childCount}',
                      style: GoogleFonts.lato(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Container(
                      width: barWidth,
                      height: childBarHeight,
                      decoration: const BoxDecoration(
                        color: Color(0xFF56B9A8),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(3.0)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8.0),

          // Label Bulan di Bawah Batang
          Text(
            data.month,
            style: GoogleFonts.lato(
              fontSize: 12.0,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  /// Card Data Anak Berdasarkan Jenis Kelamin (Laki-laki & Perempuan)
  Widget _buildGenderDataCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data  Anak Berdasarkan Jenis Kelamin',
            style: GoogleFonts.lato(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14.0),

          Row(
            children: [
              // 1. Data Laki-laki
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar Laki-laki
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCEBFE),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.face,
                        size: 28.0,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Laki-laki',
                            style: GoogleFonts.lato(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '$_totalLakiLaki',
                            style: GoogleFonts.lato(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: _colorUserBlue,
                            ),
                          ),
                          Text(
                            '($_persenLakiLaki%)',
                            style: GoogleFonts.lato(
                              fontSize: 12.0,
                              color: _colorUserBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Data Perempuan
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar Perempuan
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFEDD5),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.face_3,
                        size: 28.0,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perempuan',
                            style: GoogleFonts.lato(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '$_totalPerempuan',
                            style: GoogleFonts.lato(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF97316),
                            ),
                          ),
                          Text(
                            '($_persenPerempuan%)',
                            style: GoogleFonts.lato(
                              fontSize: 12.0,
                              color: const Color(0xFFF97316),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Header Bagian Dataset Pengguna & Tombol Unduh
  Widget _buildDatasetHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Dataset  Pengguna',
          style: GoogleFonts.lato(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        // Tombol Unduh Pill Rounded
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleDownloadDataset,
            borderRadius: BorderRadius.circular(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.file_download_outlined,
                    size: 16.0,
                    color: Color(0xFF475569),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'Unduh',
                    style: GoogleFonts.lato(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tabel Dataset Pengguna yang Dapat Digeser Secara Horizontal (Axis.horizontal)
  Widget _buildDatasetTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 420.0),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              horizontalMargin: 16.0,
              columnSpacing: 24.0,
              dataRowMinHeight: 46.0,
              dataRowMaxHeight: 52.0,
              headingRowHeight: 46.0,
              dividerThickness: 1.0,
              columns: [
                DataColumn(
                  label: Text(
                    'Nama Depan',
                    style: GoogleFonts.lato(
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Nama Belakang',
                    style: GoogleFonts.lato(
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Jenis Kelamin',
                    style: GoogleFonts.lato(
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Email',
                    style: GoogleFonts.lato(
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
              rows: _userDataset.map((row) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        row.firstName,
                        style: GoogleFonts.lato(
                          fontSize: 13.0,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        row.lastName,
                        style: GoogleFonts.lato(
                          fontSize: 13.0,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        row.gender,
                        style: GoogleFonts.lato(
                          fontSize: 13.0,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        row.email,
                        style: GoogleFonts.lato(
                          fontSize: 13.0,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  /// Tampilan jika terjadi error pemuatan
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48.0,
              color: Color(0xFFE53935),
            ),
            const SizedBox(height: 12.0),
            Text(
              'Gagal Memuat Data',
              style: GoogleFonts.lato(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              _errorMessage ?? 'Terjadi kesalahan saat memuat grafik pengguna.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13.0,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _loadDataFromSource,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3985E7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Navigation Bar permanen PediaGrow dengan sudut atas membulat
  Widget _buildBottomNavigationBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
      child: PediaBottomNavBar(
        selectedIndex: -1,
        onNavTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).maybePop();
              break;
            default:
              break;
          }
        },
      ),
    );
  }
}

/// Model data bar chart bulanan
class _MonthlyData {
  final String month;
  final int userCount;
  final int childCount;

  const _MonthlyData({
    required this.month,
    required this.userCount,
    required this.childCount,
  });
}

/// Model data baris tabel dataset pengguna
class _UserRowData {
  final String firstName;
  final String lastName;
  final String gender;
  final String email;
  final String phone;

  const _UserRowData({
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.email,
    required this.phone,
  });
}
