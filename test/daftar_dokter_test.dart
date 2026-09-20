import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/core/services/doctor_service.dart';
import 'package:pediagrow/features/pengguna/konsultasi/daftar_dokter_page.dart';
import 'package:pediagrow/features/pengguna/konsultasi/profil_dokter_page.dart';
import 'package:pediagrow/shared/widgets/illustration_forest_footer.dart';
import 'package:pediagrow/shared/widgets/pedia_bottom_nav_bar.dart';

void main() {
  setUp(() {
    DoctorService().resetToDefault();
  });

  testWidgets('DaftarDokterPage: render header, search, doctor list, footer, and navbar', (
    WidgetTester tester,
  ) async {
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

    // 1. Header & Title verification
    expect(find.text('Konsultasi Dokter'), findsOneWidget);
    expect(find.text('Daftar Dokter'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    // 2. Search bar verification
    expect(find.text('Cari nama dokter...'), findsOneWidget);

    // 3. Verify doctor names from DoctorModel.dummyList
    expect(find.text('dr. Ahmad Nuri, Sp. A'), findsOneWidget);
    expect(find.text('dr. Ririn Esterina, Sp.A'), findsOneWidget);
    expect(find.text('Spesialis Anak'), findsWidgets);
    expect(find.text('35 tahun pengalaman'), findsOneWidget);

    // 4. Verify Detail Dokter buttons
    expect(find.text('Detail Dokter'), findsWidgets);

    // 5. Verify footer illustration & navigation bar
    expect(find.byType(IllustrationForestFooter), findsOneWidget);
    expect(find.byType(PediaBottomNavBar), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Konsultasi'), findsOneWidget);
    expect(find.text('Riwayat Konsultasi'), findsOneWidget);
    expect(find.text('Profil Ibu'), findsOneWidget);
  });

  testWidgets('DaftarDokterPage: dynamic search filtering and reset', (
    WidgetTester tester,
  ) async {
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

    // Type query "Ririn"
    await tester.enterText(find.byType(TextField), 'Ririn');
    await tester.pumpAndSettle();

    // Only dr. Ririn Esterina should be visible
    expect(find.text('dr. Ririn Esterina, Sp.A'), findsOneWidget);
    expect(find.text('dr. Ahmad Nuri, Sp. A'), findsNothing);

    // Type non-existent query
    await tester.enterText(find.byType(TextField), 'DokterXYZ');
    await tester.pumpAndSettle();

    expect(find.text('Dokter Tidak Ditemukan'), findsOneWidget);
    expect(find.text('Reset Pencarian'), findsOneWidget);

    // Tap reset button
    await tester.tap(find.text('Reset Pencarian'));
    await tester.pumpAndSettle();

    expect(find.text('dr. Ahmad Nuri, Sp. A'), findsOneWidget);
    expect(find.text('dr. Ririn Esterina, Sp.A'), findsOneWidget);
  });

  testWidgets('DaftarDokterPage: tap Detail Dokter navigates to ProfilDokterPage', (
    WidgetTester tester,
  ) async {
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

    // Tap first 'Detail Dokter' button
    await tester.tap(find.text('Detail Dokter').first);
    await tester.pumpAndSettle();

    expect(find.byType(ProfilDokterPage), findsOneWidget);
    expect(find.text('Profil Dokter Anak'), findsOneWidget);
    expect(find.text('Konsultasi Sekarang'), findsOneWidget);
  });
}
