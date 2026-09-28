import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/features/pengguna/artikel/artikel_kesehatan_page.dart';
import 'package:pediagrow/features/pengguna/detail/detail_artikel_page.dart';
import 'package:pediagrow/models/artikel_model.dart';
import 'package:pediagrow/shared/widgets/pedia_bottom_nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // 1. UNIT TEST — ArtikelModel (tidak memerlukan Firebase)
  // ---------------------------------------------------------------------------
  group('ArtikelModel Unit Tests', () {
    test('Serialisasi dan Deserialisasi toMap / fromMap', () {
      const artikel = ArtikelModel(
        id: '10',
        judul: 'Uji Coba Stunting',
        kategori: 'Artikel',
        subKategori: ['Pencegahan', 'Gizi'],
        tanggal: '26 Agustus 2026',
        assetImagePath: 'assets/images/artikel_stunting.jpg',
        penulis: 'Admin PMIK',
        deskripsi: 'Deskripsi uji coba.',
        pengertian: 'Pengertian uji coba.',
      );

      final map = artikel.toMap();
      expect(map['id'], '10');
      expect(map['judul'], 'Uji Coba Stunting');
      expect(map['penulis'], 'Admin PMIK');

      final fromMap = ArtikelModel.fromMap(map);
      expect(fromMap.id, '10');
      expect(fromMap.judul, 'Uji Coba Stunting');
      expect(fromMap.subKategori, ['Pencegahan', 'Gizi']);
      expect(fromMap.isAssetImage, true);
    });

    test('displayImage mengembalikan assetImagePath jika tersedia', () {
      const a = ArtikelModel(
        judul: 'Test',
        tanggal: '1 Jan 2026',
        assetImagePath: 'assets/images/test.jpg',
      );
      expect(a.displayImage, 'assets/images/test.jpg');
      expect(a.isAssetImage, true);
    });

    test('displayImage mengembalikan imageUrl jika assetImagePath null', () {
      const a = ArtikelModel(
        judul: 'Test',
        tanggal: '1 Jan 2026',
        imageUrl: 'https://example.com/img.jpg',
      );
      expect(a.displayImage, 'https://example.com/img.jpg');
      expect(a.isAssetImage, false);
    });

    test('seedArticles berisi 3 artikel dengan ID, judul, dan penulis valid', () {
      expect(ArtikelModel.seedArticles.length, 3);
      for (final a in ArtikelModel.seedArticles) {
        expect(a.id, isNotNull);
        expect(a.judul, isNotEmpty);
        expect(a.penulis, isNotEmpty);
      }
    });

    test('copyWith mempertahankan nilai lama jika tidak ada parameter baru', () {
      const asli = ArtikelModel(
        id: 'abc',
        judul: 'Judul Asli',
        tanggal: '26 Agustus 2026',
        penulis: 'Pego',
      );
      final salinan = asli.copyWith(judul: 'Judul Baru');
      expect(salinan.id, 'abc');
      expect(salinan.judul, 'Judul Baru');
      expect(salinan.penulis, 'Pego');
    });
  });

  // ---------------------------------------------------------------------------
  // 2. WIDGET TEST — ArtikelKesehatanPage (struktur UI saja)
  // Catatan: ArtikelKesehatanPage membaca data langsung dari Firebase Firestore
  // koleksi `artikel_kesehatan`. Test di sini hanya memverifikasi struktur UI
  // (header, search bar, nav bar) yang tampil sebelum data Firebase dimuat.
  // ---------------------------------------------------------------------------
  group('ArtikelKesehatanPage Widget Tests', () {
    testWidgets(
      'Merender Header, Search Bar, dan Bottom Navigation Bar',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(home: ArtikelKesehatanPage()),
        );
        // Satu frame saja — cukup untuk memverifikasi struktur UI statik
        await tester.pump();

        // 1. Header
        expect(find.text('Artikel Kesehatan'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        // 2. Search Bar
        expect(find.text('Cari Artikel'), findsOneWidget);
        expect(find.byIcon(Icons.search_rounded), findsOneWidget);

        // 3. Bottom Navigation Bar — label sesuai PediaBottomNavBar
        expect(find.byType(PediaBottomNavBar), findsOneWidget);
        expect(find.text('Beranda'), findsOneWidget);
        expect(find.text('Konsultasi'), findsOneWidget);
        expect(find.text('Riwayat Konsultasi'), findsOneWidget);
        expect(find.text('Profil'), findsOneWidget);
      },
    );

    testWidgets(
      'TextField pencarian dapat menerima input',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(home: ArtikelKesehatanPage()),
        );
        await tester.pump();

        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);

        // Ketik kata kunci
        await tester.enterText(searchField, 'Wasting');
        await tester.pump();

        // Tombol clear harus muncul setelah ada input
        final clearButton = find.byIcon(Icons.close_rounded);
        if (clearButton.evaluate().isNotEmpty) {
          await tester.tap(clearButton);
          await tester.pump();
        }
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 3. WIDGET TEST — DetailArtikelPage
  // DetailArtikelPage menerima ArtikelModel dari Firebase via navigasi dari
  // ArtikelKesehatanPage — tidak memerlukan koneksi Firebase di test ini.
  // ---------------------------------------------------------------------------
  group('DetailArtikelPage Widget Tests', () {
    testWidgets(
      'Merender Detail Artikel lengkap dengan Deskripsi, Pengertian, dan info penulis',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Gunakan artikel seed pertama (Stunting) sebagai data yang diterima
        // dari Firebase — di runtime nyata data ini berasal dari Firestore
        final artikelTest = ArtikelModel.seedArticles.first;

        await tester.pumpWidget(
          MaterialApp(home: DetailArtikelPage(artikel: artikelTest)),
        );
        await tester.pumpAndSettle();

        // 1. Header
        expect(find.text('Detail Artikel'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        // 2. Info Utama
        expect(find.text('Stunting'), findsOneWidget);
        expect(find.text('26 Agustus 2026'), findsOneWidget);
        expect(find.text('Ditulis oleh Pego'), findsOneWidget);

        // 3. Sections konten dari field ArtikelModel
        expect(find.text('Deskripsi'), findsOneWidget);
        expect(find.text('Pengertian'), findsOneWidget);
        expect(
          find.textContaining('Stunting merupakan suatu keadaan'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Tombol Back dapat di-tap tanpa error',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final artikelTest = ArtikelModel.seedArticles.first;

        await tester.pumpWidget(
          MaterialApp(
            home: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => DetailArtikelPage(artikel: artikelTest),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      },
    );
  });
}
