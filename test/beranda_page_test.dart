import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/features/pengguna/beranda/beranda_page.dart';

void main() {
  testWidgets('BerandaPage verification: text, card widths, and images', (
    WidgetTester tester,
  ) async {
    // 390 x 844 viewport (standard modern device)
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: BerandaPage(),
      ),
    );
    await tester.pump();

    // 1. Verify text "Mom Dad belum punya profil anak"
    expect(find.text('Mom Dad belum punya profil anak'), findsOneWidget);
    expect(find.text('MomDad belum punya profil anak'), findsNothing);

    // 2. Verify all menu logo assets & PediaGrow logo & footer
    expect(find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/cek_stunting_logo.png'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/grafik_pertumbuhan_logo.png'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/resep_mpasi_logo.png'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/artikel_kesehatan_logo.png'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/lokasi_fasyankes_logo.png'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/permainan_logo.png'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/bayi_pediagrow_logo.png'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/beranda_landscape_footer.jpg'), findsOneWidget);

    // 3. Verify horizontal alignment and margins
    // MomDad Card
    final momDadFinder = find.ancestor(
      of: find.text('Mom Dad belum punya profil anak'),
      matching: find.byType(Container),
    ).first;
    final Rect momDadRect = tester.getRect(momDadFinder);
    expect(momDadRect.left, equals(12.0));
    expect(momDadRect.right, equals(390.0 - 12.0));
    expect(momDadRect.width, equals(366.0));

    // Card PediaGrow
    final pediaGrowFinder = find.ancestor(
      of: find.text('Pantau Pertumbuhan,\nCegah Stunting untuk Masa Depan'),
      matching: find.byType(Container),
    ).first;
    final Rect pediaGrowRect = tester.getRect(pediaGrowFinder);
    expect(pediaGrowRect.left, equals(12.0));
    expect(pediaGrowRect.right, equals(390.0 - 12.0));
    expect(pediaGrowRect.width, equals(366.0));

    // Menu Card 1 (Cek Stunting) and Card 3 (Resep MPASI)
    final cekStuntingCard = find.ancestor(
      of: find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/cek_stunting_logo.png'),
      matching: find.byType(Container),
    ).first;
    final resepMpasiCard = find.ancestor(
      of: find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/resep_mpasi_logo.png'),
      matching: find.byType(Container),
    ).first;

    final Rect cekStuntingRect = tester.getRect(cekStuntingCard);
    final Rect resepMpasiRect = tester.getRect(resepMpasiCard);
    expect(cekStuntingRect.left, closeTo(12.0, 0.001));
    expect(resepMpasiRect.right, closeTo(390.0 - 12.0, 0.001));

    // Footer Illustration
    final footerFinder = find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/beranda_landscape_footer.jpg');
    final Rect footerRect = tester.getRect(footerFinder);
    expect(footerRect.left, equals(0.0));
    expect(footerRect.right, equals(390.0));
    expect(footerRect.width, equals(390.0));
  });

  testWidgets('Capture BerandaPage top screenshot', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final GlobalKey repaintKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: repaintKey,
          child: const BerandaPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final RenderRepaintBoundary boundary = repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    File(r'C:\Users\anita\.gemini\antigravity-ide\brain\6aa18b72-9fc2-4659-92a3-1d89411935b5\beranda_top_screenshot.png')
        .writeAsBytesSync(byteData!.buffer.asUint8List());
  });

  testWidgets('Capture BerandaPage bottom screenshot', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final GlobalKey repaintKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: repaintKey,
          child: const BerandaPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 200));

    final RenderRepaintBoundary boundary = repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    File(r'C:\Users\anita\.gemini\antigravity-ide\brain\6aa18b72-9fc2-4659-92a3-1d89411935b5\beranda_bottom_screenshot.png')
        .writeAsBytesSync(byteData!.buffer.asUint8List());

    final footerFinder = find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/beranda_landscape_footer.jpg');
    expect(footerFinder, findsOneWidget);
  });
}




