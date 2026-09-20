import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/features/pengguna/cek_stunting/form_cek_stunting_page.dart';
import 'package:pediagrow/features/pengguna/cek_stunting/hasil_cek_stunting_page.dart';
import 'package:pediagrow/features/pengguna/cek_stunting/preview_hasil_cek_stunting_page.dart';

void main() {
  group('HasilCekStuntingPage Widget Tests', () {
    testWidgets('Renders all examination info, warning box, prediction card, and recommendations',
        (WidgetTester tester) async {
      const result = StuntingAnalysisResult(
        status: StuntingStatus.normal,
        statusLabel: 'Normal (Pertumbuhan Optimal)',
        zScoreHeightForAge: -0.2,
        zScoreWeightForAge: 0.1,
        confidenceProbability: 0.96,
        description: 'Pertumbuhan tinggi dan berat badan si Kecil berada dalam batas standar WHO.',
        recommendations: [
          'Pemberian pola asuh yang tepat',
          'Memberikan MPASI yang optimal',
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HasilCekStuntingPage(
            result: result,
            namaAnak: 'Kaia Anastasya',
            jenisKelamin: 'Perempuan',
            usiaDeskripsi: '1 tahun 3 bulan 4 Hari',
            tanggalLahir: '22/05/2025',
            tanggalPemeriksaan: '26/08/2026',
            beratBadanLahir: '2.9',
            tinggiBadanLahir: '50',
            beratBadanSekarang: 9.1,
            tinggiBadanSekarang: 77.0,
            isAsiEksklusif: true,
          ),
        ),
      );

      await tester.pump();

      // Header 56 dp
      expect(find.text('Cek Stunting'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Judul Konten
      expect(find.text('Hasil Analisis Stunting'), findsOneWidget);

      // Form Field Information
      expect(find.text('Kaia Anastasya'), findsOneWidget);
      expect(find.text('Perempuan'), findsOneWidget);
      expect(find.text('22/05/2025'), findsOneWidget);
      expect(find.text('26/08/2026'), findsOneWidget);
      expect(find.text('2.9'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('9.1'), findsOneWidget);
      expect(find.text('77'), findsOneWidget);
      expect(find.text('Ya'), findsOneWidget);
      expect(find.text('Tidak'), findsOneWidget);

      // Warning / Information Box
      expect(
        find.textContaining('Hasil cek stunting tidak akurat 100%'),
        findsOneWidget,
      );

      // Prediction Card for Normal
      expect(find.text('TIDAK STUNTING'), findsOneWidget);

      // Recommendation Card
      expect(find.text('Rekomendasi'), findsOneWidget);
      expect(find.textContaining('Upaya yang bisa dilakukan'), findsOneWidget);
      expect(find.text('Pemberian pola asuh yang tepat'), findsOneWidget);

      // Action Buttons
      expect(find.text('Cetak Hasil'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);

      // Bottom Navigation Bar Items
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Konsultasi'), findsOneWidget);
      expect(find.text('Riwayat Konsultasi'), findsOneWidget);
      expect(find.text('Profil Ibu'), findsOneWidget);
    });

    testWidgets('Displays STUNTING and red background when status is stunted',
        (WidgetTester tester) async {
      const result = StuntingAnalysisResult(
        status: StuntingStatus.severelyStunted,
        statusLabel: 'Sangat Pendek (Severely Stunted)',
        zScoreHeightForAge: -3.2,
        zScoreWeightForAge: -2.1,
        confidenceProbability: 0.95,
        description: 'Pertumbuhan tinggi si Kecil berada di bawah standar deviasi -3 SD WHO.',
        recommendations: [
          'Konsultasikan segera dengan Dokter Spesialis Anak.',
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HasilCekStuntingPage(
            result: result,
            namaAnak: 'Kaia Anastasya',
            jenisKelamin: 'Perempuan',
            usiaDeskripsi: '1 tahun 3 bulan 4 Hari',
            tanggalLahir: '22/05/2025',
            tanggalPemeriksaan: '26/08/2026',
            beratBadanLahir: '2.9',
            tinggiBadanLahir: '50',
            beratBadanSekarang: 7.0,
            tinggiBadanSekarang: 68.0,
            isAsiEksklusif: false,
          ),
        ),
      );

      await tester.pump();

      // Prediction Card for Stunted
      expect(find.text('STUNTING'), findsOneWidget);
      expect(find.text('TIDAK STUNTING'), findsNothing);
    });

    testWidgets('Tapping Cetak Hasil navigates to PreviewHasilCekStuntingPage',
        (WidgetTester tester) async {
      const result = StuntingAnalysisResult(
        status: StuntingStatus.normal,
        statusLabel: 'Normal',
        zScoreHeightForAge: 0.0,
        zScoreWeightForAge: 0.0,
        confidenceProbability: 0.95,
        description: 'Normal',
        recommendations: ['Rekomendasi'],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HasilCekStuntingPage(
            result: result,
            namaAnak: 'Kaia Anastasya',
            jenisKelamin: 'Perempuan',
            usiaDeskripsi: '15 bulan',
            tanggalLahir: '22/05/2025',
            tanggalPemeriksaan: '26/08/2026',
            beratBadanLahir: '2.9',
            tinggiBadanLahir: '50',
            beratBadanSekarang: 9.1,
            tinggiBadanSekarang: 77.0,
            isAsiEksklusif: true,
          ),
        ),
      );

      await tester.binding.setSurfaceSize(const Size(800, 1400));
      await tester.pump();

      // Ensure button is visible in scrollview and tap
      final cetakFinder = find.text('Cetak Hasil');
      await tester.ensureVisible(cetakFinder);
      await tester.pumpAndSettle();

      await tester.tap(cetakFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Preview page is pushed
      expect(find.byType(PreviewHasilCekStuntingPage), findsOneWidget);
      expect(find.textContaining('Cetak Hasil'), findsWidgets);

      // Verify back button on preview returns to HasilCekStuntingPage
      final backFinder = find.byIcon(Icons.arrow_back);
      expect(backFinder, findsWidgets);
      await tester.tap(backFinder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(HasilCekStuntingPage), findsOneWidget);
      expect(find.text('Hasil Analisis Stunting'), findsOneWidget);
    });
  });
}
