import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/shared/widgets/pesan_cepat_widget.dart';

void main() {
  testWidgets('PesanCepatWidget renders properly and sends message on tap',
      (tester) async {
    String? sentMessage;
    String? copiedMessage;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PesanCepatWidget(
            isDoctor: false,
            isDark: false,
            onSendMessage: (msg) {
              sentMessage = msg;
            },
            onSelectToInput: (msg) {
              copiedMessage = msg;
            },
          ),
        ),
      ),
    );

    // Initial state: header visible, collapsed
    expect(find.text('Pesan Cepat'), findsOneWidget);
    expect(find.text('Lihat opsi'), findsOneWidget);
    expect(find.text('Terima kasih banyak, Dokter.'), findsNothing);

    // Tap header to expand
    await tester.tap(find.text('Pesan Cepat'));
    await tester.pumpAndSettle();

    expect(find.text('Tutup'), findsOneWidget);
    expect(find.text('Terima kasih banyak, Dokter.'), findsOneWidget);

    // Tap a template to send
    await tester.tap(find.text('Terima kasih banyak, Dokter.'));
    await tester.pumpAndSettle();

    expect(sentMessage, 'Terima kasih banyak, Dokter.');
    // Should auto-collapse after sending
    expect(find.text('Lihat opsi'), findsOneWidget);
  });

  testWidgets('PesanCepatWidget for doctor renders doctor templates',
      (tester) async {
    String? sentMessage;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PesanCepatWidget(
            isDoctor: true,
            isDark: false,
            onSendMessage: (msg) {
              sentMessage = msg;
            },
          ),
        ),
      ),
    );

    // Expand
    await tester.tap(find.text('Pesan Cepat'));
    await tester.pumpAndSettle();

    expect(find.text('Halo, ada yang bisa saya bantu untuk si kecil?'), findsOneWidget);

    // Tap doctor template
    await tester.tap(find.text('Halo, ada yang bisa saya bantu untuk si kecil?'));
    await tester.pumpAndSettle();

    expect(sentMessage, 'Halo, ada yang bisa saya bantu untuk si kecil?');
  });
}

