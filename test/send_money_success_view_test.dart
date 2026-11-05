import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendMoney_Success_Controller.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendMoney_Success_View.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('success_test_');
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

  testWidgets('SendMoneySuccessView renders PhonePe-inspired UI elements properly', (tester) async {
    final controller = Get.put(SendMoneySuccessController());
    controller.amount = 5000.0;
    controller.recipient = {
      'name': 'Jane Doe',
      'phone': '9876543210',
      'accountNumber': '987654321098',
    };
    controller.providerRef = '835133872';

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SendMoneySuccessView(),
      ),
    );

    // Let entry animations run
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Heading & Subtitle
    expect(find.text("Money Sent Successfully!"), findsOneWidget);
    expect(
      find.text("Your money has been sent successfully to the recipient."),
      findsOneWidget,
    );

    // Verify Amount (Prominent and in Details card)
    expect(find.text("₹5,000"), findsNWidgets(2));

    // Verify Recipient & Masked Account
    expect(find.text("Jane Doe"), findsOneWidget);
    expect(find.text("A/c •••• 1098"), findsOneWidget);

    // Verify Transaction Details
    expect(find.text("Transaction Amount"), findsOneWidget);
    expect(find.text("Date & Time"), findsOneWidget);
    expect(find.text("Transaction ID / UTR"), findsOneWidget);
    expect(find.text("835133872"), findsOneWidget);

    // Verify Action Buttons
    expect(find.text("View Receipt"), findsOneWidget);
    expect(find.text("Back to Home"), findsOneWidget);
  });

  testWidgets('SendMoneySuccessView renders without overflow on compact 360x640 screens', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = Get.put(SendMoneySuccessController());
    controller.amount = 1250.0;
    controller.recipient = {
      'name': 'Rahul Sharma',
      'phone': '9876543210',
    };
    controller.externalTransactionId = 'C2C_EXT_999999999999';

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SendMoneySuccessView(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.text("Money Sent Successfully!"), findsOneWidget);
    expect(find.text("View Receipt"), findsOneWidget);
    expect(find.text("Back to Home"), findsOneWidget);
  });

  testWidgets('SendMoneySuccessView manages bottom insets on devices with Android 3-button navigation', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(bottom: 48, top: 24);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
    });

    final controller = Get.put(SendMoneySuccessController());
    controller.amount = 2500.0;
    controller.recipient = {
      'name': 'Priya Singh',
      'phone': '9123456789',
    };
    controller.providerRef = 'REF123456';

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SendMoneySuccessView(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    // Both action buttons must be visible in viewport
    expect(find.text("View Receipt"), findsOneWidget);
    expect(find.text("Back to Home"), findsOneWidget);
  });

  testWidgets('SendMoneySuccessView manages iPhone home indicator bottom insets (padding.bottom = 34)', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(bottom: 34, top: 59);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
    });

    final controller = Get.put(SendMoneySuccessController());
    controller.amount = 750.0;
    controller.recipient = {
      'name': 'Vikram Patel',
      'phone': '9988776655',
    };
    controller.externalTransactionId = 'TXN_IPHONE_001';

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SendMoneySuccessView(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.text("Money Sent Successfully!"), findsOneWidget);
    expect(find.text("View Receipt"), findsOneWidget);
    expect(find.text("Back to Home"), findsOneWidget);
  });

  testWidgets('SendMoneySuccessView handles ultra-small screens (320x568) and large accessibility text scaling', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    final controller = Get.put(SendMoneySuccessController());
    controller.amount = 100.0;
    controller.recipient = {
      'name': 'Amit Kumar',
      'phone': '9876500000',
    };
    controller.providerRef = 'SMALL999';

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SendMoneySuccessView(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.text("Money Sent Successfully!"), findsOneWidget);
    expect(find.text("View Receipt"), findsOneWidget);
    expect(find.text("Back to Home"), findsOneWidget);
  });
}
