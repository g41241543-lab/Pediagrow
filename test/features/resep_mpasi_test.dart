import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/features/pengguna/mpasi/detail_resep_page.dart';
import 'package:pediagrow/models/resep_mpasi_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ResepMpasiModel & PMIK Superadmin Default Data Tests', () {
    test('Semua 7 Resep Default Kemenkes RI Lengkap dan Utuh', () {
      final recipes = ResepMpasiModel.defaultKemenkesRecipes;
      expect(recipes.length, 7);

      for (final recipe in recipes) {
        // Validasi judul dan kategori
        expect(recipe.judul.isNotEmpty, true);
        expect(recipe.kategoriUsia.isNotEmpty, true);
        expect(recipe.tanggal.isNotEmpty, true);

        // Validasi kelengkapan bahan dan cara membuat
        expect(
          recipe.bahan.isNotEmpty,
          true,
          reason: '${recipe.judul} harus memiliki daftar bahan',
        );
        expect(
          recipe.caraMembuat.isNotEmpty,
          true,
          reason: '${recipe.judul} harus memiliki langkah cara membuat',
        );

        // Validasi nilai nutrisi terisi
        expect((recipe.energiKkal ?? 0) > 0, true);
        expect((recipe.proteinGr ?? 0) > 0, true);
        expect((recipe.lemakGr ?? 0) > 0, true);
        expect((recipe.porsi ?? 0) > 0, true);
      }
    });

    test('Verifikasi Khusus Resep Ke-5: Mie Kukus Telur Puyuh', () {
      final recipe5 = ResepMpasiModel.defaultKemenkesRecipes.firstWhere(
        (r) => r.id == 5,
      );

      expect(recipe5.judul, 'Mie Kukus Telur Puyuh');
      expect(recipe5.kategoriUsia, '9-11 bulan');
      expect(recipe5.porsi, 2);
      expect(recipe5.energiKkal, 185.0);
      expect(recipe5.proteinGr, 10.0);
      expect(recipe5.lemakGr, 7.0);

      // Pastikan bahan memuat bahan utama mie dan telur puyuh
      final bahanText = recipe5.bahan.join(' ').toLowerCase();
      expect(bahanText.contains('mie'), true);
      expect(bahanText.contains('telur puyuh'), true);
      expect(bahanText.contains('wortel'), true);
      expect(bahanText.contains('keju'), true);

      // Pastikan langkah pembuatan lengkap (minimal 5 langkah)
      expect(recipe5.caraMembuat.length >= 5, true);
    });

    test('Serialisasi dan Deserialisasi ResepMpasiModel', () {
      final sample = ResepMpasiModel.defaultKemenkesRecipes[4]; // Resep 5
      final map = sample.toMap();

      expect(map['id'], 5);
      expect(map['judul'], 'Mie Kukus Telur Puyuh');
      expect(map['kategori_usia'], '9-11 bulan');

      final deserialized = ResepMpasiModel.fromMap(map);
      expect(deserialized.id, 5);
      expect(deserialized.judul, 'Mie Kukus Telur Puyuh');
      expect(deserialized.bahan.length, sample.bahan.length);
      expect(deserialized.caraMembuat.length, sample.caraMembuat.length);
      expect(deserialized.buah.length, sample.buah.length);
    });

    test('ResepMpasi.fromModel menghasilkan objek detail yang valid', () {
      final sample = ResepMpasiModel.defaultKemenkesRecipes[4];
      final detail = ResepMpasi.fromModel(sample);

      expect(detail.id, '5');
      expect(detail.title, 'Mie Kukus Telur Puyuh');
      expect(detail.author, 'Pego');
      expect(detail.category, '9-11 bulan');
      expect(detail.energi, 185.0);
      expect(detail.protein, 10.0);
      expect(detail.lemak, 7.0);
      expect(detail.porsi, 2);
      expect(detail.bahan.isNotEmpty, true);
      expect(detail.caraMembuat.isNotEmpty, true);
    });
  });

  group('DetailResepPage Widget Tests', () {
    testWidgets('Merender Resep Ke-5 (Mie Kukus Telur Puyuh) Secara Lengkap', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final recipe5 = ResepMpasiModel.defaultKemenkesRecipes[4];

      await tester.pumpWidget(
        MaterialApp(
          home: DetailResepPage(resepModel: recipe5),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header
      expect(find.text('Detail Resep'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // 2. Metadata Utama
      expect(find.text('Mie Kukus Telur Puyuh'), findsOneWidget);
      expect(find.text('26 Agustus 2026'), findsOneWidget);
      expect(find.text('Ditulis oleh Pego'), findsOneWidget);

      // 3. Nutrisi
      expect(find.text('Energi'), findsOneWidget);
      expect(find.text('185 kkal'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('10.0 gr'), findsOneWidget);
      expect(find.text('Lemak'), findsOneWidget);
      expect(find.text('7.0 gr'), findsOneWidget);
      expect(find.text('Porsi'), findsOneWidget);
      expect(find.text('2 porsi'), findsOneWidget);

      // 4. Section Bahan dan Cara Membuat
      expect(find.text('Bahan'), findsOneWidget);
      expect(find.text('Buah'), findsOneWidget);
      expect(find.text('Cara Membuat'), findsOneWidget);

      // Verifikasi cuplikan teks bahan dan langkah
      expect(find.textContaining('mie kering khusus balita'), findsOneWidget);
      expect(find.textContaining('telur puyuh'), findsWidgets);
    });

    testWidgets('Merender Empty State saat data resep null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DetailResepPage(resep: null),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Data resep tidak ditemukan'), findsOneWidget);
      expect(
        find.textContaining('Silakan kembali ke daftar resep'),
        findsOneWidget,
      );
    });
  });
}
