import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/features/pengguna/beranda/widgets/header_sky_illustration.dart';

void main() {
  testWidgets('HeaderSkyIllustration renders Day and Night modes correctly', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Test Day Mode
    final dayKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: RepaintBoundary(
            key: dayKey,
            child: SizedBox(
              width: 390,
              height: 280,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: HeaderSkyIllustration.dayGradientColors,
                        stops: HeaderSkyIllustration.dayGradientStops,
                      ),
                    ),
                  ),
                  const HeaderSkyIllustration(mode: SkyTimeMode.day),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(HeaderSkyIllustration), findsOneWidget);

    // Capture day screenshot
    final boundaryDay = dayKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final imageDay = await boundaryDay.toImage(pixelRatio: 2.0);
    final byteDataDay = await imageDay.toByteData(format: ui.ImageByteFormat.png);
    if (byteDataDay != null) {
      final fileDay = File(r'C:\Users\anita\.gemini\antigravity-ide\brain\52cef7cb-45b6-4f04-b193-2d1a6606502b\day_header_preview.png');
      await fileDay.writeAsBytes(byteDataDay.buffer.asUint8List());
    }

    // Unmount day widget to stop animation controller
    await tester.pumpWidget(const SizedBox());

    // 2. Test Night Mode
    final nightKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: RepaintBoundary(
            key: nightKey,
            child: SizedBox(
              width: 390,
              height: 280,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: HeaderSkyIllustration.nightGradientColors,
                        stops: HeaderSkyIllustration.nightGradientStops,
                      ),
                    ),
                  ),
                  const HeaderSkyIllustration(mode: SkyTimeMode.night),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(HeaderSkyIllustration), findsOneWidget);

    // Capture night screenshot
    final boundaryNight = nightKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final imageNight = await boundaryNight.toImage(pixelRatio: 2.0);
    final byteDataNight = await imageNight.toByteData(format: ui.ImageByteFormat.png);
    if (byteDataNight != null) {
      final fileNight = File(r'C:\Users\anita\.gemini\antigravity-ide\brain\52cef7cb-45b6-4f04-b193-2d1a6606502b\night_header_preview.png');
      await fileNight.writeAsBytes(byteDataNight.buffer.asUint8List());
    }

    // Unmount night widget to stop animation controller
    await tester.pumpWidget(const SizedBox());
  });
}
