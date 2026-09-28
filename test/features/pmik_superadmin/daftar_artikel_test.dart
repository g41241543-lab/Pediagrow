import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/models/artikel_model.dart';
import 'package:pediagrow/pmik_superadmin/kelola_artikel/daftar_artikel_page.dart';
import 'package:pediagrow/pmik_superadmin/kelola_artikel/form_artikel_page.dart';
import 'package:pediagrow/shared/widgets/illustration_forest_footer.dart';
import 'package:pediagrow/shared/widgets/pedia_bottom_nav_bar.dart';

// ---------------------------------------------------------------------------
// Catatan Testing:
// DaftarArtikelPage dan FormArtikelPage membaca/menulis data ke Firebase Firestore
// koleksi `artikel_kesehatan` via ArtikelService.
//
// Test di sini hanya memverifikasi STRUKTUR UI (label, ikon, komponen) karena:
// 1. Widget test tidak terhubung ke Firebase secara langsung.
// 2. DaftarArtikelPage memiliki fallback ke ArtikelModel.seedArticles saat
//    koneksi Firebase gagal, sehingga kartu artikel tetap muncul.
// 3. FormArtikelPage tidak membutuhkan Firebase untuk render form kosong atau
//    pra-isi data dari ArtikelModel yang sudah diterima via parameter.
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // 1. DaftarArtikelPage
  // ---------------------------------------------------------------------------
  group('DaftarArtikelPage Widget Tests', () {
    testWidgets(
      'Merender Header, Search Bar, tombol tambah, dan NavBar',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(home: DaftarArtikelPage()),
        );
        // Tunggu fallback seedArticles dimuat setelah Firebase error
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // 1. Header
        expect(find.text('Daftar Artikel'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);

        // 2. Search Bar (icon = Icons.search, bukan Icons.search_rounded)
        expect(find.text('Cari Artikel'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);

        // 3. Ilustrasi Forest Footer di atas Bottom Nav Bar
        expect(find.byType(IllustrationForestFooter), findsOneWidget);

        // 4. Bottom Navigation Bar
        expect(find.byType(PediaBottomNavBar), findsOneWidget);
        expect(find.text('Beranda'), findsOneWidget);
        expect(find.text('Konsultasi'), findsOneWidget);
        expect(find.text('Riwayat Konsultasi'), findsOneWidget);
        expect(find.text('Profil'), findsOneWidget);
      },
    );

    testWidgets(
      'Kartu artikel dan tombol hapus/edit muncul setelah data dimuat',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(home: DaftarArtikelPage()),
        );
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Fallback ke seedArticles — artikel "Stunting" harus muncul
        expect(find.textContaining('Stunting'), findsWidgets);
        expect(find.byIcon(Icons.delete_outline_rounded), findsWidgets);
        expect(find.byIcon(Icons.edit_outlined), findsWidgets);
      },
    );

    testWidgets(
      'Responsif pada layar kecil Android compact tanpa overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 533);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(home: DaftarArtikelPage()),
        );
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(tester.takeException(), isNull);
        expect(find.text('Daftar Artikel'), findsOneWidget);
      },
    );

    testWidgets(
      'Filter live pencarian menyaring artikel berdasarkan kata kunci',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(home: DaftarArtikelPage()),
        );
        await tester.pumpAndSettle(const Duration(seconds: 5));

        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);

        await tester.enterText(searchField, 'Wasting');
        await tester.pumpAndSettle();

        expect(find.textContaining('Wasting'), findsWidgets);

        // Clear pencarian
        final clearButton = find.byIcon(Icons.close_rounded);
        if (clearButton.evaluate().isNotEmpty) {
          await tester.tap(clearButton);
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets(
      'Dialog konfirmasi hapus muncul dengan judul Hapus Data dan tombol Ya/Tidak',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(home: DaftarArtikelPage()),
        );
        await tester.pumpAndSettle(const Duration(seconds: 5));

        final deleteButtons = find.byIcon(Icons.delete_outline_rounded);
        expect(deleteButtons, findsWidgets);

        await tester.tap(deleteButtons.first);
        await tester.pumpAndSettle();

        // Verifikasi judul dan teks dialog
        expect(find.text('Hapus Data'), findsOneWidget);
        expect(
          find.text(
            'Mohon pastikan ulang sebelum menghapus Artikel. Apakah anda yakin ingin menghapus?',
          ),
          findsOneWidget,
        );
        expect(find.text('Ya'), findsOneWidget);
        expect(find.text('Tidak'), findsOneWidget);

        // Tekan Tidak — dialog harus tertutup
        await tester.tap(find.text('Tidak'));
        await tester.pumpAndSettle();
        expect(find.text('Hapus Data'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 2. FormArtikelPage
  // ---------------------------------------------------------------------------
  group('FormArtikelPage Widget Tests (Mode Tambah & Mode Ubah)', () {
    testWidgets(
      'Mode Tambah: merender header "Tambah Artikel" dan form kosong',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(home: FormArtikelPage()),
        );
        await tester.pumpAndSettle();

        // Header
        expect(find.text('Tambah Artikel'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        // Area foto placeholder
        expect(find.byIcon(Icons.image_outlined), findsOneWidget);

        // Tombol Ubah Foto
        expect(find.text('Ubah Foto'), findsOneWidget);

        // Label field
        expect(find.text('Isi Judul'), findsOneWidget);
        expect(find.text('Nama Penulis'), findsOneWidget);
        expect(find.text('Isi Artikel'), findsOneWidget);

        // Tombol simpan
        expect(find.text('Simpan'), findsOneWidget);
      },
    );

    testWidgets(
      'Mode Ubah: header "Ubah Artikel" dan data artikel terpilih terisi otomatis',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const sampleArtikel = ArtikelModel(
          id: 'artikel_1',
          judul: 'Stunting',
          penulis: 'Pego',
          tanggal: '26 Agustus 2026',
          assetImagePath: 'assets/images/artikel_stunting.jpg',
          deskripsi: 'Deskripsi uji coba stunting.',
          pengertian: 'Pengertian uji coba stunting.',
          isiLengkap: 'Isi lengkap stunting untuk test.',
        );

        await tester.pumpWidget(
          const MaterialApp(home: FormArtikelPage(artikel: sampleArtikel)),
        );
        await tester.pumpAndSettle();

        // Header mode ubah
        expect(find.text('Ubah Artikel'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        // Tombol Ubah Foto
        expect(find.text('Ubah Foto'), findsOneWidget);

        // Tanggal terisi otomatis dari artikel
        expect(find.text('26 Agustus 2026'), findsOneWidget);

        // Judul dan penulis terisi
        expect(find.text('Stunting'), findsOneWidget);
        expect(find.text('Pego'), findsOneWidget);

        // Tombol simpan
        expect(find.text('Simpan'), findsOneWidget);
      },
    );

    testWidgets(
      'Validasi form memunculkan pesan error jika judul atau isi kosong',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(home: FormArtikelPage()),
        );
        await tester.pumpAndSettle();

        // Tekan Simpan tanpa mengisi field apa pun
        await tester.tap(find.text('Simpan'));
        await tester.pumpAndSettle();

        // Pesan error sesuai string di _handleSimpan
        expect(find.text('Judul artikel wajib diisi'), findsOneWidget);
        expect(find.text('Isi artikel wajib diisi'), findsOneWidget);
      },
    );

    testWidgets(
      'Responsif pada layar kecil Android compact tanpa overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 533);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const sampleArtikel = ArtikelModel(
          id: 'artikel_1',
          judul: 'Stunting',
          penulis: 'Pego',
          tanggal: '26 Agustus 2026',
          assetImagePath: 'assets/images/artikel_stunting.jpg',
        );

        await tester.pumpWidget(
          const MaterialApp(home: FormArtikelPage(artikel: sampleArtikel)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Ubah Artikel'), findsOneWidget);
      },
    );

    testWidgets(
      'Menampilkan toolbar rich text (Paragraph, B, I, U, Lists, Undo, Redo) dan memformat teks saat ditekan',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(home: FormArtikelPage()),
        );
        await tester.pumpAndSettle();

        // 1. Verifikasi elemen toolbar
        expect(find.text('Paragraph'), findsOneWidget);
        expect(find.text('B'), findsOneWidget);
        expect(find.text('I'), findsOneWidget);
        expect(find.text('U'), findsOneWidget);
        expect(find.byIcon(Icons.format_list_bulleted_rounded), findsOneWidget);
        expect(find.byIcon(Icons.format_list_numbered_rounded), findsOneWidget);
        expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
        expect(find.byIcon(Icons.redo_rounded), findsOneWidget);

        // 2. Ketuk tombol Bold (B) — menambahkan placeholder bold
        await tester.tap(find.text('B'));
        await tester.pumpAndSettle();
        expect(find.textContaining('teks tebal'), findsWidgets);

        // 3. Ketuk tombol Italic (I)
        await tester.tap(find.text('I'));
        await tester.pumpAndSettle();
        expect(find.textContaining('teks miring'), findsWidgets);

        // 4. Ketuk tombol Underline (U)
        await tester.tap(find.text('U'));
        await tester.pumpAndSettle();
        expect(find.textContaining('teks bergaris bawah'), findsWidgets);
      },
    );
  });
}
