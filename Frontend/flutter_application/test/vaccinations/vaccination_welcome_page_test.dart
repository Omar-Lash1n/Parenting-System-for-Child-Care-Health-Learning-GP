// --- test/vaccinations/vaccination_welcome_page_test.dart ---

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:Ajial/vaccinations/vaccination_welcome_page.dart';
import 'package:Ajial/vaccinations/vaccination_welcome_provider.dart';

// ─────────────────────── Helpers ────────────────────────────────────────────

/// Wraps the widget under test with the minimum necessary scaffolding:
///   • [MaterialApp] with RTL locale, the tested page as its home, and
///     the '/vaccination-welcome' route registered for navigation tests.
///   • A fresh [VaccinationWelcomeProvider] via [ChangeNotifierProvider].
Widget _buildTestHarness({
  VaccinationWelcomeProvider? provider,
}) {
  final testProvider = provider ?? VaccinationWelcomeProvider();

  return ChangeNotifierProvider<VaccinationWelcomeProvider>.value(
    value: testProvider,
    child: MaterialApp(
      locale: const Locale('ar'),
      routes: {
        '/vaccination-welcome': (ctx) => const VaccinationWelcomePage(),
        // Stub for the next page so navigation tests don't crash.
        '/vaccination-survey': (ctx) =>
            const Scaffold(body: Text('survey page')),
      },
      home: const VaccinationWelcomePage(),
    ),
  );
}

// ─────────────────────── Tests ───────────────────────────────────────────────

void main() {
  group('VaccinationWelcomePage', () {
    // ── 1. Static text renders ────────────────────────────────────────────
    testWidgets('renders the page title', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestHarness());
      await tester.pump(); // allow post-frame callbacks

      expect(find.text('تجهيز سجل التطعيمات'), findsOneWidget);
    });

    testWidgets('renders the subtitle containing the default child name',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestHarness());
      await tester.pump();

      // Provider not seeded → _childName == '' → displayName == 'طفلك'
      expect(find.textContaining('حتى الان'), findsOneWidget);
    });

    // ── 2. Both buttons are present ───────────────────────────────────────
    testWidgets('renders primary "بدء تسجيل التطعيمات" button',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestHarness());
      await tester.pump();

      expect(find.text('بدء تسجيل التطعيمات'), findsOneWidget);
    });

    testWidgets('renders secondary "رجوع" button', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestHarness());
      await tester.pump();

      expect(find.text('رجوع'), findsOneWidget);
    });

    // ── 3. Primary button navigates forward ──────────────────────────────
    testWidgets('tapping primary button navigates to /vaccination-survey',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestHarness());
      await tester.pump();

      await tester.tap(find.text('بدء تسجيل التطعيمات'));
      await tester.pumpAndSettle();

      // The stub page for /vaccination-survey should now be visible.
      expect(find.text('survey page'), findsOneWidget);
    });

    // ── 4. Back button pops the route ─────────────────────────────────────
    testWidgets('tapping "رجوع" navigates back', (WidgetTester tester) async {
      // Push the welcome page on top of a home page so there is something to
      // pop back to.
      await tester.pumpWidget(
        ChangeNotifierProvider<VaccinationWelcomeProvider>(
          create: (_) => VaccinationWelcomeProvider(),
          child: MaterialApp(
            routes: {
              '/': (ctx) => const Scaffold(body: Text('home')),
              '/vaccination-welcome': (ctx) => const VaccinationWelcomePage(),
            },
            initialRoute: '/',
          ),
        ),
      );
      await tester.pump();

      // Navigate to the welcome page.
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pushNamed('/vaccination-welcome');
      await tester.pumpAndSettle();

      expect(find.text('رجوع'), findsOneWidget);

      await tester.tap(find.text('رجوع'));
      await tester.pumpAndSettle();

      // Should have popped back to the home stub.
      expect(find.text('home'), findsOneWidget);
    });

    // ── 5. Child name renders dynamically ────────────────────────────────
    testWidgets('subtitle contains the child name after provider loads',
        (WidgetTester tester) async {
      final provider = VaccinationWelcomeProvider();

      await tester.pumpWidget(_buildTestHarness(provider: provider));
      await tester.pump();

      // Simulate the provider having loaded with a specific name.
      await provider.loadChildData(childName: 'سارة');
      await tester.pump();

      expect(find.textContaining('سارة'), findsOneWidget);
    });

    // ── 6. ChildProfileFrame is present in the widget tree ────────────────
    testWidgets('renders ChildProfileFrame widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestHarness());
      await tester.pump();

      // ChildProfileFrame is in the widget tree.
      expect(find.byWidgetPredicate((widget) {
        // Matches by checking for the outer SizedBox with our frame size.
        // This is a structural smoke test.
        return widget.runtimeType.toString() == 'ChildProfileFrame';
      }), findsOneWidget);
    });
  });
}
