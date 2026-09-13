import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/features/pengguna/riwayat_konsultasi/daftar_riwayat_page.dart';
import 'package:pediagrow/features/pengguna/riwayat_konsultasi/detail_konsultasi_page.dart';
import 'package:pediagrow/features/pengguna/riwayat_konsultasi/widgets/riwayat_consultation_card.dart';
import 'package:pediagrow/features/pengguna/riwayat_konsultasi/widgets/riwayat_empty_state.dart';
import 'package:pediagrow/features/pengguna/riwayat_konsultasi/widgets/riwayat_header.dart';
import 'package:pediagrow/models/riwayat_konsultasi_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Riwayat Konsultasi Tests', () {
    testWidgets('DaftarRiwayatPage displays Empty State when list is empty',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DaftarRiwayatPage(
            initialRiwayatList: [],
          ),
        ),
      );
      await tester.pump();

      // Verifikasi header
      expect(
        find.descendant(
          of: find.byType(RiwayatHeader),
          matching: find.text('Riwayat Konsultasi'),
        ),
        findsOneWidget,
      );

      // Verifikasi empty state
      expect(find.byType(RiwayatEmptyState), findsOneWidget);
      expect(find.text('Belum ada riwayat konsultasi'), findsOneWidget);

      // Tidak ada card konsultasi
      expect(find.byType(RiwayatConsultationCard), findsNothing);
    });

    testWidgets(
        'DaftarRiwayatPage displays Consultation Cards and navigates to Detail',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: DaftarRiwayatPage(
            initialRiwayatList: [RiwayatKonsultasiModel.sampleRiwayat1],
          ),
        ),
      );
      await tester.pump();

      // Verifikasi bahwa card riwayat muncul
      expect(find.byType(RiwayatConsultationCard), findsOneWidget);
      expect(find.text('dr. Ririn Esterina, Sp.A'), findsOneWidget);
      expect(find.text('Anak : Kaia Anastasya'), findsOneWidget);
      expect(
        find.text('Keluhan : BB anak naik turun dan nafsu makan berkurang'),
        findsOneWidget,
      );
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('26 Agustus 2026'), findsOneWidget);

      // Tekan card riwayat untuk navigasi ke DetailKonsultasiPage
      await tester.tap(find.byType(RiwayatConsultationCard));
      await tester.pumpAndSettle();

      // Verifikasi halaman Detail Konsultasi terbuka
      expect(find.byType(DetailKonsultasiPage), findsOneWidget);
      expect(find.text('Detail Konsultasi'), findsOneWidget);
      expect(find.text('Dokter Spesialis Anak'), findsOneWidget);
      expect(find.text('Nama anak'), findsOneWidget);
      expect(find.text('Kaia Anastasya'), findsOneWidget);
      expect(find.text('Tanggal Konsultasi'), findsOneWidget);
      expect(find.text('Status Konsultasi'), findsOneWidget);
      expect(find.text('Keluhan'), findsOneWidget);
      expect(find.text('Ringkasan Konsultasi'), findsOneWidget);
    });

    testWidgets('DetailKonsultasiPage back button pops back',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: DetailKonsultasiPage(
            riwayat: RiwayatKonsultasiModel.sampleRiwayat1,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Detail Konsultasi'), findsOneWidget);
      expect(find.text('dr. Ririn Esterina, Sp.A'), findsOneWidget);

      // Cari tombol kembali dan tap
      final backButtonFinder = find.byIcon(Icons.arrow_back);
      expect(backButtonFinder, findsOneWidget);
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();
    });

    testWidgets('DaftarRiwayatPage handles multiple consultation cards safely',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640); // Small screen constraint
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: DaftarRiwayatPage(
            initialRiwayatList: RiwayatKonsultasiModel.mockMultiList,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(RiwayatConsultationCard), findsNWidgets(2));
      expect(find.text('dr. Ririn Esterina, Sp.A'), findsOneWidget);
      expect(find.text('dr. Ahmad Nuri, Sp.A'), findsOneWidget);

      // Pastikan tidak ada RenderFlex overflow
      expect(tester.takeException(), isNull);
    });
  });
}
