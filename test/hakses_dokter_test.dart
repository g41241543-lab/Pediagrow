import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/core/services/doctor_service.dart';
import 'package:pediagrow/core/services/staff_auth_service.dart';
import 'package:pediagrow/features/pmik_superadmin/beranda/kelola_resep_mpasi/daftar_resep_mpasi_admin_page.dart';
import 'package:pediagrow/features/pmik_superadmin/profil/hak_akses/daftar_dokter_akses_page.dart';
import 'package:pediagrow/features/pmik_superadmin/profil/hak_akses/edit_dokter_akses_page.dart';
import 'package:pediagrow/features/pmik_superadmin/profil/hak_akses/hapus_dokter_akses_page.dart';
import 'package:pediagrow/features/pmik_superadmin/profil/hak_akses/tambah_dokter_akses_page.dart';
import 'package:pediagrow/models/doctor_model.dart';
import 'package:pediagrow/models/doctor_permissions.dart';
import 'package:pediagrow/models/staff_account_model.dart';
import 'package:pediagrow/pmik_superadmin/kelola_artikel/daftar_artikel_page.dart';
import 'package:pediagrow/shared/widgets/pedia_bottom_nav_bar.dart';

void main() {
  group('Hakses Dokter Pages Tests', () {
    testWidgets('DaftarDokterAksesPage renders header, search bar, and bottom nav',
        (tester) async {
      DoctorService().setDoctorsForTesting([
        const DoctorModel(
          id: 'doc-1',
          name: 'dr. Ahmad Nuri, Sp. A',
          specialization: 'Spesialis Anak',
        ),
      ]);

      await tester.pumpWidget(
        const MaterialApp(
          home: DaftarDokterAksesPage(),
        ),
      );
      await tester.pump();

      expect(find.text('Daftar Dokter'), findsOneWidget);
      expect(find.text('Cari Dokter'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
      expect(find.text('dr. Ahmad Nuri, Sp. A'), findsOneWidget);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Konsultasi'), findsOneWidget);
      expect(find.text('Riwayat Konsultasi'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('TambahDokterAksesPage renders fields, practice places, and 16 permissions',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TambahDokterAksesPage(
            createdByEmail: 'superadmin@pediagrow.com',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Tambah Dokter'), findsOneWidget);
      expect(find.text('Unggah Foto'), findsOneWidget);
      expect(find.text('Tempat Praktik'), findsOneWidget);
      // "Hak Akses" appears as header and permission item #16
      expect(find.text('Hak Akses'), findsNWidgets(2));
      expect(find.text('Simpan'), findsOneWidget);

      // Verify permissions are displayed
      for (final p in DoctorPermissions.allPermissions.take(5)) {
        expect(find.text(p.label), findsWidgets);
      }
      expect(find.text('Daftar Resep MPASI'), findsOneWidget);
      expect(find.text('Edit Resep MPASI'), findsOneWidget);
      expect(find.text('Daftar Artikel Kesehatan'), findsOneWidget);
      expect(find.text('Edit Artikel Kesehatan'), findsOneWidget);
    });

    testWidgets('EditDokterAksesPage renders prefilled doctor data',
        (tester) async {
      const testDoctor = DoctorModel(
        id: 'doc-1',
        name: 'dr. Ahmad Nuri, Sp. A',
        specialization: 'Spesialis Anak',
        experienceYears: 7,
        strNumber: '3511201402012222',
        placesOfPractice: ['RS Citra Husada Jember'],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: EditDokterAksesPage(
            doctor: testDoctor,
          ),
        ),
      );
      await tester.pump();

      // "Profil" appears in header and as permission item #15
      expect(find.text('Profil'), findsNWidgets(2));
      expect(find.text('dr. Ahmad Nuri, Sp. A'), findsOneWidget);
      expect(find.text('Spesialis Anak'), findsOneWidget);
      expect(find.text('RS Citra Husada Jember'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
    });

    testWidgets('HapusDokterAksesPage renders confirmation dialog matching image 4',
        (tester) async {
      const testDoctor = DoctorModel(
        id: 'doc-1',
        name: 'dr. Ahmad Nuri, Sp. A',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HapusDokterAksesPage(
              doctor: testDoctor,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Hapus Data'), findsOneWidget);
      expect(
        find.text(
          'Mohon pastikan ulang sebelum menghapus akun Dokter. Apakah anda yakin ingin menghapus?',
        ),
        findsOneWidget,
      );
      expect(find.text('Ya'), findsOneWidget);
      expect(find.text('Tidak'), findsOneWidget);
    });

    testWidgets('DaftarResepMpasiAdminPage shows navbar and controls CRUD by doctor edit permission',
        (tester) async {
      // 1. Tanpa izin edit (view only)
      StaffAuthService().setStaff(
        const StaffAccount(
          id: 'staff-doc-1',
          name: 'dr. Budi',
          email: 'budi@pediagrow.com',
          passwordHash: 'dummy_hash',
          createdBy: 'superadmin',
          role: StaffRole.dokter,
          permissions: {'edit_resep_mpasi': false},
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: DaftarResepMpasiAdminPage(),
        ),
      );
      await tester.pump();

      // Navbar harus tetap ada
      expect(find.byType(PediaBottomNavBar), findsOneWidget);
      // Tombol tambah (+) tidak ada
      expect(find.byIcon(Icons.add), findsNothing);

      // 2. Dengan izin edit (plek ketiplek PMIK)
      StaffAuthService().setStaff(
        const StaffAccount(
          id: 'staff-doc-1',
          name: 'dr. Budi',
          email: 'budi@pediagrow.com',
          passwordHash: 'dummy_hash',
          createdBy: 'superadmin',
          role: StaffRole.dokter,
          permissions: {'edit_resep_mpasi': true},
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: DaftarResepMpasiAdminPage(),
        ),
      );
      await tester.pump();

      // Navbar ada & tombol tambah (+) muncul
      expect(find.byType(PediaBottomNavBar), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('DaftarArtikelPage shows navbar and controls CRUD by doctor edit permission',
        (tester) async {
      // 1. Tanpa izin edit (view only)
      StaffAuthService().setStaff(
        const StaffAccount(
          id: 'staff-doc-1',
          name: 'dr. Budi',
          email: 'budi@pediagrow.com',
          passwordHash: 'dummy_hash',
          createdBy: 'superadmin',
          role: StaffRole.dokter,
          permissions: {'edit_artikel_kesehatan': false},
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: DaftarArtikelPage(),
        ),
      );
      await tester.pump();

      // Navbar harus tetap ada
      expect(find.byType(PediaBottomNavBar), findsOneWidget);
      // Tombol tambah (+) tidak ada
      expect(find.byIcon(Icons.add), findsNothing);

      // 2. Dengan izin edit (plek ketiplek PMIK)
      StaffAuthService().setStaff(
        const StaffAccount(
          id: 'staff-doc-1',
          name: 'dr. Budi',
          email: 'budi@pediagrow.com',
          passwordHash: 'dummy_hash',
          createdBy: 'superadmin',
          role: StaffRole.dokter,
          permissions: {'edit_artikel_kesehatan': true},
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: DaftarArtikelPage(),
        ),
      );
      await tester.pump();

      // Navbar ada & tombol tambah (+) muncul
      expect(find.byType(PediaBottomNavBar), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
