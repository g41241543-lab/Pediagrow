import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/core/services/child_service.dart';
import 'package:pediagrow/features/pengguna/profil_anak/hapus_anak_dialog.dart';
import 'package:pediagrow/features/pengguna/profil_anak/ubah_anak_page.dart';
import 'package:pediagrow/models/child_model.dart';

void main() {
  setUp(() {
    ChildService().clear();
  });

  final testChild = ChildModel(
    id: 'child_123',
    name: 'Budi Santoso',
    gender: 'Laki-laki',
    ageDescription: '1 tahun 2 bulan',
    birthDate: DateTime(2023, 5, 10),
    weightKg: 3.4,
    heightCm: 50.0,
    hasAllergies: true,
    allergies: 'Debu dan susu sapi',
  );

  testWidgets('UbahAnakPage pre-fills form data from ChildModel', (tester) async {
    ChildService().addChild(testChild);

    await tester.pumpWidget(
      MaterialApp(
        home: UbahAnakPage(child: testChild),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header title
    expect(find.text('Ubah Data Profil'), findsOneWidget);
    expect(find.text('Hapus'), findsOneWidget);

    // Verify prefilled values
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('10/05/2023'), findsOneWidget);
    expect(find.text('3.4'), findsOneWidget);
    expect(find.text('50.0'), findsOneWidget);
    expect(find.text('Debu dan susu sapi'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);
  });

  testWidgets('HapusAnakDialog shows confirmation and invokes callback on Ya', (tester) async {
    bool deleteConfirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                HapusAnakDialog.show(
                  context,
                  onConfirmDelete: () {
                    deleteConfirmed = true;
                  },
                );
              },
              child: const Text('Buka Dialog'),
            ),
          ),
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Buka Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('Hapus Data'), findsOneWidget);
    expect(
      find.text('Mohon pastikan ulang sebelum menghapus profil anak. Apakah anda yakin ingin menghapus?'),
      findsOneWidget,
    );
    expect(find.text('Ya'), findsOneWidget);
    expect(find.text('Tidak'), findsOneWidget);

    // Tap "Ya"
    await tester.tap(find.text('Ya'));
    await tester.pumpAndSettle();

    expect(deleteConfirmed, isTrue);
  });
}
