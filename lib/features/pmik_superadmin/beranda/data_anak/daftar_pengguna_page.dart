import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/child_model.dart';
import '../../../../models/user_model.dart';
import '../../../../shared/widgets/illustration_forest_footer.dart';
import '../../../../shared/widgets/pedia_bottom_nav_bar.dart';
import '../beranda_superadmin_page.dart';
import '../../konsultasi/konsultasi_superadmin_page.dart';
import '../../riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import '../../profil/profil_superadmin_page.dart';
import 'pilih_anak_button_sheet.dart';

/// Halaman Daftar Data Pengguna untuk POV SUPERADMIN aplikasi PediaGrow.
///
/// Fitur Utama:
/// - Header fixed 56dp di bagian atas layar dengan tombol kembali & judul "Data Pengguna".
/// - Search Bar fixed di bawah header dengan sudut rounded, background abu-abu muda,
///   ikon pencarian, hint "Cari data pengguna", dan filter pencarian dinamis (real-time).
/// - Daftar card pengguna scrollable dengan efek border & shadow biru khas
///   (konsisten dengan hover card pada `lokasi_fasyankes_page.dart`).
/// - Menampilkan nama lengkap pengguna (Lato Bold 17sp, #000000) dan info status anak:
///   "[x] Anak Terdaftar" atau "Belum ada data anak" (Lato Regular 13sp, #94A3B8).
/// - Selalu clickable, memunculkan modal bottom sheet "Pilih Profil Anak" ([PilihAnakBottomSheet]).
/// - Sumber data utama dari database Firebase Firestore (`users` & `children`).
/// - Jika database kosong, tidak menampilkan card pengguna apa pun melainkan
///   menampilkan ilustrasi alam ([IllustrationForestFooter]) dan informasi ramah.
/// - Navigation Bar permanen 4 menu di Scaffold bawah ([PediaBottomNavBar]).
class DaftarPenggunaPage extends StatefulWidget {
  const DaftarPenggunaPage({super.key});

  @override
  State<DaftarPenggunaPage> createState() => _DaftarPenggunaPageState();
}

class _DaftarPenggunaPageState extends State<DaftarPenggunaPage> {
  // Controller & Focus untuk Search Bar
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  // Stream Firebase Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Warna Konsisten Sesuai Desain & lokasi_fasyankes_page.dart
  static const Color _colorPrimaryBlue = Color(0xFF2B7AE8);
  static const Color _colorTextBlack = Color(0xFF000000);
  static const Color _colorSubtitleGrey = Color(0xFF94A3B8);
  static const Color _colorCardBorder = Color(0xFF2B7AE8);
  static const Color _colorSearchBarBg = Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final text = _searchController.text.trim();
    if (_searchQuery != text) {
      setState(() {
        _searchQuery = text;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchQuery = '';
    });
  }

  /// Handler navigasi bottom bar khusus superadmin yang konsisten dengan BerandaSuperadminPage.
  /// Menggunakan FadeTransition (200ms) agar animasi identik dengan PediaBottomNavBar
  /// dan transisi beranda → profil.
  void _onNavTap(int index) {
    if (index == 0) {
      // Kembali ke Beranda Superadmin — clear seluruh stack
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const BerandaSuperadminPage(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 200),
        ),
        (route) => false,
      );
      return;
    }

    Widget targetPage;
    switch (index) {
      case 1:
        targetPage = const KonsultasiSuperadminPage();
        break;
      case 2:
        targetPage = const DaftarRiwayatKonsultasiAdminPage();
        break;
      case 3:
        targetPage = const ProfilSuperadminPage();
        break;
      default:
        return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => targetPage,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dismiss keyboard saat pengguna mengetuk di luar Search Bar
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // -------------------------------------------------------------
              // 1. HEADER FIXED (56dp) — Tidak ikut scroll
              // -------------------------------------------------------------
              _buildFixedHeader(),

              // -------------------------------------------------------------
              // 2. SEARCH BAR FIXED — Tidak ikut scroll
              // -------------------------------------------------------------
              _buildFixedSearchBar(),

              // -------------------------------------------------------------
              // 3. KONTEN UTAMA SCROLLABLE (Daftar Pengguna / Empty State)
              // -------------------------------------------------------------
              Expanded(
                child: _buildUserListStream(),
              ),
            ],
          ),
        ),
        // -----------------------------------------------------------------
        // 4. BOTTOM NAVIGATION BAR FIXED — 4 Menu Konsisten dengan Beranda Superadmin
        // -----------------------------------------------------------------
        bottomNavigationBar: _buildFixedNavBar(),
      ),
    );
  }

  // =========================================================================
  // NAVIGATION BAR — 4 tab: Beranda, Konsultasi, Riwayat Konsultasi, Profil
  // Warna #F2EDED, tinggi 68dp, Expanded layout & animasi konsisten dengan admin
  // =========================================================================
  Widget _buildFixedNavBar() {
    final navItems = [
      const _NavItem(icon: Icons.home_outlined, label: 'Beranda'),
      const _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Konsultasi'),
      const _NavItem(icon: Icons.find_in_page_outlined, label: 'Riwayat Konsultasi'),
      const _NavItem(icon: Icons.person_outline_rounded, label: 'Profil'),
    ];

    return Container(
      width: double.infinity,
      height: 68.0,
      decoration: const BoxDecoration(
        color: Color(0xFFF2EDED),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(navItems.length, (i) {
            final item = navItems[i];

            return Expanded(
              child: GestureDetector(
                onTap: () => _onNavTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 68.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 24.0,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 3.0),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 11.0,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER FIXED (Tinggi 56dp)
  // Tombol Kembali 12dp dari kiri, Judul "Data Pengguna" Lato 20sp Bold
  // ===========================================================================
  Widget _buildFixedHeader() {
    return Container(
      width: double.infinity,
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.only(left: 12, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Kembali
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back,
                color: _colorTextBlack,
                size: 24,
              ),
            ),
          ),

          // Jarak 12dp setelah tombol kembali
          const SizedBox(width: 12),

          // Judul "Data Pengguna" (Font Lato 20sp Bold, #000000)
          Expanded(
            child: Text(
              'Data Pengguna',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _colorTextBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. SEARCH BAR FIXED
  // Sudut Rounded 14dp, Background Abu-Abu Muda, Ikon Search, Dynamic Filtering
  // ===========================================================================
  Widget _buildFixedSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _colorSearchBarBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 12),
            // Ikon Pencarian
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
            const SizedBox(width: 8),

            // Input Teks Pencarian
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _colorTextBlack,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari Data Pengguna',
                  hintStyle: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Tombol Reset / Clear Pencarian
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: _clearSearch,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.cancel_rounded,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. STREAMBUILDER FIREBASE (USERS + CHILDREN)
  // Menghubungkan ke collection 'users' dan 'children' Firestore secara dinamis
  // ===========================================================================
  Widget _buildUserListStream() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore.collection('users').snapshots(),
          builder: (context, userSnapshot) {
            // State Loading
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingSkeleton();
            }

            // State Error
            if (userSnapshot.hasError) {
              return _buildErrorState(userSnapshot.error.toString());
            }

            final userDocs = userSnapshot.data?.docs ?? [];

            // -------------------------------------------------------------------
            // JIKA DATABASE KOSONG:
            // Tidak boleh menampilkan card pengguna apa pun, hanya Header,
            // Search Bar, Ilustrasi Alam & Navigation Bar
            // -------------------------------------------------------------------
            if (userDocs.isEmpty) {
              return _buildEmptyDatabaseState(constraints);
            }

            // Parsing data pengguna
            final List<UserModel> allUsers = userDocs.map((doc) {
              final data = doc.data();
              return UserModel.fromMap({...data, 'id': doc.id});
            }).toList();

            // Mengambil data seluruh anak untuk menghitung jumlah anak per user
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('children').snapshots(),
              builder: (context, childSnapshot) {
                final childDocs = childSnapshot.data?.docs ?? [];
                final Map<String, List<ChildModel>> childrenByUser = {};

                for (final doc in childDocs) {
                  final data = doc.data();
                  final child = ChildModel.fromMap({...data, 'id': doc.id});
                  final ownerId = child.ownerId;
                  if (ownerId.isNotEmpty) {
                    childrenByUser.putIfAbsent(ownerId, () => []).add(child);
                  }
                }

                // Filter pencarian berdasarkan query (nama pengguna / email)
                final filteredUsers = allUsers.where((user) {
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  final nameMatch = user.name.toLowerCase().contains(q);
                  final emailMatch = user.email.toLowerCase().contains(q);
                  return nameMatch || emailMatch;
                }).toList();

                // Jika hasil pencarian tidak ditemukan
                if (filteredUsers.isEmpty) {
                  return _buildNoSearchResultsState(constraints);
                }

                // Render Daftar Card Pengguna
                return _buildScrollableUserList(
                  filteredUsers,
                  childrenByUser,
                  constraints,
                );
              },
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 4. DAFTAR CARD PENGGUNA SCROLLABLE
  // Setiap card memiliki efek hover/border biru halus seperti fasyankes_card_item.
  // Ilustrasi pohon berada tepat di bagian paling bawah dan tidak dapat di-scroll
  // lebih lanjut ke bawah (mentok di ilustrasi).
  // ===========================================================================
  Widget _buildScrollableUserList(
    List<UserModel> users,
    Map<String, List<ChildModel>> childrenByUser,
    BoxConstraints constraints,
  ) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.maxHeight,
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              for (int i = 0; i < users.length; i++) ...[
                _buildUserCard(
                  user: users[i],
                  children: childrenByUser[users[i].id] ?? [],
                  childrenCount: (childrenByUser[users[i].id] ?? []).length,
                ),
              ],

              // Spacer fleksibel agar ilustrasi menempel tepat di dasar bila item sedikit
              const Spacer(),

              const SizedBox(height: 16),

              // Ilustrasi Footer Landscape tepat di paling bawah tanpa ruang scroll lagi
              const IllustrationForestFooter(fit: BoxFit.fitWidth),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. ITEM CARD PENGGUNA
  // - Rounded 16dp
  // - Border biru halus & subtle shadow biru konsisten dengan lokasi_fasyankes_page.dart
  // - Nama Lengkap (Lato Bold 17sp, #000000)
  // - Info Jumlah Anak (Lato Regular 13sp, #94A3B8)
  // - Icon chevron right (>)
  // - Always clickable -> memunculkan bottom sheet "Pilih Profil Anak"
  // ===========================================================================
  Widget _buildUserCard({
    required UserModel user,
    required List<ChildModel> children,
    required int childrenCount,
  }) {
    // Teks keterangan jumlah anak
    final String childInfoText = childrenCount > 0
        ? '$childrenCount Anak Terdaftar'
        : 'Belum ada data anak';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Efek border biru halus yang ada di hover card fasyankes
        border: Border.all(
          color: _colorCardBorder.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          // Shadow halus dengan rona biru elegan
          BoxShadow(
            color: _colorPrimaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: _colorPrimaryBlue.withValues(alpha: 0.08),
          highlightColor: _colorPrimaryBlue.withValues(alpha: 0.04),
          onTap: () {
            // Memunculkan Modal Bottom Sheet "Pilih Profil Anak" dari file terpisah
            PilihAnakBottomSheet.showForDetail(
              context,
              user: user,
              children: children,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Info Pengguna (Nama & Status Anak)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nama Pengguna (Lato Bold, #000000)
                      Text(
                        user.name.isNotEmpty ? user.name : 'Pengguna',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _colorTextBlack,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Status Jumlah Anak (Lato Regular, warna abu-abu #94A3B8)
                      Text(
                        childInfoText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: _colorSubtitleGrey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Button Chevron Right (>) Penanda Klik
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 26,
                  color: _colorTextBlack,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 6. EMPTY DATABASE STATE
  // Apabila belum terdapat daftar pengguna pada database (database kosong)
  // Tidak menampilkan card pengguna apa pun, ilustrasi alam berada di paling bawah.
  // ===========================================================================
  Widget _buildEmptyDatabaseState(BoxConstraints constraints) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_off_outlined,
                            size: 36,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Data Pengguna',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Data pengguna yang terdaftar di aplikasi akan muncul di sini secara otomatis.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Ilustrasi Landscape Pepohonan konsisten dengan Beranda (di paling bawah)
              const IllustrationForestFooter(fit: BoxFit.fitWidth),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 7. HASIL PENCARIAN KOSONG STATE
  // ===========================================================================
  Widget _buildNoSearchResultsState(BoxConstraints constraints) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Pengguna Tidak Ditemukan',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tidak ditemukan data pengguna dengan kata kunci "$_searchQuery".',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const IllustrationForestFooter(fit: BoxFit.fitWidth),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 8. SKELETON / LOADING STATE
  // ===========================================================================
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 160,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 9. ERROR STATE
  // ===========================================================================
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            Text(
              'Gagal Memuat Data Pengguna',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Terjadi kendala saat menghubungkan ke database: $error',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Coba Lagi',
                style: GoogleFonts.lato(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorPrimaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Helper class data item navigasi bottom bar
// =============================================================================
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
