import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/features/pengguna/konsultasi/chat_konsultasi_page.dart';
import 'package:pediagrow/features/pengguna/konsultasi/konfirmasi_selesai_dialog.dart';
import 'package:pediagrow/features/pengguna/konsultasi/konsultasi_selesai_dialog.dart';

void main() {
  group('ChatKonsultasiPage Widget Tests', () {
    testWidgets('Renders header, disclaimer, chat messages, and input bar', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ChatKonsultasiPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('dr. Ririn Esterina, Sp.A'), findsOneWidget);
      expect(find.text('Dokter Spesialis Anak'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Disclaimer verification
      expect(
        find.text(
          'Chat ini bersifat konsultasi umum dan bukan pengganti pemeriksaan langsung.',
        ),
        findsOneWidget,
      );

      // Date badge and Attachment
      expect(find.text('Hari ini'), findsOneWidget);
      expect(find.text('Formulir Keluhan Pasien'), findsOneWidget);

      // Input elements
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Ketik pesan...'), findsOneWidget);
      expect(find.byIcon(Icons.comments_disabled_rounded), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('Dismissing disclaimer hides it from view', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ChatKonsultasiPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Chat ini bersifat konsultasi umum dan bukan pengganti pemeriksaan langsung.',
        ),
        findsNothing,
      );
    });

    testWidgets('Sending a message adds it to chat and triggers doctor response', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ChatKonsultasiPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter text in chat field
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Halo dokter, mau tanya lagi');
      await tester.pump();

      // Tap send button
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // Verify user message appears immediately
      expect(find.text('Halo dokter, mau tanya lagi'), findsOneWidget);

      // Advance time for typing indicator
      await tester.pump(const Duration(milliseconds: 900));

      // Advance time for doctor reply
      await tester.pump(const Duration(milliseconds: 2100));

      expect(
        find.textContaining('Sama-sama Mom’s'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping Akhiri Konsultasi triggers KonfirmasiSelesaiDialog', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ChatKonsultasiPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Akhiri Konsultasi button
      await tester.tap(find.byIcon(Icons.call_end_rounded));
      await tester.pumpAndSettle();

      // Verify Dialog 1 appears
      expect(find.byType(KonfirmasiSelesaiDialog), findsOneWidget);
      expect(find.text('Akhiri Konsultasi ini?'), findsOneWidget);
      expect(find.text('Ya, Akhiri'), findsOneWidget);

      // Tap Ya, Akhiri
      await tester.tap(find.text('Ya, Akhiri'));
      await tester.pumpAndSettle();

      // Verify Dialog 2 appears
      expect(find.byType(KonsultasiSelesaiDialog), findsOneWidget);
      expect(find.text('Konsultasi telah selesai!'), findsOneWidget);
      expect(find.text('Kembali ke beranda'), findsOneWidget);
      expect(find.text('Buka Riwayat Konsultasi'), findsOneWidget);
    });
  });
}
