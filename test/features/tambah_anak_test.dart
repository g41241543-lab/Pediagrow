import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/core/services/child_service.dart';
import 'package:pediagrow/features/pengguna/profil_anak/tambah_anak_page.dart';

void main() {
  setUp(() {
    ChildService().clear();
  });

  Widget buildTestWidget() {
    return const MaterialApp(
      home: TambahAnakPage(),
    );
  }

  group('TambahAnakPage UI Rendering & Initial State', () {
    testWidgets('Merender seluruh komponen utama form dan header', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Tambah Profil Anak'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Foto profil section
      expect(find.text('Unggah Foto Anda'), findsOneWidget);

      // Field labels
      expect(find.textContaining('Nama Lengkap', skipOffstage: false), findsWidgets);
      expect(find.textContaining('Tanggal Lahir', skipOffstage: false), findsWidgets);
      expect(find.textContaining('Jenis Kelamin', skipOffstage: false), findsWidgets);
      expect(find.text('Data Kelahiran', skipOffstage: false), findsOneWidget);
      expect(find.text('Foto Si Kecil', skipOffstage: false), findsOneWidget);
      expect(find.text('+ Unggah Foto', skipOffstage: false), findsOneWidget);
      expect(find.textContaining('Apakah Anak Anda Lahir Prematur?', skipOffstage: false), findsWidgets);
      expect(find.textContaining('Berat Badan Saat Lahir (kg)', skipOffstage: false), findsWidgets);
      expect(find.textContaining('Tinggi Badan Saat Lahir (cm)', skipOffstage: false), findsWidgets);
      expect(find.textContaining('Lingkar Kepala Saat Lahir (cm)', skipOffstage: false), findsWidgets);
      expect(find.textContaining('Alergi', skipOffstage: false), findsWidgets);

      // Tombol Simpan
      expect(find.text('Simpan', skipOffstage: false), findsOneWidget);

      // Bottom Navigation Bar
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Konsultasi'), findsOneWidget);
      expect(find.text('Riwayat Konsultasi'), findsOneWidget);
      expect(find.text('Profil Ibu'), findsOneWidget);
    });

    testWidgets('Field kondisional awalnya tersembunyi', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Usia Kehamilan & Sebutkan Alergi belum muncul
      expect(find.textContaining('Usia Kehamilan Saat Lahir', skipOffstage: false), findsNothing);
      expect(find.textContaining('Sebutkan Alergi', skipOffstage: false), findsNothing);
    });
  });

  group('Kondisional Radio Buttons', () {
    testWidgets('Memilih Prematur Ya memunculkan input Usia Kehamilan', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll ke bagian prematur
      final prematurYa = find.text('Ya');
      await tester.ensureVisible(prematurYa);
      await tester.tap(prematurYa);
      await tester.pumpAndSettle();

      // Field Usia Kehamilan harus muncul
      expect(find.textContaining('Usia Kehamilan Saat Lahir (minggu)', skipOffstage: false), findsOneWidget);

      // Tap Tidak -> field harus hilang
      final prematurTidak = find.text('Tidak').first;
      await tester.tap(prematurTidak);
      await tester.pumpAndSettle();

      expect(find.textContaining('Usia Kehamilan Saat Lahir (minggu)', skipOffstage: false), findsNothing);
    });

    testWidgets('Memilih Alergi Ada memunculkan input Sebutkan Alergi', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll ke bagian Alergi
      final alergiAda = find.text('Ada');
      await tester.ensureVisible(alergiAda);
      await tester.tap(alergiAda);
      await tester.pumpAndSettle();

      expect(find.textContaining('Sebutkan Alergi', skipOffstage: false), findsOneWidget);

      // Tap Tidak pada Alergi
      final alergiWidgets = find.text('Tidak');
      // alergi "Tidak" adalah tombol kedua (setelah prematur "Tidak")
      await tester.tap(alergiWidgets.last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Sebutkan Alergi', skipOffstage: false), findsNothing);
    });
  });

  group('Validasi Form saat Simpan ditekan', () {
    testWidgets('Menampilkan pesan error serentak ketika field wajib kosong', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tekan tombol Simpan tanpa mengisi form
      final simpanBtn = find.text('Simpan');
      await tester.ensureVisible(simpanBtn);
      await tester.tap(simpanBtn);
      await tester.pumpAndSettle();

      // Validasi error harus muncul
      expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);
      expect(find.text('Tanggal lahir wajib diisi'), findsOneWidget);
      expect(find.text('Jenis kelamin anak wajib dipilih'), findsOneWidget);
      expect(find.text('Status kelahiran prematur wajib dipilih'), findsOneWidget);
      expect(find.text('Berat badan saat lahir wajib diisi'), findsOneWidget);
      expect(find.text('Tinggi badan saat lahir wajib diisi'), findsOneWidget);
      expect(find.text('Lingkar kepala saat lahir wajib diisi'), findsOneWidget);
      expect(find.text('Status alergi wajib dipilih'), findsOneWidget);

      // Data tidak boleh tersimpan ke ChildService
      expect(ChildService().children.isEmpty, isTrue);
    });
  });

  group('Konfirmasi Tombol Kembali', () {
    testWidgets('Menampilkan dialog konfirmasi saat back ditekan jika form terisi', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Isi Nama Lengkap
      final namaField = find.byType(TextFormField).first;
      await tester.enterText(namaField, 'Kaia Anastasya');
      await tester.pumpAndSettle();

      // Tekan tombol kembali di header
      final backButton = find.byIcon(Icons.arrow_back);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Dialog konfirmasi harus muncul
      expect(find.text('Data Belum Tersimpan'), findsOneWidget);
      expect(find.text('Lanjutkan Mengisi Profil'), findsOneWidget);
      expect(find.text('Ya, Kembali ke Beranda'), findsOneWidget);

      // Tekan Lanjutkan Mengisi Profil -> dialog tertutup, data tetap ada
      await tester.tap(find.text('Lanjutkan Mengisi Profil'));
      await tester.pumpAndSettle();

      expect(find.text('Data Belum Tersimpan'), findsNothing);
      expect(find.text('Kaia Anastasya'), findsOneWidget);
    });
  });
}
