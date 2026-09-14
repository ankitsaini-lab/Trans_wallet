import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:transwallet/widgets/app_lock_overlay.dart';
import 'package:transwallet/services/auth_service.dart';

// Fake LocalAuthentication for unit/widget testing
class FakeLocalAuthentication extends Fake implements LocalAuthentication {
  bool isSupported = true;
  bool canCheck = true;
  List<BiometricType> available = [BiometricType.fingerprint];
  bool authenticateResult = true;
  PlatformException? throwException;

  @override
  Future<bool> isDeviceSupported() async => isSupported;

  @override
  Future<bool> get canCheckBiometrics async => canCheck;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => available;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #authenticate) {
      if (throwException != null) throw throwException!;
      return Future.value(authenticateResult);
    }
    return super.noSuchMethod(invocation);
  }

  @override
  Future<bool> stopAuthentication() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_lock_test_');
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
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.unlock();
    }
    await GetStorage().erase();
    Get.reset();
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('AppLockService Background & Timeout Tests', () {
    test('App does NOT lock if backgrounded for less than 2 seconds', () async {
      final storage = GetStorage();
      storage.write('is_logged_in', true);
      storage.write('accessToken', 'mock_token_123');
      storage.write('saved_mpin', '1234');

      Get.put(AuthService());
      final lockService = Get.put(AppLockService());
      await lockService.init();

      expect(lockService.isLocked.value, isFalse);

      // 1. Simulate backgrounding app
      lockService.didChangeAppLifecycleState(AppLifecycleState.paused);

      // 2. Wait only 1 second (< 2 seconds threshold)
      await Future.delayed(const Duration(milliseconds: 1000));

      // 3. Simulate returning to foreground
      lockService.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // 4. Assert: Still unlocked!
      expect(lockService.isLocked.value, isFalse);
    });

    test('App DOES lock automatically when backgrounded for >= 2 seconds', () async {
      final storage = GetStorage();
      storage.write('is_logged_in', true);
      storage.write('accessToken', 'mock_token_123');
      storage.write('saved_mpin', '1234');

      Get.put(AuthService());
      final lockService = Get.put(AppLockService());
      await lockService.init();

      expect(lockService.isLocked.value, isFalse);

      // 1. Simulate backgrounding app
      lockService.didChangeAppLifecycleState(AppLifecycleState.paused);

      // 2. Wait 2.1 seconds (exceeding 2s threshold)
      await Future.delayed(const Duration(milliseconds: 2100));

      // 3. Assert: App is now locked!
      expect(lockService.isLocked.value, isTrue);

      // 4. Resume app while locked
      lockService.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(lockService.isLocked.value, isTrue);
    });

    test('App does NOT lock when app_lock_enabled is explicitly disabled in settings', () async {
      final storage = GetStorage();
      storage.write('app_lock_enabled', false);

      Get.put(AuthService());
      final lockService = Get.put(AppLockService());
      await lockService.init();

      lockService.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future.delayed(const Duration(milliseconds: 2100));
      lockService.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(lockService.isLocked.value, isFalse);
    });

    test('App does not lock when user is NOT logged in', () async {
      final storage = GetStorage();
      storage.write('is_logged_in', false);

      Get.put(AuthService());
      final lockService = Get.put(AppLockService());
      await lockService.init();

      lockService.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future.delayed(const Duration(milliseconds: 2100));
      lockService.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(lockService.isLocked.value, isFalse);
    });

    test('App does NOT lock when setPickingMedia(true) is active (e.g. photo/camera selection)', () async {
      final storage = GetStorage();
      storage.write('is_logged_in', true);
      storage.write('accessToken', 'mock_token_123');

      Get.put(AuthService());
      final lockService = Get.put(AppLockService());
      await lockService.init();

      lockService.setPickingMedia(true);

      lockService.didChangeAppLifecycleState(AppLifecycleState.inactive);
      lockService.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future.delayed(const Duration(milliseconds: 2100));
      lockService.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(lockService.isLocked.value, isFalse);

      lockService.setPickingMedia(false);
    });

    test(
        'App locks accurately with realistic OS sequence: inactive -> paused -> wait 2.1s -> inactive -> resumed',
        () async {
      final storage = GetStorage();
      storage.write('is_logged_in', true);
      storage.write('accessToken', 'mock_token_123');

      Get.put(AuthService());
      final lockService = Get.put(AppLockService());
      await lockService.init();

      expect(lockService.isLocked.value, isFalse);

      // Real OS: user swipes away app
      lockService.didChangeAppLifecycleState(AppLifecycleState.inactive);
      lockService.didChangeAppLifecycleState(AppLifecycleState.paused);

      // In background for 2.1s
      await Future.delayed(const Duration(milliseconds: 2100));

      // Real OS: app comes to foreground, sending inactive before resumed
      lockService.didChangeAppLifecycleState(AppLifecycleState.inactive);
      lockService.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // Assert: Must be locked!
      expect(lockService.isLocked.value, isTrue);
      expect(lockService.lastElapsedMs.value, greaterThanOrEqualTo(2000));
    });

    test('App locks via elapsed time evaluation on resumed even if timer did not fire in background',
        () async {
      final storage = GetStorage();
      storage.write('is_logged_in', true);
      storage.write('accessToken', 'mock_token_123');

      Get.put(AuthService());
      final lockService = Get.put(AppLockService());
      await lockService.init();

      // App backgrounded
      lockService.didChangeAppLifecycleState(AppLifecycleState.paused);

      // Wait 2.1s
      await Future.delayed(const Duration(milliseconds: 2100));

      // Force unlocked to simulate background timer having been killed or suspended
      lockService.isLocked.value = false;

      // On resume, the elapsed duration must still detect >= 2s and lock!
      lockService.didChangeAppLifecycleState(AppLifecycleState.inactive);
      lockService.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(lockService.isLocked.value, isTrue);
    });

    test('App locks in developer test mode even when not logged in', () async {
      final storage = GetStorage();
      storage.write('app_lock_test_mode', true);
      storage.write('is_logged_in', false);

      Get.put(AuthService());
      final lockService = Get.put(AppLockService());
      await lockService.init();

      lockService.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future.delayed(const Duration(milliseconds: 2100));
      lockService.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(lockService.isLocked.value, isTrue);
    });
  });

  group('AppLockService MPIN Verification Tests', () {
    test('verifyMpin unlocks with correct saved MPIN', () async {
      final storage = GetStorage();
      storage.write('is_logged_in', true);
      storage.write('accessToken', 'mock_token');
      storage.write('saved_mpin', '5678');

      Get.put(AuthService());
      final lockService = Get.put(AppLockService());
      await lockService.init();

      lockService.lockApp();
      expect(lockService.isLocked.value, isTrue);

      // Wrong PIN
      final wrongResult = await lockService.verifyMpin('1111');
      expect(wrongResult, isFalse);
      expect(lockService.isLocked.value, isTrue);
      expect(lockService.pinError.value.isNotEmpty, isTrue);

      // Correct PIN
      final rightResult = await lockService.verifyMpin('5678');
      expect(rightResult, isTrue);
      expect(lockService.isLocked.value, isFalse);
      expect(lockService.pinError.value.isEmpty, isTrue);
    });

    test('onKeyTap appends digits and auto-verifies at 4 digits', () async {
      final storage = GetStorage();
      storage.write('is_logged_in', true);
      storage.write('accessToken', 'mock_token');
      storage.write('saved_mpin', '4321');

      Get.put(AuthService());
      final lockService = Get.put(AppLockService());
      await lockService.init();

      lockService.lockApp();

      lockService.onKeyTap('4');
      lockService.onKeyTap('3');
      expect(lockService.enteredPin.value, '43');

      lockService.onDeleteKey();
      expect(lockService.enteredPin.value, '4');

      lockService.onKeyTap('3');
      lockService.onKeyTap('2');
      lockService.onKeyTap('1'); // 4th digit triggers auto-verify

      expect(lockService.isLocked.value, isFalse);
    });
  });

  group('AppLockOverlay Widget Tests', () {
    testWidgets('Renders child normally when unlocked, shows overlay when locked',
        (tester) async {
      final storage = GetStorage();
      storage.write('is_logged_in', true);
      storage.write('accessToken', 'mock_token');
      storage.write('saved_mpin', '1234');

      Get.put(AuthService());
      final lockService = Get.put(AppLockService());
      await lockService.init();

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: AppLockOverlay(
              child: Center(child: Text('Dashboard Content Protected')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Unlocked state: child is visible, "App Locked" is NOT visible
      expect(find.text('Dashboard Content Protected'), findsOneWidget);
      expect(find.text('App Locked'), findsNothing);

      // Lock app
      lockService.lockApp();
      await tester.pumpAndSettle();

      // Locked state: Overlay displays "App Locked", keypad digits 1..9, 0
      expect(find.text('App Locked'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Forgot MPIN?  Log Out'), findsOneWidget);

      // Enter correct MPIN via keypad taps
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();

      // App is now unlocked!
      expect(lockService.isLocked.value, isFalse);
      expect(find.text('App Locked'), findsNothing);
      expect(find.text('Dashboard Content Protected'), findsOneWidget);
    });

    testWidgets(
        'Shows Biometric-Only initially, and switches to MPIN-Only only after > 3 failures',
        (tester) async {
      final storage = GetStorage();
      storage.write('is_logged_in', true);
      storage.write('accessToken', 'mock_token');
      storage.write('saved_mpin', '1234');
      storage.write('biometric_enabled', true);

      Get.put(AuthService());

      // Register BiometricService with fake auth
      final fakeAuth = FakeLocalAuthentication();
      final bioService = Get.put(BiometricService(auth: fakeAuth));
      await bioService.init();

      final lockService = Get.put(AppLockService());
      await lockService.init();

      // Initially unlocked
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: AppLockOverlay(
              child: Center(child: Text('Dashboard Content Protected')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Lock the app
      lockService.lockApp();
      await tester.pumpAndSettle();

      // Initially (failures = 0): Biometric-only mode!
      expect(lockService.shouldShowMpinOnly, isFalse);
      expect(find.text('App Locked'), findsOneWidget);
      expect(
        find.textContaining('Scan face or touch sensor to unlock'),
        findsOneWidget,
      );
      // MPIN Keypad is NOT shown yet!
      expect(find.text('1'), findsNothing);
      expect(find.text('0'), findsNothing);

      // 2. Fail biometric attempt 1
      lockService.recordBiometricFailure();
      await tester.pumpAndSettle();
      expect(lockService.shouldShowMpinOnly, isFalse);
      expect(
        find.textContaining('Scan face or touch sensor to unlock'),
        findsOneWidget,
      );
      expect(find.text('1'), findsNothing); // Keypad still hidden
      expect(find.textContaining('1 of 3 used'), findsOneWidget);

      // 3. Fail biometric attempt 2
      lockService.recordBiometricFailure();
      await tester.pumpAndSettle();
      expect(lockService.shouldShowMpinOnly, isFalse);
      expect(find.text('1'), findsNothing); // Keypad still hidden
      expect(find.textContaining('2 of 3 used'), findsOneWidget);

      // 4. Fail biometric attempt 3
      lockService.recordBiometricFailure();
      await tester.pumpAndSettle();
      expect(lockService.shouldShowMpinOnly, isFalse);
      expect(find.text('1'), findsNothing); // Keypad still hidden!
      expect(find.textContaining('3 incorrect attempts'), findsOneWidget);

      // 5. Fail biometric attempt 4 (> 3 times!)
      lockService.recordBiometricFailure();
      await tester.pumpAndSettle();

      // Now failures = 4 (> 3): MPIN-ONLY MODE!
      expect(lockService.shouldShowMpinOnly, isTrue);
      // Biometric scan prompt is GONE
      expect(
        find.textContaining('Scan face or touch sensor to unlock'),
        findsNothing,
      );
      // Subtitle informs user biometric is locked after > 3 failures
      expect(find.textContaining('Biometric incorrect more than 3 times'),
          findsOneWidget);
      // Numeric Keypad is NOW visible!
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      // 6. Enter correct MPIN to unlock
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();

      // App unlocked, failure count reset to 0!
      expect(lockService.isLocked.value, isFalse);
      expect(lockService.biometricFailedAttempts.value, 0);
      expect(find.text('Dashboard Content Protected'), findsOneWidget);
    });

    testWidgets('Allows manual switching between Biometric screen and MPIN keypad',
        (tester) async {
      final storage = GetStorage();
      storage.write('is_logged_in', true);
      storage.write('accessToken', 'mock_token');
      storage.write('saved_mpin', '1234');
      storage.write('biometric_enabled', true);

      Get.put(AuthService());
      final fakeAuth = FakeLocalAuthentication();
      final bioService = Get.put(BiometricService(auth: fakeAuth));
      await bioService.init();

      final lockService = Get.put(AppLockService());
      await lockService.init();

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: AppLockOverlay(
              child: Center(child: Text('Dashboard Content Protected')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Lock the app
      lockService.lockApp();
      await tester.pumpAndSettle();

      // In biometric mode: "Use 4-digit MPIN instead" is visible
      expect(find.text('Use 4-digit MPIN instead'), findsOneWidget);
      expect(find.text('1'), findsNothing);

      // 2. Tap "Use 4-digit MPIN instead"
      await tester.tap(find.text('Use 4-digit MPIN instead'));
      await tester.pumpAndSettle();

      // Keypad is now visible!
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.textContaining('Use'), findsWidgets); // "Use Face Lock or Fingerprint instead"

      // 3. Tap "Use ... instead" to switch back to biometric mode and authenticate
      await tester.tap(find.textContaining('instead'));
      await tester.pumpAndSettle();

      // Successful biometric verification unlocks the app!
      expect(lockService.isLocked.value, isFalse);
      expect(find.text('Dashboard Content Protected'), findsOneWidget);
    });
  });
}
