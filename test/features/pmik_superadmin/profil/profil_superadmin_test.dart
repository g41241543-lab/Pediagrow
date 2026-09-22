import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/features/pmik_superadmin/profil/profil_superadmin_page.dart';
import 'package:pediagrow/features/pmik_superadmin/profil/hak_akses/hak_akses_page.dart';

void main() {
  testWidgets('ProfilSuperadminPage: renders all components, header, cards, buttons, navbar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilSuperadminPage(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Header & Title verification
    expect(find.text('Profil'), findsWidgets); // di header & navbar
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    // 2. Profile Card verification
    expect(find.text('Anita Setyowati, S.Tr. RMIK'), findsOneWidget);
    expect(find.text('PMIK'), findsOneWidget);
    expect(find.text('g41241509@student.polije.ac.id'), findsOneWidget);
    expect(find.text('Pengalaman'), findsOneWidget);
    expect(find.text('7 tahun'), findsOneWidget);
    expect(find.text('No. STR'), findsOneWidget);
    expect(find.text('3511201402012222'), findsOneWidget);

    // 3. General info card verification
    expect(find.text('Informasi Umum'), findsOneWidget);
    expect(find.text('Tanggal Lahir'), findsOneWidget);
    expect(find.text('16/07/2006'), findsOneWidget);
    expect(find.text('Pendidikan'), findsOneWidget);
    expect(find.text('DIV - Manajemen Informasi Kesehatan'), findsOneWidget);

    // 4. Action buttons
    expect(find.text('HAK AKSES'), findsOneWidget);
    expect(find.text('LOGOUT'), findsOneWidget);

    // 5. Bottom navigation bar (4 menus)
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Konsultasi'), findsOneWidget);
    expect(find.text('Riwayat Konsultasi'), findsOneWidget);

    // 6. Navigation to Hak Akses
    await tester.tap(find.text('HAK AKSES'));
    await tester.pumpAndSettle();

    expect(find.byType(HakAksesPage), findsOneWidget);
    expect(find.text('Hak Akses'), findsOneWidget);
    expect(find.text('Dokter'), findsOneWidget);
    expect(find.text('PMIK'), findsOneWidget);
  });

  testWidgets('ProfilSuperadminPage: responsive layout on small screen (no overflow)', (
    WidgetTester tester,
  ) async {
    // Layar kecil Android (contoh: 320 x 533)
    tester.view.physicalSize = const Size(320, 533);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilSuperadminPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Pastikan tidak ada RenderFlex overflow
    expect(tester.takeException(), isNull);
    expect(find.text('Anita Setyowati, S.Tr. RMIK'), findsOneWidget);
    expect(find.text('HAK AKSES'), findsOneWidget);
  });
}
