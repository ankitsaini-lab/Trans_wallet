import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Onboarding%20Screen/onboardingscreen_View.dart';
import 'package:transwallet/products/Onboarding%20Screen/onboardingscreen_controller.dart';
import 'package:transwallet/products/login_singupscreen/login_singupscreen_View.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('onboarding_test_');
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

  testWidgets('OnboardingscreenView renders Skip button and navigates to login screen on tap', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/onboarding',
        getPages: [
          GetPage(name: '/onboarding', page: () => const OnboardingscreenView()),
          GetPage(name: '/login_singupview', page: () => const LoginSingupscreenView()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final controller = Get.find<OnboardingscreenController>();

    // Verify Skip button is present on first screen
    expect(find.text('Skip'), findsOneWidget);
    expect(controller.currentPage.value, 0);

    // Tap Skip button
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Verify redirected directly to login screen (Welcome text visible)
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Step into simpler payments'), findsOneWidget);
  });

  testWidgets('Onboarding page navigation updates currentPage and controller.skip() navigates to login', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/onboarding',
        getPages: [
          GetPage(name: '/onboarding', page: () => const OnboardingscreenView()),
          GetPage(name: '/login_singupview', page: () => const LoginSingupscreenView()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final controller = Get.find<OnboardingscreenController>();
    expect(controller.currentPage.value, 0);

    // Call nextPage()
    controller.nextPage();
    await tester.pumpAndSettle();
    expect(controller.currentPage.value, 1);

    // Call skip()
    controller.skip();
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);
  });
}
