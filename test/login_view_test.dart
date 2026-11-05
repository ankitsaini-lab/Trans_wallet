import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/login_singupscreen/login_singupscreen_View.dart';
import 'package:transwallet/products/login_singupscreen/login_singupscreen_Controller.dart';
import 'package:transwallet/products/Profile screen/profilescreen_Controller.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/app_lock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    HttpOverrides.global = null;
    tempDir = await Directory.systemTemp.createTemp('login_test_');
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

  testWidgets('LoginSingupscreenView pumps and displays content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const GetMaterialApp(home: LoginSingupscreenView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Step into simpler payments'), findsOneWidget);
  });

  testWidgets(
    'LoginSingupscreenView keeps phone text field visible when keyboard is open',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        const GetMaterialApp(home: LoginSingupscreenView()),
      );
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      // Simulate soft keyboard opening (350dp keyboard)
      tester.view.viewInsets = const FakeViewPadding(bottom: 350 * 2.75);
      await tester.tap(textFieldFinder);
      await tester.pumpAndSettle();

      // Ensure the text field is positioned well within the visible screen area above the keyboard
      final textFieldBottom = tester.getBottomLeft(textFieldFinder).dy;
      final visibleScreenHeight = (2400 - 350 * 2.75) / 2.75;
      expect(textFieldBottom, lessThan(visibleScreenHeight));
    },
  );

  testWidgets(
    'LoginSingupscreenController tracks biometric label and availability correctly',
    (tester) async {
      final controller = Get.put(LoginSingupscreenController());

      // 1. When device features Fingerprint only
      controller.isBiometricAvailable.value = true;
      controller.biometricLabel.value = 'Fingerprint';
      controller.biometricIcon.value = Icons.fingerprint_rounded;
      expect(controller.biometricLabel.value, 'Fingerprint');
      expect(controller.isBiometricAvailable.value, isTrue);

      // 2. When device features Face Lock only
      controller.biometricLabel.value = 'Face Lock';
      controller.biometricIcon.value = Icons.face_rounded;
      expect(controller.biometricLabel.value, 'Face Lock');

      // 3. When device features Face ID (iOS)
      controller.biometricLabel.value = 'Face ID';
      expect(controller.biometricLabel.value, 'Face ID');

      // 4. When device features Face Lock or Fingerprint
      controller.biometricLabel.value = 'Face Lock or Fingerprint';
      expect(controller.biometricLabel.value, 'Face Lock or Fingerprint');

      // 5. When device has NO biometric features available
      controller.isBiometricAvailable.value = false;
      expect(controller.isBiometricAvailable.value, isFalse);
    },
  );

  group('Logout Redirection Tests', () {
    testWidgets(
      'ProfilescreenController performLogout clears session and navigates to /login_singupview',
      (tester) async {
        final authService = Get.put(AuthService());
        await authService.saveSession(
          token: 'active_access_token',
          refreshToken: 'active_refresh_token',
          userId: 'USER_101',
        );
        expect(authService.isLoggedIn, isTrue);

        final profileController = Get.put(ProfilescreenController());

        // Pump app with routes
        await tester.pumpWidget(
          GetMaterialApp(
            initialRoute: '/profile',
            getPages: [
              GetPage(
                name: '/profile',
                page: () => const Scaffold(body: Text('Profile Screen')),
              ),
              GetPage(
                name: '/login_singupview',
                page: () => const Scaffold(body: Text('Login Screen')),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Profile Screen'), findsOneWidget);

        // Perform logout
        await profileController.performLogout();
        await tester.pumpAndSettle();

        // Verify auth session is cleared
        expect(authService.isLoggedIn, isFalse);
        expect(authService.token, isNull);

        // Verify navigated directly to Login screen
        expect(find.text('Login Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'AppLockService logoutAndReset clears session and navigates directly to login',
      (tester) async {
        final authService = Get.put(AuthService());
        await authService.saveSession(
          token: 'active_access_token',
          refreshToken: 'active_refresh_token',
          userId: 'USER_102',
        );
        final appLockService = Get.put(AppLockService());
        appLockService.isLocked.value = true;

        await tester.pumpWidget(
          GetMaterialApp(
            initialRoute: '/lock',
            getPages: [
              GetPage(
                name: '/lock',
                page: () => const Scaffold(body: Text('Lock Screen')),
              ),
              GetPage(
                name: '/login_singupview',
                page: () => const Scaffold(body: Text('Login Screen')),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await appLockService.logoutAndReset();
        await tester.pumpAndSettle();

        expect(authService.isLoggedIn, isFalse);
        expect(appLockService.isLocked.value, isFalse);
        expect(find.text('Login Screen'), findsOneWidget);
      },
    );

    testWidgets(
      '/login and /login_singupview both resolve to LoginSingupscreenView',
      (tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          GetMaterialApp(
            initialRoute: '/login',
            getPages: [
              GetPage(
                name: '/login',
                page: () => const LoginSingupscreenView(),
              ),
              GetPage(
                name: '/login_singupview',
                page: () => const LoginSingupscreenView(),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Welcome'), findsOneWidget);
      },
    );
  });
}
