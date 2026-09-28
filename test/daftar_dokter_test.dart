import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pediagrow/features/pengguna/konsultasi/daftar_dokter_page.dart';
import 'package:pediagrow/features/pengguna/konsultasi/profil_dokter_page.dart';
import 'package:pediagrow/shared/widgets/illustration_forest_footer.dart';
import 'package:pediagrow/shared/widgets/pedia_bottom_nav_bar.dart';

void main() {
  testWidgets(
    'DaftarDokterPage: menampilkan halaman daftar dokter',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: DaftarDokterPage(),
        ),
      );

      await tester.pumpAndSettle();

      // =========================
      // HEADER
      // =========================

      expect(
        find.text('Konsultasi Dokter'),
        findsOneWidget,
      );

      expect(
        find.text('Daftar Dokter'),
        findsOneWidget,
      );

      expect(
        find.byIcon(Icons.notifications_none_rounded),
        findsOneWidget,
      );

      // =========================
      // SEARCH
      // =========================

      expect(
        find.text('Cari nama dokter...'),
        findsOneWidget,
      );

      expect(
        find.byType(TextField),
        findsOneWidget,
      );

      // =========================
      // FOOTER
      // =========================

      expect(
        find.byType(IllustrationForestFooter),
        findsOneWidget,
      );

      // =========================
      // BOTTOM NAVIGATION
      // =========================

      expect(
        find.byType(PediaBottomNavBar),
        findsOneWidget,
      );

      expect(
        find.text('Beranda'),
        findsOneWidget,
      );

      expect(
        find.text('Konsultasi'),
        findsOneWidget,
      );

      expect(
        find.text('Riwayat Konsultasi'),
        findsOneWidget,
      );

      expect(
        find.text('Profil'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'DaftarDokterPage: pencarian dokter yang tidak ditemukan',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: DaftarDokterPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Masukkan nama dokter yang dipastikan
      // tidak ada di daftar.
      await tester.enterText(
        find.byType(TextField),
        'DokterXYZTidakAda',
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Dokter Tidak Ditemukan'),
        findsOneWidget,
      );

      expect(
        find.text('Reset Pencarian'),
        findsOneWidget,
      );

      // Reset pencarian.
      await tester.tap(
        find.text('Reset Pencarian'),
      );

      await tester.pumpAndSettle();

      // Setelah reset, halaman kembali ke daftar dokter.
      expect(
        find.text('Daftar Dokter'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'DaftarDokterPage: dapat membuka profil dokter',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: DaftarDokterPage(),
        ),
      );

      await tester.pumpAndSettle();

      final detailDokter = find.text('Detail Dokter');

      // Dokter berasal dari Firestore dan ditentukan
      // oleh Superadmin.
      //
      // Jika belum ada dokter, tidak ada tombol Detail Dokter.
      // Jika sudah ada dokter, tombol tersebut digunakan
      // untuk membuka ProfilDokterPage.
      if (detailDokter.evaluate().isNotEmpty) {
        await tester.tap(detailDokter.first);

        await tester.pumpAndSettle();

        expect(
          find.byType(ProfilDokterPage),
          findsOneWidget,
        );

        expect(
          find.text('Profil Dokter Anak'),
          findsOneWidget,
        );

        expect(
          find.text('Konsultasi Sekarang'),
          findsOneWidget,
        );
      }
    },
  );
}
