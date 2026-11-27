import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/features/pengguna/beranda/widgets/forest_cloud_painter.dart';
import 'package:pediagrow/features/pengguna/game_edukasi/game_mulai_page.dart';
import 'package:pediagrow/features/pengguna/game_edukasi/game_skor_akhir_page.dart';
import 'package:pediagrow/models/soal_model.dart';
import 'package:pediagrow/shared/widgets/illustration_forest_footer.dart';

void main() {
  testWidgets(
    'IllustrationForestFooter renders sky gradient & clouds cleanly in Light and Dark modes',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          home: const Scaffold(
            backgroundColor: Colors.white,
            body: Align(
              alignment: Alignment.bottomCenter,
              child: IllustrationForestFooter(fit: BoxFit.fitWidth),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IllustrationForestFooter), findsOneWidget);
      expect(find.byType(ForestCloudWidget), findsNWidgets(3));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
          home: const Scaffold(
            backgroundColor: Color(0xFF0B1014),
            body: Align(
              alignment: Alignment.bottomCenter,
              child: IllustrationForestFooter(fit: BoxFit.fitWidth),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IllustrationForestFooter), findsOneWidget);
      expect(find.byType(ForestCloudWidget), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'IllustrationForestFooter omits footer clouds when withClouds is false',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: IllustrationForestFooter(
                fit: BoxFit.fitWidth,
                withClouds: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IllustrationForestFooter), findsOneWidget);
      expect(find.byType(ForestCloudWidget), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'IllustrationForestFooter supports custom backgroundBlendColor for soft slate scaffolds',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Align(
              alignment: Alignment.bottomCenter,
              child: IllustrationForestFooter(
                fit: BoxFit.fitWidth,
                backgroundBlendColor: Color(0xFFF8FAFC),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final footer = tester.widget<IllustrationForestFooter>(
        find.byType(IllustrationForestFooter),
      );
      expect(footer.backgroundBlendColor, const Color(0xFFF8FAFC));
      expect(find.byType(ForestCloudWidget), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'GameMulaiPage & GameSkorAkhirPage render forest footer with custom blue blend cleanly',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: GameMulaiPage(),
        ),
      );
      await tester.pumpAndSettle();

      final mulaiFooter = tester.widget<IllustrationForestFooter>(
        find.byType(IllustrationForestFooter),
      );
      expect(mulaiFooter.backgroundBlendColor, const Color(0xFF6FA8E8));
      expect(find.byType(ForestCloudWidget), findsNWidgets(3));
      expect(tester.takeException(), isNull);

      const sampleSoal = SoalModel(
        id: 1,
        kategori: 'Stunting & Gizi',
        pertanyaan: 'Contoh soal?',
        jawabanBenar: true,
        penjelasan: 'Contoh penjelasan.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: GameSkorAkhirPage(
            soalList: [sampleSoal],
            hasilList: [
              HasilSoal(soal: sampleSoal, pilihanPengguna: true),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final skorFooter = tester.widget<IllustrationForestFooter>(
        find.byType(IllustrationForestFooter),
      );
      expect(skorFooter.backgroundBlendColor, const Color(0xFF6FA8E8));
      expect(find.byType(ForestCloudWidget), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );
}
