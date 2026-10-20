import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/core/services/theme_service.dart';
import 'package:pediagrow/features/auth/auth_choice_page.dart';
import 'package:pediagrow/features/auth/login_page.dart';
import 'package:pediagrow/features/auth/register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildThemedApp({required Widget child, required ThemeMode mode}) {
    return MaterialApp(
      theme: ThemeService.lightTheme,
      darkTheme: ThemeService.darkTheme,
      themeMode: mode,
      home: child,
    );
  }

  group('Auth Pages Dark and Light Mode Tests', () {
    testWidgets('AuthChoicePage respects light and dark mode', (tester) async {
      // Test Light Mode
      await tester.pumpWidget(
        buildThemedApp(
          child: const AuthChoicePage(),
          mode: ThemeMode.light,
        ),
      );
      await tester.pumpAndSettle();

      var scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.white);

      // Test Dark Mode
      await tester.pumpWidget(
        buildThemedApp(
          child: const AuthChoicePage(),
          mode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF0B1014));
    });

    testWidgets('LoginPage respects light and dark mode', (tester) async {
      // Test Light Mode
      await tester.pumpWidget(
        buildThemedApp(
          child: const LoginPage(),
          mode: ThemeMode.light,
        ),
      );
      await tester.pumpAndSettle();

      var scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.white);

      // Test Dark Mode
      await tester.pumpWidget(
        buildThemedApp(
          child: const LoginPage(),
          mode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF0B1014));
    });

    testWidgets('RegisterPage respects light and dark mode', (tester) async {
      // Test Light Mode
      await tester.pumpWidget(
        buildThemedApp(
          child: const RegisterPage(),
          mode: ThemeMode.light,
        ),
      );
      await tester.pumpAndSettle();

      var scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.white);

      // Test Dark Mode
      await tester.pumpWidget(
        buildThemedApp(
          child: const RegisterPage(),
          mode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF0B1014));
    });
  });
}
