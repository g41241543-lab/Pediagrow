import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/features/pengguna/fasyankes/models/fasyankes_model.dart';
import 'package:pediagrow/features/pengguna/fasyankes/services/fasyankes_service.dart';
import 'package:pediagrow/features/pengguna/fasyankes/widgets/fasyankes_card_item.dart';
import 'package:pediagrow/features/pengguna/fasyankes/widgets/fasyankes_map_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // -----------------------------------------------------------------------
  // UNIT TESTS: FasyankesModel & FasyankesService
  // -----------------------------------------------------------------------
  group('Unit Tests: FasyankesModel & FasyankesService', () {
    test('FasyankesModel calculates Haversine distance accurately', () {
      const fasyankes = FasyankesModel(
        id: '1',
        name: 'Klinik Pratama Polije',
        address: 'Jl. Mastrip No.164 Jember',
        phone: '0812-3300-0905',
        rating: 4.0,
        latitude: -8.157829,
        longitude: 113.722814,
        category: 'Klinik',
      );

      // Jarak dari titik yang sama harus 0 km
      final zeroDist = fasyankes.calculateDistance(-8.157829, 113.722814);
      expect(zeroDist, closeTo(0.0, 0.001));

      // Jarak ~1 km dari titik berbeda
      final dist = fasyankes.calculateDistance(-8.165000, 113.722814);
      expect(dist, greaterThan(0.5));
      expect(dist, lessThan(1.5));

      // formattedDistance: meter
      final updated = fasyankes.copyWith(distanceKm: 0.85);
      expect(updated.formattedDistance, '850 m');

      // formattedDistance: km
      final updatedFar = fasyankes.copyWith(distanceKm: 2.4);
      expect(updatedFar.formattedDistance, '2.4 km');
    });

    test('googleMapsDirectUrl menggunakan format geo: dengan nama & koordinat', () {
      const fasyankes = FasyankesModel(
        id: '1',
        name: 'Klinik Sakinah',
        address: 'Jl. Kaliurang Jember',
        phone: '0815-5969-4882',
        rating: 4.7,
        latitude: -8.160100,
        longitude: 113.731500,
        category: 'Klinik',
      );

      // Verifikasi format geo: URI
      expect(fasyankes.googleMapsDirectUrl, startsWith('geo:'));
      expect(fasyankes.googleMapsDirectUrl, contains('-8.1601'));
      expect(fasyankes.googleMapsDirectUrl, contains('113.7315'));
    });

    test('FasyankesService returns max 10 nearest facilities sorted by distance',
        () async {
      final service = FasyankesService();
      final list = await service.getNearestFasyankes(
        userLat: -8.1585,
        userLng: 113.7225,
      );

      expect(list.isNotEmpty, true);
      expect(list.length, lessThanOrEqualTo(10));

      // Verifikasi urutan jarak menaik (ascending)
      for (int i = 0; i < list.length - 1; i++) {
        final dist1 = list[i].distanceKm ?? 0;
        final dist2 = list[i + 1].distanceKm ?? 0;
        expect(dist1, lessThanOrEqualTo(dist2));
      }

      // Verifikasi item referensi utama ada di list
      final names = list.map((f) => f.name).toList();
      expect(names.contains('Klinik Pratama Politeknik Negeri Jember'), true);
      expect(names.contains('Klinik Kimia Farma UNEJ Medical Center'), true);
    });

    test('FasyankesService filters by query correctly', () async {
      final service = FasyankesService();
      final results = await service.getNearestFasyankes(
        query: 'Politeknik',
      );

      expect(results.isNotEmpty, true);
      expect(results.first.name, contains('Politeknik Negeri Jember'));
    });
  });

  // -----------------------------------------------------------------------
  // WIDGET TESTS: FasyankesMapWidget & FasyankesCardItem
  // -----------------------------------------------------------------------
  group('Widget Tests: FasyankesMapWidget & FasyankesCardItem', () {
    const testFasyankes = FasyankesModel(
      id: 'test_1',
      name: 'Klinik Pratama Politeknik Negeri Jember',
      address: 'Jl. Mastrip No.164, Jember',
      phone: '0812-3300-0905',
      rating: 4.0,
      userRatingsTotal: 142,
      latitude: -8.157829,
      longitude: 113.722814,
      category: 'Klinik',
      distanceKm: 0.3,
    );

    testWidgets('FasyankesMapWidget renders Map/Satellite toggle & zoom controls',
        (tester) async {
      tester.view.physicalSize = const Size(400, 320);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FasyankesMapWidget(
              fasyankesList: [testFasyankes],
              userLat: -8.1585,
              userLng: 113.7225,
              height: 270,
            ),
          ),
        ),
      );
      // pump beberapa frame tanpa pumpAndSettle (tile network request bisa timeout)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Toggle Map/Satellite terlihat
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Satellite'), findsOneWidget);

      // Kontrol zoom terlihat
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

      // Tap Satellite toggle
      await tester.tap(find.text('Satellite'));
      await tester.pump();

      // Tap zoom in & zoom out
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
    });

    testWidgets('FasyankesMapWidget shows callout when fasyankes selected',
        (tester) async {
      tester.view.physicalSize = const Size(400, 320);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FasyankesMapWidget(
              fasyankesList: [testFasyankes],
              selectedFasyankes: testFasyankes,
              userLat: -8.1585,
              userLng: 113.7225,
              height: 270,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Callout harus muncul saat ada selectedFasyankes
      expect(find.text('Klinik Pratama Politeknik Negeri Jember'), findsWidgets);
      expect(find.text('Buka Maps'), findsWidgets);
    });

    testWidgets('FasyankesCardItem renders nama, alamat, rating, dan tombol Buka Maps',
        (tester) async {
      tester.view.physicalSize = const Size(360, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FasyankesCardItem(
              fasyankes: testFasyankes,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Klinik Pratama Politeknik Negeri Jember'), findsOneWidget);
      expect(find.text('Jl. Mastrip No.164, Jember'), findsOneWidget);
      expect(find.text('0812-3300-0905'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.text('Buka Maps'), findsOneWidget);
      expect(find.text('300 m'), findsOneWidget);
    });

    testWidgets('FasyankesCardItem tidak overflow pada layar kecil (320dp lebar)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FasyankesCardItem(
                fasyankes: testFasyankes,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tidak ada overflow exception
      expect(find.byType(FasyankesCardItem), findsOneWidget);
    });
  });
}
