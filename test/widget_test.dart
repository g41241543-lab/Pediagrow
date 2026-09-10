import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/features/auth/auth_choice_page.dart';
import 'package:pediagrow/features/splash/splash_page.dart';
import 'package:pediagrow/main.dart';

void main() {
  testWidgets('SplashPage smoke test - renders MyApp and reaches AuthChoicePage', (
    WidgetTester tester,
  ) async {
    // Set a typical compact Android phone viewport (360x640)
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    expect(find.byType(SplashPage), findsOneWidget);

    // Pump through the entire animation duration (3800ms)
    await tester.pumpAndSettle(const Duration(milliseconds: 4500));

    // Verify AuthChoicePage elements are present and visible
    expect(find.byType(AuthChoicePage), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Daftar Akun Baru'), findsOneWidget);
    expect(
      find.text('Pantau Pertumbuhan, Cegah Stunting\nUntuk Masa Depan'),
      findsOneWidget,
    );
  });

  testWidgets(
    'AuthChoicePage buttons trigger onLoginPressed and onRegisterPressed',
    (WidgetTester tester) async {
      bool loginPressed = false;
      bool registerPressed = false;

      tester.view.physicalSize = const Size(412, 915); // Modern Android phone
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AuthChoicePage(
            onLoginPressed: () => loginPressed = true,
            onRegisterPressed: () => registerPressed = true,
          ),
        ),
      );

      // Test Masuk button
      await tester.tap(find.text('Masuk'));
      await tester.pump();
      expect(loginPressed, isTrue);

      // Test Daftar Akun Baru button
      await tester.tap(find.text('Daftar Akun Baru'));
      await tester.pump();
      expect(registerPressed, isTrue);
    },
  );

  testWidgets('SplashPage tap to skip immediately jumps to AuthChoicePage', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SplashPage()));

    // Initial state (Stage 1)
    await tester.pump(const Duration(milliseconds: 100));

    // Tap screen to skip
    await tester.tap(find.byType(SplashPage));
    await tester.pumpAndSettle();

    // Verify AuthChoicePage elements are now available
    expect(find.byType(AuthChoicePage), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Daftar Akun Baru'), findsOneWidget);
  });
}
