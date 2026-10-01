import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heathify_app/ui/features/scan/scan_view.dart';
import 'package:heathify_app/ui/features/scan/scan_view_model.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('ScanView switches to Barcode tab and renders all elements', (tester) async {
    final vm = ScanViewModel();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ScanViewModel>.value(
          value: vm,
          child: const ScanView(),
        ),
      ),
    );

    expect(find.text('Snap Your Plate'), findsOneWidget);

    // Tap Barcode tab
    await tester.tap(find.text('Barcode'));
    await tester.pumpAndSettle();

    expect(find.text('Scan with Camera'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text("Rolled Oats (Bob's)"), findsOneWidget);
  });
}
