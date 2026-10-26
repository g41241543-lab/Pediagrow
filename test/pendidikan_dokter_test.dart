import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/core/services/doctor_service.dart';
import 'package:pediagrow/features/dokter/profil_dokter_page.dart' as dokter_view;
import 'package:pediagrow/features/pengguna/konsultasi/profil_dokter_page.dart' as user_view;
import 'package:pediagrow/features/pmik_superadmin/profil/hak_akses/edit_dokter_akses_page.dart';
import 'package:pediagrow/features/pmik_superadmin/profil/hak_akses/tambah_dokter_akses_page.dart';
import 'package:pediagrow/models/doctor_model.dart';

void main() {
  group('Pendidikan Dokter Feature Tests', () {
    const testDoctor = DoctorModel(
      id: 'doc-test-1',
      name: 'dr. Reny Diah Pujiastuti. Sp. A',
      specialization: 'Spesialis Anak',
      experienceYears: 10,
      strNumber: '351216435491964',
      hospital: 'RS PENDIDIKAN POLITEKNIK NEGERI JEMBER',
      placesOfPractice: ['RS PENDIDIKAN POLITEKNIK NEGERI JEMBER'],
      educations: [
        'Universitas Airlangga - Spesialis Anak',
      ],
      education: 'Universitas Airlangga - Spesialis Anak',
    );

    test('DoctorModel: daftarPendidikan returns education list', () {
      expect(testDoctor.daftarPendidikan, ['Universitas Airlangga - Spesialis Anak']);

      const fallbackDoctor = DoctorModel(
        id: 'doc-test-2',
        name: 'dr. Fallback',
        education: 'Universitas Indonesia',
      );
      expect(fallbackDoctor.daftarPendidikan, ['Universitas Indonesia']);
    });

    testWidgets(
      'ProfilDokterPage (Pengguna): menampilkan card Pendidikan di atas Tempat Praktik & menghapus Jadwal Praktik',
      (tester) async {
        DoctorService().setDoctorsForTesting([testDoctor]);

        await tester.pumpWidget(
          const MaterialApp(
            home: user_view.ProfilDokterPage(doctor: testDoctor),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Memastikan card Pendidikan ada
        expect(find.text('Pendidikan'), findsOneWidget);
        expect(find.text('Universitas Airlangga - Spesialis Anak'), findsOneWidget);
        expect(find.byIcon(Icons.school_outlined), findsWidgets);

        // 2. Memastikan card Tempat Praktik tetap ada
        expect(find.text('Tempat Praktik'), findsOneWidget);
        expect(find.text('RS PENDIDIKAN POLITEKNIK NEGERI JEMBER'), findsOneWidget);

        // 3. Memastikan Jadwal Praktik (kotak merah) SUDAH DIHAPUS
        expect(find.text('Jadwal Praktik'), findsNothing);
        expect(find.text('Tersedia Besok'), findsNothing);
      },
    );

    testWidgets('EditDokterAksesPage: memiliki section Pendidikan', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EditDokterAksesPage(doctor: testDoctor),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pendidikan'), findsOneWidget);
      expect(find.text('Tempat Praktik'), findsOneWidget);
      expect(find.text('Universitas Airlangga - Spesialis Anak'), findsOneWidget);
    });

    testWidgets('TambahDokterAksesPage: memiliki section Pendidikan', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TambahDokterAksesPage(createdByEmail: 'superadmin@pediagrow.com'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pendidikan'), findsOneWidget);
      expect(find.text('Tempat Praktik'), findsOneWidget);
    });

    testWidgets('ProfilDokterPage (Dokter Role): menampilkan section Pendidikan', (tester) async {
      DoctorService().setDoctorsForTesting([testDoctor]);

      await tester.pumpWidget(
        const MaterialApp(
          home: dokter_view.ProfilDokterPage(),
        ),
      );
      await tester.pump();

      expect(find.text('Pendidikan'), findsOneWidget);
      expect(find.text('Tempat Praktik'), findsOneWidget);
    });
  });
}
