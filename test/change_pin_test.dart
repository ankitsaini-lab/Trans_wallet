import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Profile%20screen/change_pin/change_pin_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    HttpOverrides.global = null;
    tempDir = await Directory.systemTemp.createTemp('change_pin_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => tempDir.path,
        );
    await GetStorage.init();
    await GetStorage().erase();
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() async {
    Get.reset();
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  testWidgets('ChangePinView asks for Current PIN first when user has existing PIN', (
    WidgetTester tester,
  ) async {
    final box = GetStorage();
    box.write('saved_mpin', '1234');
    box.write('has_mpin', true);

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: ChangePinView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Change Pin"), findsWidgets);
    expect(find.text("Enter Current PIN"), findsOneWidget);
    expect(find.text("Enter your existing 4-digit PIN to verify your identity"), findsOneWidget);
    expect(find.text("Forgot Current PIN?"), findsOneWidget);
  });

  testWidgets('ChangePinView shows error when incorrect Current PIN is entered', (
    WidgetTester tester,
  ) async {
    final box = GetStorage();
    box.write('saved_mpin', '1234');
    box.write('has_mpin', true);

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: ChangePinView(),
      ),
    );
    await tester.pumpAndSettle();

    // Enter wrong PIN: '9', '9', '9', '9'
    for (int i = 0; i < 4; i++) {
      await tester.tap(find.text('9'));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text("Incorrect current PIN. Please try again."), findsOneWidget);
  });

  testWidgets('ChangePinView advances to Step 2 (Enter New PIN) when correct Current PIN is entered', (
    WidgetTester tester,
  ) async {
    final box = GetStorage();
    box.write('saved_mpin', '1234');
    box.write('has_mpin', true);

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: ChangePinView(),
      ),
    );
    await tester.pumpAndSettle();

    // Enter correct PIN: 1, 2, 3, 4
    await tester.tap(find.text('1'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('2'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('3'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('4'));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text("Enter New PIN"), findsOneWidget);
    expect(find.text("Set a new 4-digit PIN for securing your transactions"), findsOneWidget);
  });

  testWidgets('ChangePinView prevents setting new PIN same as current PIN', (
    WidgetTester tester,
  ) async {
    final box = GetStorage();
    box.write('saved_mpin', '1234');
    box.write('has_mpin', true);

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: ChangePinView(),
      ),
    );
    await tester.pumpAndSettle();

    // Current PIN: 1, 2, 3, 4
    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Try same PIN as new PIN: 1, 2, 3, 4
    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text("New PIN cannot be the same as your current PIN."), findsOneWidget);
  });

  testWidgets('ChangePinView prevents mismatched confirmation PIN', (
    WidgetTester tester,
  ) async {
    final box = GetStorage();
    box.write('saved_mpin', '1234');
    box.write('has_mpin', true);

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: ChangePinView(),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1: Current PIN: 1, 2, 3, 4
    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Step 2: New PIN: 5, 6, 7, 8
    for (final digit in ['5', '6', '7', '8']) {
      await tester.tap(find.text(digit));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text("Confirm New PIN"), findsOneWidget);

    // Step 3: Mismatched Confirm PIN: 5, 6, 7, 9
    for (final digit in ['5', '6', '7', '9']) {
      await tester.tap(find.text(digit));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text("PINs do not match. Please try again."), findsOneWidget);
  });

  testWidgets('ChangePinView renders cleanly on compact Android screens with 3-button nav bar without overflow', (
    WidgetTester tester,
  ) async {
    final box = GetStorage();
    box.write('saved_mpin', '1234');
    box.write('has_mpin', true);

    // Compact screen (e.g. 360 x 640 @ 2.0x, physical size 720 x 1280) with 48dp 3-button nav bar padding
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0;
    tester.view.padding = const FakeViewPadding(bottom: 96); // 48dp * 2.0 = 96px
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: ChangePinView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Change Pin"), findsWidgets);
    expect(find.text("Enter Current PIN"), findsOneWidget);
    // Keypad digits should be visible and pressable
    expect(find.text('0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

