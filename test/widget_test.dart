import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/features/auth/auth_choice_page.dart';
import 'package:pediagrow/features/auth/register_page.dart';
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

  testWidgets('RegisterPage renders pinned header and all form elements', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterPage(),
      ),
    );

    // Verify pinned header
    expect(find.text('Daftar Akun Baru'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    // Verify field hint texts
    expect(find.text('Masukkan nama lengkap anda'), findsOneWidget);
    expect(find.text('Masukkan email aktif anda'), findsOneWidget);
    expect(find.text('Kata Sandi min. 6 karakter'), findsOneWidget);
    expect(find.text('Ulangi kata sandi yang dimasukkan'), findsOneWidget);

    // Verify buttons
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text('Daftar dengan Google'), findsOneWidget);
    expect(find.text('atau'), findsOneWidget);
  });

  testWidgets('RegisterPage validates empty and invalid inputs properly', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterPage(),
      ),
    );

    final registerBtn = find.byKey(const Key('register_button'));
    final nameField = find.byKey(const Key('name_field'));
    final emailField = find.byKey(const Key('email_field'));
    final passField = find.byKey(const Key('password_field'));
    final confirmField = find.byKey(const Key('confirm_password_field'));

    // 1. Click Daftar while empty -> should show required validation errors
    await tester.tap(registerBtn);
    await tester.pumpAndSettle();

    expect(find.text('Nama pengguna wajib diisi'), findsOneWidget);
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    expect(find.text('Konfirmasi kata sandi wajib diisi'), findsOneWidget);

    // 2. Test Nama Pengguna with numbers (invalid)
    await tester.enterText(nameField, 'User123');
    await tester.tap(registerBtn);
    await tester.pumpAndSettle();
    expect(find.text('Nama pengguna harus diisikan dengan huruf saja'), findsOneWidget);

    // 3. Test Email with non-gmail (invalid)
    await tester.enterText(nameField, 'Budi Santoso');
    await tester.enterText(emailField, 'test@yahoo.com');
    await tester.tap(registerBtn);
    await tester.pumpAndSettle();
    expect(find.text('Email harus berupa akun Gmail yang valid (@gmail.com)'), findsOneWidget);

    // 4. Test Password without symbol / combination
    await tester.enterText(emailField, 'budi.santoso@gmail.com');
    await tester.enterText(passField, '123456');
    await tester.tap(registerBtn);
    await tester.pumpAndSettle();
    expect(find.text('Kata sandi harus kombinasi huruf, angka, dan simbol'), findsOneWidget);

    // 5. Test Password mismatch
    await tester.enterText(passField, 'PediaGrow123!');
    await tester.enterText(confirmField, 'DifferentPass123!');
    await tester.tap(registerBtn);
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi kata sandi tidak cocok dengan kata sandi'), findsOneWidget);

    // 6. Test valid submission
    await tester.enterText(confirmField, 'PediaGrow123!');
    await tester.tap(registerBtn);
    await tester.pump();
    expect(find.text('Pendaftaran berhasil! Mengalihkan ke halaman pilihan akun...'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(milliseconds: 1200));
  });

  testWidgets('RegisterPage opens Google Account picker bottom sheet', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterPage(),
      ),
    );

    // Scroll to and click Daftar dengan Google
    final googleBtn = find.byKey(const Key('google_register_button'));
    await tester.ensureVisible(googleBtn);
    await tester.tap(googleBtn);
    await tester.pumpAndSettle();

    // Verify modal bottom sheet is displayed
    expect(find.text('Pilih akun Google'), findsOneWidget);
    expect(find.text('pengguna.pediagrow@gmail.com'), findsOneWidget);
  });
}
