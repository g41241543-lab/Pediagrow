import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/features/pengguna/konsultasi/daftar_dokter_page.dart';
import 'package:pediagrow/features/pengguna/konsultasi/formulir_konsultasi_page.dart';
import 'package:pediagrow/features/pengguna/konsultasi/menunggu_persetujuan_page.dart';
import 'package:pediagrow/models/doctor_model.dart';

void main() {
  group('MenungguPersetujuanPage Widget Tests', () {
    testWidgets('Renders page with default doctor dr. Ririn Esterina, Sp.A', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MenungguPersetujuanPage(),
        ),
      );

      // Settle entrance animations
      await tester.pumpAndSettle(const Duration(milliseconds: 1200));

      // Header verification
      expect(find.text('Menunggu Persetujuan Dokter'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Doctor verification
      expect(find.text('dr. Ririn Esterina, Sp.A'), findsOneWidget);
      expect(find.text('Spesialis Anak'), findsWidgets);

      // Timeline stages verification
      expect(find.text('Permintaan konsultasi dibuat'), findsOneWidget);
      expect(find.text('Menunggu persetujuan dokter'), findsOneWidget);
      expect(find.text('Lanjut isi formulir'), findsOneWidget);

      // Main status text
      expect(find.text('Menunggu persetujuan dokter...'), findsOneWidget);

      // Countdown box present
      expect(find.textContaining(':'), findsWidgets);
    });

    testWidgets('Renders page dynamically with custom doctor dr. Ahmad Nuri, Sp. A', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const customDoctor = DoctorModel(
        id: 'doc-1',
        name: 'dr. Ahmad Nuri, Sp. A',
        specialization: 'Spesialis Anak Konsultan',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MenungguPersetujuanPage(doctor: customDoctor),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1200));

      expect(find.text('dr. Ahmad Nuri, Sp. A'), findsOneWidget);
      expect(find.text('Spesialis Anak Konsultan'), findsOneWidget);
      expect(find.text('dr. Ririn Esterina, Sp.A'), findsNothing);
    });

    testWidgets('State transition to accepted shows "Isi Formulir" and navigates', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final key = GlobalKey<MenungguPersetujuanPageState>();

      await tester.pumpWidget(
        MaterialApp(
          home: MenungguPersetujuanPage(key: key),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1200));

      // Simulate doctor accept
      key.currentState?.simulateDoctorAccept();
      await tester.pumpAndSettle();

      // Verify accepted UI
      expect(find.text('Isi Formulir'), findsOneWidget);
      expect(find.text('Konsultasi disetujui dokter!'), findsOneWidget);

      // Tap "Isi Formulir"
      await tester.tap(find.text('Isi Formulir'));
      await tester.pumpAndSettle();

      // Verify navigation to FormulirKonsultasiPage
      expect(find.byType(FormulirKonsultasiPage), findsOneWidget);
      expect(find.text('Formulir Konsultasi'), findsOneWidget);
    });

    testWidgets('State transition to expired shows "Kembali ke Daftar Dokter" and navigates', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final key = GlobalKey<MenungguPersetujuanPageState>();

      await tester.pumpWidget(
        MaterialApp(
          home: MenungguPersetujuanPage(key: key),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 1200));

      // Simulate doctor reject / expired
      key.currentState?.simulateDoctorReject();
      await tester.pumpAndSettle();

      // Verify expired UI
      expect(find.text('Kembali ke Daftar Dokter'), findsOneWidget);
      expect(find.text('Konsultasi tidak diterima'), findsWidgets);

      // Tap "Kembali ke Daftar Dokter"
      await tester.tap(find.text('Kembali ke Daftar Dokter'));
      await tester.pumpAndSettle();

      // Verify navigation to DaftarDokterPage
      expect(find.byType(DaftarDokterPage), findsOneWidget);
    });

    testWidgets('Back button navigates back', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MenungguPersetujuanPage(),
                    ),
                  );
                },
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      expect(find.byType(MenungguPersetujuanPage), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verified popped back
      expect(find.byType(MenungguPersetujuanPage), findsNothing);
      expect(find.text('Buka'), findsOneWidget);
    });
  });
}
