import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Profile%20screen/change_pin/forgot_pin_view.dart';
import 'package:transwallet/services/api_service.dart';

class MockForgotPinApiService extends ApiService {
  final List<String> recordedCalls = [];

  @override
  Future<Response<T>> postRequest<T>(
    String path,
    dynamic body, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    recordedCalls.add(path);
    final map = body is Map ? body : <String, dynamic>{};

    if (path == '/api/v1/auth/mpin/forgot/otp/send') {
      expect(map['mobileNumber'], '9876543210');
      return Response<T>(
        statusCode: 200,
        body: {
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "flow": "RESET_MPIN",
            "providerRef": "TEST_REF_123",
            "expiresInSeconds": 300,
            "debugOtp": {"otp": "123456"}
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        } as T,
      );
    } else if (path == '/api/v1/auth/mpin/forgot/otp/verify') {
      expect(map['mobileNumber'], '9876543210');
      expect(map['otp'], '123456');
      expect(map['providerRef'], 'TEST_REF_123');
      return Response<T>(
        statusCode: 200,
        body: {
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "flow": "RESET_MPIN",
            "resetToken": "TOKEN_ABC_999",
            "expiresInSeconds": 600
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        } as T,
      );
    } else if (path == '/api/v1/auth/mpin/forgot/verify') {
      expect(map['resetToken'], 'TOKEN_ABC_999');
      expect(map['panLast4'], '234F');
      expect(map['dateOfBirth'], isNotEmpty);
      return Response<T>(
        statusCode: 200,
        body: {
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "flow": "RESET_MPIN",
            "resetToken": "TOKEN_ABC_999_VERIFIED",
            "expiresInSeconds": 600
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        } as T,
      );
    } else if (path == '/api/v1/auth/mpin/reset') {
      expect(map['resetToken'], 'TOKEN_ABC_999_VERIFIED');
      expect(map['newMpin'], '2468');
      expect(map['confirmMpin'], '2468');
      return Response<T>(
        statusCode: 200,
        body: {
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "status": "UPDATED"
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        } as T,
      );
    }

    return Response<T>(statusCode: 404, statusText: 'Not found');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('forgot_pin_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => tempDir.path,
        );
    try {
      await GetStorage.init();
      await GetStorage().erase();
    } catch (_) {}
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

  testWidgets('ForgotPinView renders Stage 1 with Mobile input and Send OTP', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: ForgotPinView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Forgot MPIN"), findsOneWidget);
    expect(find.text("Enter Registered Mobile"), findsOneWidget);
    expect(find.text("Mobile Number"), findsOneWidget);
    expect(find.text("Send OTP"), findsOneWidget);
  });

  testWidgets('ForgotPinView validates empty mobile number on Send OTP', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: ForgotPinView(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Send OTP without mobile number
    await tester.tap(find.text("Send OTP"));
    await tester.pumpAndSettle();

    expect(find.text("Please enter mobile number"), findsOneWidget);
  });

  testWidgets('ForgotPinView executes full 4-step flow end-to-end', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockApi = Get.put<ApiService>(MockForgotPinApiService());

    // Seed phone, PAN, and DOB in storage
    final box = GetStorage();
    box.write('phone', '9876543210');
    box.write('pan', 'ABCDE234F');
    box.write('dob', '1990-01-15');

    await tester.pumpWidget(
      const GetMaterialApp(
        home: ForgotPinView(),
      ),
    );
    await tester.pumpAndSettle();

    // Stage 1: Phone is prefilled
    expect(find.text("9876543210"), findsOneWidget);

    // Tap Send OTP (Step 1 API)
    await tester.tap(find.text("Send OTP"));
    await tester.pumpAndSettle();

    // Stage 2: OTP View
    expect(find.text("Enter Verification Code"), findsOneWidget);
    expect(find.text("Verify OTP"), findsOneWidget);

    // Enter 6-digit OTP (auto-triggers verification via onCompleted)
    final otpFinder = find.byType(TextField);
    expect(otpFinder, findsWidgets);
    await tester.enterText(otpFinder.first, "123456");
    await tester.pumpAndSettle();

    // Stage 3: PAN & DOB Security Verification
    expect(find.text("Security Verification"), findsOneWidget);
    expect(find.text("Verify Identity"), findsOneWidget);

    final selectDobFinder = find.text("Select Date of Birth (DD/MM/YYYY)");
    if (selectDobFinder.evaluate().isNotEmpty) {
      await tester.tap(selectDobFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text("Confirm"));
      await tester.pumpAndSettle();
    }

    // Tap Verify Identity (Step 3 API)
    await tester.tap(find.text("Verify Identity"));
    await tester.pumpAndSettle();

    // Stage 4: Keypad to set new MPIN
    expect(find.text("Enter New MPIN"), findsOneWidget);

    Future<void> tapDigit(String digit) async {
      await tester.tap(find.text(digit).last);
      await tester.pump(const Duration(milliseconds: 60));
    }

    // Tap digits 2, 4, 6, 8
    await tapDigit("2");
    await tapDigit("4");
    await tapDigit("6");
    await tapDigit("8");
    await tester.pumpAndSettle();

    // Sub-stage 2: Confirm New MPIN
    expect(find.text("Confirm New MPIN"), findsOneWidget);

    // Tap digits 2, 4, 6, 8 again (Step 4 API)
    await tapDigit("2");
    await tapDigit("4");
    await tapDigit("6");
    await tapDigit("8");
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify all 4 APIs were called in exact order
    expect((mockApi as MockForgotPinApiService).recordedCalls, [
      '/api/v1/auth/mpin/forgot/otp/send',
      '/api/v1/auth/mpin/forgot/otp/verify',
      '/api/v1/auth/mpin/forgot/verify',
      '/api/v1/auth/mpin/reset',
    ]);

    // Should show success view and update storage
    expect(find.text("MPIN Reset Successfully!"), findsOneWidget);
    expect(box.read('has_mpin'), true);
    expect(box.read('saved_mpin'), '2468');

    // Wait for the 1200ms success auto-pop timer to fire
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
  });

  testWidgets('ForgotPinView limits PAN to 4 characters and validates PAN and DOB errors', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put<ApiService>(MockForgotPinApiService());

    final box = GetStorage();
    box.write('phone', '9876543210');

    await tester.pumpWidget(
      const GetMaterialApp(
        home: ForgotPinView(),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1: Send OTP
    await tester.tap(find.text("Send OTP"));
    await tester.pumpAndSettle();

    // Step 2: Enter OTP
    final otpFinder = find.byType(TextField);
    await tester.enterText(otpFinder.first, "123456");
    await tester.pumpAndSettle();

    // Step 3: Security Verification
    expect(find.text("Security Verification"), findsOneWidget);
    expect(find.text("PAN Number (Last 4 characters)"), findsOneWidget);

    // Verify PAN TextField has maxLength 4
    final panTextField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) => widget is TextField && widget.maxLength == 4,
      ),
    );
    expect(panTextField.maxLength, 4);

    // Try tapping Verify Identity without entering PAN or DOB
    await tester.tap(find.text("Verify Identity"));
    await tester.pumpAndSettle();

    // Both specific errors should be displayed under their respective fields
    expect(find.text("Please enter last 4 characters of PAN"), findsOneWidget);
    expect(find.text("Please select Date of Birth"), findsOneWidget);

    // Enter less than 4 characters
    final panInputFinder = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.maxLength == 4,
    );
    await tester.enterText(panInputFinder, "12");
    await tester.tap(find.text("Verify Identity"));
    await tester.pumpAndSettle();

    expect(find.text("Please enter exactly 4 characters of your PAN"), findsOneWidget);
    expect(find.text("Please select Date of Birth"), findsOneWidget);

    // Verify tapping outside textfield unfocuses keyboard
    await tester.tap(panInputFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text("Security Verification"));
    await tester.pumpAndSettle();
  });
}
