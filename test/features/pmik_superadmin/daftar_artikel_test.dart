import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/models/artikel_model.dart';
import 'package:pediagrow/pmik_superadmin/kelola_artikel/daftar_artikel_page.dart';
import 'package:pediagrow/pmik_superadmin/kelola_artikel/form_artikel_page.dart';
import 'package:pediagrow/shared/widgets/pedia_bottom_nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DaftarArtikelPage Widget Tests', () {
    testWidgets('Merender Header, Search Bar, Card Artikel, Tombol Aksi, dan NavBar', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: DaftarArtikelPage()),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi Header
      expect(find.text('Daftar Artikel'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // 2. Verifikasi Search Bar
      expect(find.text('Cari Artikel'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      // 3. Verifikasi Kartu Artikel
      expect(find.text('Stunting'), findsWidgets);
      expect(find.byIcon(Icons.delete_outline_rounded), findsWidgets);
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);

      // 4. Verifikasi Bottom Navigation Bar
      expect(find.byType(PediaBottomNavBar), findsOneWidget);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Konsultasi'), findsOneWidget);
      expect(find.text('Riwayat Konsultasi'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('Responsif pada layar kecil Android compact tanpa overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 533);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: DaftarArtikelPage()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Daftar Artikel'), findsOneWidget);
    });

    testWidgets('Filter live pencarian menyaring artikel berdasarkan judul atau tag', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: DaftarArtikelPage()),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Cari artikel dengan kata "Wasting"
      await tester.enterText(searchField, 'Wasting');
      await tester.pumpAndSettle();

      expect(find.textContaining('Wasting'), findsWidgets);

      // Hapus pencarian
      final clearButton = find.byIcon(Icons.close_rounded);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Dialog konfirmasi hapus muncul dengan judul Hapus Data dan tombol Ya/Tidak', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: DaftarArtikelPage()),
      );
      await tester.pumpAndSettle();

      final deleteButtons = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteButtons, findsWidgets);

      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Verifikasi judul dan teks dialog konfirmasi
      expect(find.text('Hapus Data'), findsOneWidget);
      expect(
        find.text(
          'Mohon pastikan ulang sebelum menghapus Artikel. Apakah anda yakin ingin menghapus?',
        ),
        findsOneWidget,
      );
      expect(find.text('Ya'), findsOneWidget);
      expect(find.text('Tidak'), findsOneWidget);

      // Tekan tombol Tidak (batal)
      await tester.tap(find.text('Tidak'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Data'), findsNothing);
    });
  });

  group('FormArtikelPage Widget Tests (Mode Tambah & Mode Ubah)', () {
    testWidgets('Mode Tambah: merender form kosong dan header Tambah Artikel', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: FormArtikelPage()),
      );
      await tester.pumpAndSettle();

      // Header Tambah Artikel
      expect(find.text('Tambah Artikel'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Area Foto default kosong
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.text('Ubah Foto'), findsOneWidget);

      // Input fields
      expect(find.text('Isi Judul'), findsOneWidget);
      expect(find.text('Judul Artikel'), findsOneWidget);
      expect(find.text('Nama Penulis'), findsOneWidget);
      expect(find.text('Isi Artikel'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
    });

    testWidgets('Mode Ubah: merender data artikel terpilih secara otomatis', (
      WidgetTester tester,
    ) async {
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
      );

      await tester.pumpWidget(
        const MaterialApp(home: FormArtikelPage(artikel: sampleArtikel)),
      );
      await tester.pumpAndSettle();

      // 1. Header Ubah Artikel
      expect(find.text('Ubah Artikel'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // 2. Foto & Tombol Ubah Foto
      expect(find.text('Ubah Foto'), findsOneWidget);

      // 3. Tanggal Terisi Otomatis
      expect(find.text('26 Agustus 2026'), findsOneWidget);

      // 4. Isi Judul & Penulis Terisi Otomatis
      expect(find.text('Stunting'), findsOneWidget);
      expect(find.text('Pego'), findsOneWidget);

      // 5. Isi Artikel Terisi
      expect(find.textContaining('Deskripsi'), findsWidgets);
      expect(find.text('Simpan'), findsOneWidget);
    });

    testWidgets('Validasi form mencegah penyimpanan jika judul atau isi kosong', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: FormArtikelPage()),
      );
      await tester.pumpAndSettle();

      // Tekan tombol Simpan tanpa mengisi
      final simpanButton = find.text('Simpan');
      await tester.tap(simpanButton);
      await tester.pumpAndSettle();

      expect(find.text('Judul artikel wajib diisi'), findsOneWidget);
      expect(find.text('Isi artikel wajib diisi'), findsOneWidget);
    });

    testWidgets('Responsif pada layar kecil Android compact tanpa overflow', (
      WidgetTester tester,
    ) async {
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
    });
  });
}
