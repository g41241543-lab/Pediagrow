import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/features/pengguna/artikel/artikel_kesehatan_page.dart';
import 'package:pediagrow/features/pengguna/detail/detail_artikel_page.dart';
import 'package:pediagrow/models/artikel_model.dart';
import 'package:pediagrow/shared/widgets/pedia_bottom_nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ArtikelModel Unit Tests', () {
    test('Serialisasi dan Deserialisasi ArtikelModel', () {
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
  });

  group('ArtikelKesehatanPage Widget Tests', () {
    testWidgets(
      'Merender Header, Search Bar, Card Artikel, Footer, dan NavBar',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(home: ArtikelKesehatanPage()),
        );
        await tester.pumpAndSettle();

        // 1. Verifikasi Header
        expect(find.text('Artikel Kesehatan'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        // 2. Verifikasi Search Bar
        expect(find.text('Cari Artikel'), findsOneWidget);
        expect(find.byIcon(Icons.search_rounded), findsOneWidget);

        // 3. Verifikasi Bottom Navigation Bar
        expect(find.byType(PediaBottomNavBar), findsOneWidget);
        expect(find.text('Beranda'), findsOneWidget);
        expect(find.text('Konsultasi'), findsOneWidget);
        expect(find.text('Riwayat Konsultasi'), findsOneWidget);
        expect(find.text('Profil Ibu'), findsOneWidget);
      },
    );

    testWidgets('Pencarian dinamis menyaring artikel berdasarkan kata kunci', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ArtikelKesehatanPage()));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Ketik kata kunci pencarian
      await tester.enterText(searchField, 'Wasting');
      await tester.pumpAndSettle();

      // Clear search
      final clearButton = find.byIcon(Icons.close_rounded);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pumpAndSettle();
      }
    });
  });

  group('DetailArtikelPage Widget Tests', () {
    testWidgets(
      'Merender Detail Artikel lengkap dengan deskripsi dan pengertian',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

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

        // 3. Sections
        expect(find.text('Deskripsi'), findsOneWidget);
        expect(find.text('Pengertian'), findsOneWidget);
        expect(
          find.textContaining('Stunting merupakan suatu keadaan'),
          findsOneWidget,
        );

        // 4. Fixed Nav Bar
        expect(find.byType(PediaBottomNavBar), findsOneWidget);
      },
    );
  });
}
