import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/child_model.dart';
import '../../../../models/user_model.dart';
import '../../../../shared/widgets/child_avatar.dart';
import '../../../../shared/widgets/illustration_forest_footer.dart';
import '../../../../shared/widgets/pedia_bottom_nav_bar.dart';
import '../../../../core/services/staff_auth_service.dart';
import '../../../../models/staff_account_model.dart';
import '../../../dokter/beranda/beranda_dokter_page.dart';
import '../../../dokter/konsultasi/konsultasi_dokter_page.dart';
import '../../../dokter/profil_dokter_page.dart';
import '../beranda_pmik_page.dart';
import '../../konsultasi/konsultasi_pmik_admin_page.dart';
import '../../../pmik_superadmin/riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import '../../profil_pmik_page.dart';
import 'detail_anak_page.dart';
import 'pilih_anak_button_sheet.dart';

/// Halaman Daftar Data Pasien Anak untuk POV PMIK ADMIN aplikasi PediaGrow.
///
/// Logika Baru:
/// - List menampilkan seluruh daftar anak yang terdaftar di aplikasi (tersimpan di Firestore 'children').
/// - Setiap card anak menampilkan Avatar, Nama Anak, Usia, dan Nama Orang Tua.
/// - Saat card anak diklik, langsung membuka [DetailAnakPage].
class DaftarPenggunaPage extends StatefulWidget {
  const DaftarPenggunaPage({super.key});

  @override
  State<DaftarPenggunaPage> createState() => _DaftarPenggunaPageState();
}

class _DaftarPenggunaPageState extends State<DaftarPenggunaPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Color _colorPrimaryBlue = Color(0xFF2B7AE8);
  static const Color _colorTextBlack = Color(0xFF000000);
  static const Color _colorSubtitleGrey = Color(0xFF8696A0);
  static const Color _colorCardBorder = Color(0xFF2B7AE8);
  static const Color _colorSearchBarBg = Color(0xFFE9EDEF);

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

  void _onNavTap(int index) {
    final isDokter = StaffAuthService().currentStaff?.role == StaffRole.dokter;

    if (index == 0) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, _, _) =>
              isDokter ? const BerandaDokterPage() : const BerandaPmikPage(),
          transitionsBuilder: (_, animation, _, child) =>
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
        targetPage = isDokter
            ? const KonsultasiDokterPage()
            : const KonsultasiPmikAdminPage();
        break;
      case 2:
        targetPage = const DaftarRiwayatKonsultasiAdminPage();
        break;
      case 3:
        targetPage =
            isDokter ? const ProfilDokterPage() : const ProfilPmikPage();
        break;
      default:
        return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => targetPage,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1014) : Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildFixedHeader(),
            _buildFixedSearchBar(),
            Expanded(child: _buildChildListStream()),
          ],
        ),
      ),
      bottomNavigationBar: PediaBottomNavBar(
        selectedIndex: -1,
        onNavTap: _onNavTap,
      ),
    );
  }

  Widget _buildFixedHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 56,
      color: isDark ? const Color(0xFF0B1014) : Colors.white,
      padding: const EdgeInsets.only(left: 12, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back,
                color: isDark ? const Color(0xFFE9EDEF) : Colors.black,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Data Pasien Anak',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2228) : _colorSearchBarBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.search_rounded,
              color: isDark ? const Color(0xFF8696A0) : const Color(0xFF8696A0),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari data anak atau orang tua',
                  hintStyle: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF8696A0),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: _clearSearch,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.close_rounded,
                    color: isDark ? const Color(0xFF8696A0) : const Color(0xFF8696A0),
                    size: 20,
                  ),
                ),
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildChildListStream() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore.collection('children').snapshots(),
          builder: (context, childSnapshot) {
            if (childSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingSkeleton();
            }

            if (childSnapshot.hasError) {
              return _buildErrorState(childSnapshot.error.toString());
            }

            final childDocs = childSnapshot.data?.docs ?? [];

            if (childDocs.isEmpty) {
              return _buildEmptyDatabaseState(constraints);
            }

            final List<ChildModel> allChildren = childDocs.map((doc) {
              final data = doc.data();
              return ChildModel.fromMap({...data, 'id': doc.id});
            }).toList();

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, userSnapshot) {
                final userDocs = userSnapshot.data?.docs ?? [];
                final Map<String, UserModel> usersById = {};

                for (final doc in userDocs) {
                  final data = doc.data();
                  final user = UserModel.fromMap({...data, 'id': doc.id});
                  usersById[user.id] = user;
                  if (user.email.isNotEmpty) {
                    usersById[user.email.toLowerCase()] = user;
                  }
                }

                final filteredChildren = allChildren.where((child) {
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  final childMatch = child.name.toLowerCase().contains(q);
                  final parentUser = usersById[child.ownerId] ??
                      (child.ownerId.isNotEmpty
                          ? usersById[child.ownerId.toLowerCase()]
                          : null);
                  final parentMatch =
                      parentUser?.name.toLowerCase().contains(q) == true;
                  return childMatch || parentMatch;
                }).toList();

                if (filteredChildren.isEmpty) {
                  return _buildNoSearchResultsState(constraints);
                }

                return _buildScrollableChildList(
                  filteredChildren,
                  usersById,
                  constraints,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildScrollableChildList(
    List<ChildModel> children,
    Map<String, UserModel> usersById,
    BoxConstraints constraints,
  ) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              for (int i = 0; i < children.length; i++) ...[
                _buildChildCard(
                  child: children[i],
                  parentUser: usersById[children[i].ownerId] ??
                      (children[i].ownerId.isNotEmpty
                          ? usersById[children[i].ownerId.toLowerCase()]
                          : null),
                ),
              ],
              const Spacer(),
              const SizedBox(height: 16),
              const IllustrationForestFooter(fit: BoxFit.fitWidth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard({
    required ChildModel child,
    required UserModel? parentUser,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parentName = parentUser?.name.isNotEmpty == true
        ? parentUser!.name
        : 'Orang tua tidak diketahui';

    String usiaText = child.ageDescription;
    if (child.birthDate != null) {
      usiaText = calculateAge(child.birthDate!).formatted;
    }
    if (usiaText.isEmpty) {
      usiaText = '-';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2C363D)
              : _colorCardBorder.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
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
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DetailAnakPage(
                  child: child,
                  user: parentUser,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Anak
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ChildAvatar.bgColorFor(gender: child.gender),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: child.photoUrl != null && child.photoUrl!.isNotEmpty
                      ? Image.network(
                          child.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ChildAvatar(
                            gender: child.gender,
                            size: 48,
                          ),
                        )
                      : ChildAvatar(
                          gender: child.gender,
                          size: 48,
                        ),
                ),
                const SizedBox(width: 14),

                // Info Anak
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nama Anak
                      Text(
                        child.name.isNotEmpty ? child.name : 'Anak Pasien',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Usia Anak
                      Text(
                        'Usia: $usiaText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF8696A0)
                              : const Color(0xFF64748B),
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Orang Tua
                      Text(
                        'Orang Tua: $parentName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF8696A0) : _colorSubtitleGrey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Chevron Right
                Icon(
                  Icons.chevron_right_rounded,
                  size: 26,
                  color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDatabaseState(BoxConstraints constraints) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                            color: isDark
                                ? const Color(0xFF242E35)
                                : const Color(0xFFE9EDEF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2C363D)
                                  : const Color(0xFFE9EDEF),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.child_care_rounded,
                            size: 36,
                            color: Color(0xFF8696A0),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Data Pasien Anak',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFE9EDEF)
                                : const Color(0xFF1A2228),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Data anak yang terdaftar di aplikasi akan muncul di sini secara otomatis.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: isDark
                                ? const Color(0xFF8696A0)
                                : const Color(0xFF667781),
                            height: 1.4,
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

  Widget _buildNoSearchResultsState(BoxConstraints constraints) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                          color: Color(0xFF8696A0),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Data Anak Tidak Ditemukan',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFE9EDEF)
                                : const Color(0xFF1A2228),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tidak ditemukan data anak dengan kata kunci "$_searchQuery".',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF8696A0)
                                : const Color(0xFF667781),
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

  Widget _buildLoadingSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2228) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2C363D)
                  : const Color(0xFFE9EDEF),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF242E35)
                      : const Color(0xFFE9EDEF),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF242E35)
                            : const Color(0xFFE9EDEF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF242E35)
                            : const Color(0xFFE9EDEF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFE53935),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Gagal Memuat Data Pasien Anak',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: const Color(0xFF8696A0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
