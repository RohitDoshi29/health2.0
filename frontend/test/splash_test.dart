import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/ui/core/widgets/light_beam_button.dart';
import 'package:heathify_app/ui/features/splash/splash_view.dart';

void main() {
  group('SplashView Flash Screen Tests', () {
    testWidgets('SplashView renders brand title, subtitle, and telemetry', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashView(),
        ),
      );

      expect(find.text('H E A L T H I F Y'), findsOneWidget);
      expect(find.text('AI NUTRITION COCKPIT 3.0'), findsOneWidget);
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
      expect(find.text('v2.4.0 • SECURE ENCRYPTED BIOMETRICS'), findsOneWidget);
    });

    testWidgets('SplashView in standalone mode displays Enter Cockpit LightBeamButton', (WidgetTester tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SplashView(
            isStandalone: true,
            onComplete: () {
              completed = true;
            },
          ),
        ),
      );

      expect(find.text('ENTER COCKPIT'), findsOneWidget);
      expect(find.byType(LightBeamButton), findsOneWidget);

      await tester.tap(find.text('ENTER COCKPIT'));
      await tester.pump();
      expect(completed, isTrue);
    });
  });
}
