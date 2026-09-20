import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/core/services/child_service.dart';
import 'package:pediagrow/features/pengguna/konsultasi/chat_konsultasi_page.dart';
import 'package:pediagrow/features/pengguna/konsultasi/formulir_konsultasi_page.dart';
import 'package:pediagrow/models/child_model.dart';

void main() {
  group('FormulirKonsultasiPage Widget Tests', () {
    setUp(() {
      // Reset ChildService state before each test for full isolation
      ChildService().clear();
    });

    tearDown(() {
      ChildService().clear();
    });

    testWidgets('Renders all visual sections according to design', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: FormulirKonsultasiPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Formulir Konsultasi'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // Card Lengkapi Form Konsultasi
      expect(find.text('Lengkapi Form Konsultasi'), findsOneWidget);
      expect(
        find.text(
          'Mohon lengkapi data berikut agar dokter dapat memahami kondisi anak Anda dengan lebih baik.',
        ),
        findsOneWidget,
      );

      // Data Anak (default fallback — no active child set → plain label)
      expect(find.text('Data Anak'), findsOneWidget);

      // Card Berat Badan Saat Ini
      expect(find.text('Berat Badan Saat Ini'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
      expect(find.text('Contoh: 10.5'), findsOneWidget);

      // Card Tinggi Badan Saat Ini
      expect(find.text('Tinggi Badan Saat Ini'), findsOneWidget);
      expect(find.text('cm'), findsOneWidget);
      expect(find.text('Contoh: 85.0'), findsOneWidget);

      // Card Keluhan
      expect(find.text('Keluhan'), findsOneWidget);
      expect(
        find.text('Ceritakan keluhan atau kondisi yang dirasakan anak saat ini.'),
        findsOneWidget,
      );
      expect(find.text('0/500'), findsOneWidget);

      // Card Tips
      expect(find.text('Tips'), findsOneWidget);
      expect(
        find.text(
          'Berikan informasi selengkap mungkin agar dokter dapat memberikan saran yang tepat.',
        ),
        findsOneWidget,
      );

      // Card Informasi Penting
      expect(find.text('Informasi Penting'), findsOneWidget);
      expect(find.text('Data yang anda berikan bersifat rahasia.'), findsOneWidget);
      expect(find.text('Pastikan data yang diisi sudah benar.'), findsOneWidget);

      // Button & Footer Keamanan
      expect(find.text('Lanjutkan Chat Dokter'), findsOneWidget);
      expect(find.text('Data Anda aman dan terlindungi'), findsOneWidget);
    });

    testWidgets('Renders dynamic child data when provided via widget param', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const customChild = ChildModel(
        id: 'child-1',
        name: 'Rafa',
        gender: 'Laki-laki',
        ageDescription: '2 tahun 1 bulan',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: FormulirKonsultasiPage(child: customChild),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Laki-laki, 2 tahun 1 bulan'), findsOneWidget);
      // Child name should appear in title
      expect(find.text('Data Anak (Rafa)'), findsOneWidget);
    });

    testWidgets(
      'Defaults to active child from ChildService when no child parameter is passed',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const activeChild = ChildModel(
          id: 'child-active',
          name: 'Budi Santoso',
          gender: 'Laki-laki',
          ageDescription: '3 tahun 2 bulan',
        );

        // Set the active child BEFORE opening the form (no child widget param)
        ChildService().addChild(activeChild);

        await tester.pumpWidget(
          const MaterialApp(
            home: FormulirKonsultasiPage(),
          ),
        );
        await tester.pumpAndSettle();

        // Title must include active child's name
        expect(find.text('Data Anak (Budi Santoso)'), findsOneWidget);

        // Subtitle must reflect active child gender + age
        expect(find.text('Laki-laki, 3 tahun 2 bulan'), findsOneWidget);
      },
    );

    testWidgets('Validates required fields and character counter updates', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: FormulirKonsultasiPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to button until visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Tap submit with empty fields
      await tester.tap(find.text('Lanjutkan Chat Dokter'));
      await tester.pumpAndSettle();

      // Verify validation errors appear
      expect(find.text('Berat badan belum diisi.'), findsOneWidget);
      expect(find.text('Tinggi badan belum diisi.'), findsOneWidget);
      expect(find.text('Keluhan belum diisi.'), findsOneWidget);

      // Type into complaint textarea and check realtime counter
      final complaintField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.maxLines == 5,
      );
      await tester.enterText(complaintField, 'Anak demam sejak semalam');
      await tester.pump();

      expect(find.text('24/500'), findsOneWidget);
    });

    testWidgets('Navigates to ChatKonsultasiPage when all inputs valid', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: FormulirKonsultasiPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter weight
      final weightField = find.widgetWithText(TextFormField, 'Masukkan berat badan');
      await tester.enterText(weightField, '10.5');
      await tester.pump();

      // Enter height
      final heightField = find.widgetWithText(TextFormField, 'Masukkan tinggi badan');
      await tester.enterText(heightField, '85.0');
      await tester.pump();

      // Enter complaint
      final complaintField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.maxLines == 5,
      );
      await tester.enterText(complaintField, 'Anak batuk pilek dan nafsu makan menurun');
      await tester.pump();

      // Scroll down to submit button until visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Tap submit
      await tester.tap(find.text('Lanjutkan Chat Dokter'));
      await tester.pumpAndSettle();

      // Verify navigation to ChatKonsultasiPage
      expect(find.byType(ChatKonsultasiPage), findsOneWidget);
    });
  });
}
