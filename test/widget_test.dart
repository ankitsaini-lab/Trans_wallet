import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:transwallet/widgets/app_lock_overlay.dart';

void main() {
  testWidgets('AppLockOverlay basic smoke test', (WidgetTester tester) async {
    Get.reset();
    Get.testMode = true;

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AppLockOverlay(
            child: Text('Transwallet Smoke Test'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppLockOverlay), findsOneWidget);
    expect(find.text('Transwallet Smoke Test'), findsOneWidget);
  });
}
