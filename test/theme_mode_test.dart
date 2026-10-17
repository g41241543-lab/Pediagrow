import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/core/services/theme_service.dart';
import 'package:pediagrow/features/pengguna/profil/tampilan_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeService Tests', () {
    test('Default theme should be system', () {
      final service = ThemeService();
      expect(service.currentMode, AppThemeMode.system);
      expect(service.flutterThemeMode, ThemeMode.system);
    });

    test('Can change theme to light and dark', () async {
      final service = ThemeService();

      await service.setTheme(AppThemeMode.light);
      expect(service.currentMode, AppThemeMode.light);
      expect(service.flutterThemeMode, ThemeMode.light);

      await service.setTheme(AppThemeMode.dark);
      expect(service.currentMode, AppThemeMode.dark);
      expect(service.flutterThemeMode, ThemeMode.dark);

      // Restore to system
      await service.setTheme(AppThemeMode.system);
      expect(service.currentMode, AppThemeMode.system);
      expect(service.flutterThemeMode, ThemeMode.system);
    });
  });

  group('TampilanPage Widget Tests', () {
    testWidgets('Renders all 3 theme options correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeService.lightTheme,
          darkTheme: ThemeService.darkTheme,
          themeMode: ThemeService().flutterThemeMode,
          home: const TampilanPage(),
        ),
      );

      // Verify Header
      expect(find.text('Tampilan'), findsOneWidget);
      expect(
        find.textContaining('Pilih tema aplikasi sesuai kenyamanan Anda'),
        findsOneWidget,
      );

      // Verify 3 options exist
      expect(find.text('Default Sistem'), findsOneWidget);
      expect(find.text('Mode Terang'), findsOneWidget);
      expect(find.text('Mode Gelap'), findsOneWidget);

      // Tap Mode Gelap
      await tester.tap(find.text('Mode Gelap'));
      await tester.pumpAndSettle();

      expect(ThemeService().currentMode, AppThemeMode.dark);

      // Tap Mode Terang
      await tester.tap(find.text('Mode Terang'));
      await tester.pumpAndSettle();

      expect(ThemeService().currentMode, AppThemeMode.light);

      // Reset to system
      await tester.tap(find.text('Default Sistem'));
      await tester.pumpAndSettle();

      expect(ThemeService().currentMode, AppThemeMode.system);
    });
  });
}
