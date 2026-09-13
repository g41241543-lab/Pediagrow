import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/features/pengguna/cek_stunting/proses_cek_stunting_page.dart';
import 'package:pediagrow/features/pengguna/cek_stunting/services/stunting_ml_service.dart';
import 'package:pediagrow/features/pengguna/cek_stunting/widgets/pego_analysis_overlay.dart';
import 'package:pediagrow/features/pengguna/cek_stunting/widgets/pego_robot_widget.dart';

void main() {
  group('Unit Tests: StuntingMlService & Data Mining Logic', () {
    test('Calculates correct age and features for child', () {
      final input = StuntingInputData(
        namaAnak: 'Kaia Anastasya',
        gender: 'Perempuan',
        birthDate: DateTime(2025, 5, 22),
        checkDate: DateTime(2026, 8, 26),
        birthWeightKg: 2.9,
        birthHeightCm: 50.0,
        currentWeightKg: 9.1,
        currentHeightCm: 77.0,
        isExclusiveBreastfeeding: true,
      );

      expect(input.ageInMonths, equals(15));
      expect(input.ageDescription, contains('1 tahun 3 bulan'));

      final featureMap = input.toFeatureMap();
      expect(featureMap['gender'], equals(1)); // 1 for female
      expect(featureMap['asi_eksklusif'], equals(1));
      expect(featureMap['current_weight_kg'], equals(9.1));
      expect(featureMap['current_height_cm'], equals(77.0));
    });

    test('Runs Local Random Forest inference and evaluates stunting status', () async {
      // Data Kaia Anastasya (Normal growth: 15 bulan, 77 cm)
      final normalInput = StuntingInputData(
        namaAnak: 'Kaia Anastasya',
        gender: 'Perempuan',
        birthDate: DateTime(2025, 5, 22),
        checkDate: DateTime(2026, 8, 26),
        birthWeightKg: 2.9,
        birthHeightCm: 50.0,
        currentWeightKg: 9.1,
        currentHeightCm: 77.0,
        isExclusiveBreastfeeding: true,
      );

      final result = await StuntingMlService.predict(normalInput);
      expect(result.status, equals(StuntingStatusCategory.normal));
      expect(result.confidenceProbability, greaterThanOrEqualTo(0.85));
      expect(result.recommendations.isNotEmpty, isTrue);

      // Data Anak Stunted (15 bulan, 68 cm -> HAZ < -2.5)
      final stuntedInput = StuntingInputData(
        namaAnak: 'Anak Uji',
        gender: 'Perempuan',
        birthDate: DateTime(2025, 5, 22),
        checkDate: DateTime(2026, 8, 26),
        birthWeightKg: 2.2,
        birthHeightCm: 46.0,
        currentWeightKg: 6.8,
        currentHeightCm: 68.0,
        isExclusiveBreastfeeding: false,
      );

      final stuntedResult = await StuntingMlService.predict(stuntedInput);
      expect(
        stuntedResult.status == StuntingStatusCategory.berisikoStunting ||
            stuntedResult.status == StuntingStatusCategory.severelyStunted,
        isTrue,
      );
    });
  });

  group('Widget Tests: ProsesCekStuntingPage UI & Responsive Checks', () {
    testWidgets('Renders all required elements without overflow on small Android screen',
        (WidgetTester tester) async {
      // Set small Android screen (320 x 600)
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProsesCekStuntingPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Custom Header (56dp)
      expect(find.text('Cek Stunting'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // 2. Verify Heading
      expect(find.text('Lengkapi Informasi Tentang Si Kecil!'), findsOneWidget);

      // 3. Verify Form Fields
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Jenis Kelamin'), findsOneWidget);
      expect(find.text('Tanggal Lahir'), findsOneWidget);
      expect(find.text('Tanggal Cek Stunting'), findsOneWidget);
      expect(find.text('Berat Badan Saat Lahir'), findsOneWidget);
      expect(find.text('Tinggi Badan Saat Lahir'), findsOneWidget);
      expect(find.text('Berat Badan Sekarang'), findsOneWidget);
      expect(find.text('Tinggi Badan Sekarang'), findsOneWidget);
      expect(
        find.text('Apakah hingga saat ini si kecil mendapatkan ASI secara penuh?'),
        findsOneWidget,
      );
      expect(find.text('Tidak'), findsOneWidget);
      expect(find.text('Ya'), findsOneWidget);

      // 4. Verify Main Button "CEK SEKARANG!"
      expect(find.text('CEK SEKARANG!'), findsOneWidget);

      // 5. Verify 4 items in bottom navigation bar
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Konsultasi'), findsOneWidget);
      expect(find.text('Riwayat Konsultasi'), findsOneWidget);
      expect(find.text('Profil Ibu'), findsOneWidget);
    });

    testWidgets('Tapping CEK SEKARANG! triggers Pego analysis overlay sequence',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProsesCekStuntingPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap CEK SEKARANG!
      final buttonFinder = find.text('CEK SEKARANG!');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump(const Duration(milliseconds: 100));

      // Verify overlay is triggered
      expect(find.byType(PegoAnalysisOverlay), findsOneWidget);
      expect(find.byType(PegoRobotWidget), findsOneWidget);
      expect(find.text('Pego sedang menganalisis'), findsOneWidget);

      // Advance through the full sequence (fade, blackhole, pego spring, analysis, return)
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump(const Duration(milliseconds: 1632));
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      // Verify result sheet is displayed
      expect(find.text('Lihat Hasil Lengkap'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);
    });
  });
}
