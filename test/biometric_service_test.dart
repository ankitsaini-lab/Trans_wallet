import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/biometric_service.dart';

// Fake LocalAuthentication for deterministic unit testing
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
    HttpOverrides.global = null;
    tempDir = await Directory.systemTemp.createTemp('biometric_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );
    await GetStorage.init();
    Get.reset();
    Get.testMode = true;
    Get.put(AuthService());
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('BiometricService detects hardware capabilities correctly', () async {
    final fakeAuth = FakeLocalAuthentication();
    fakeAuth.isSupported = true;
    fakeAuth.canCheck = true;
    fakeAuth.available = [BiometricType.face];

    final service = BiometricService(auth: fakeAuth);
    await service.init();

    expect(service.isHardwareSupported.value, isTrue);
    expect(service.canCheckBiometrics.value, isTrue);
    expect(service.isBiometricAvailable, isTrue);
    expect(service.hasFaceId, isTrue);
    expect(service.hasFingerprint, isFalse);
    expect(service.biometricIcon, Icons.face_rounded);
  });

  test('BiometricService detects fingerprint and generates Touch ID / Fingerprint label', () async {
    final fakeAuth = FakeLocalAuthentication();
    fakeAuth.isSupported = true;
    fakeAuth.canCheck = true;
    fakeAuth.available = [BiometricType.fingerprint];

    final service = BiometricService(auth: fakeAuth);
    await service.init();

    expect(service.hasFingerprint, isTrue);
    expect(service.hasFaceId, isFalse);
    expect(service.biometricIcon, Icons.fingerprint_rounded);
  });

  test('BiometricService authenticate returns success on valid scan', () async {
    final fakeAuth = FakeLocalAuthentication();
    fakeAuth.authenticateResult = true;

    final service = BiometricService(auth: fakeAuth);
    await service.init();

    final result = await service.authenticate(localizedReason: 'Test authentication');
    expect(result.success, isTrue);
    expect(result.errorMessage, isNull);
  });

  test('BiometricService maps NotEnrolled platform exception accurately', () async {
    final fakeAuth = FakeLocalAuthentication();
    fakeAuth.throwException = PlatformException(
      code: 'NotEnrolled',
      message: 'No biometrics enrolled',
    );

    final service = BiometricService(auth: fakeAuth);
    await service.init();

    final result = await service.authenticate(localizedReason: 'Test authentication');
    expect(result.success, isFalse);
    expect(result.errorType, BiometricErrorType.notEnrolled);
    expect(result.errorMessage, contains('No biometric credentials enrolled'));
  });

  test('BiometricService maps PasscodeNotSet platform exception accurately', () async {
    final fakeAuth = FakeLocalAuthentication();
    fakeAuth.throwException = PlatformException(
      code: 'PasscodeNotSet',
      message: 'Passcode not set',
    );

    final service = BiometricService(auth: fakeAuth);
    await service.init();

    final result = await service.authenticate(localizedReason: 'Test authentication');
    expect(result.success, isFalse);
    expect(result.errorType, BiometricErrorType.passcodeNotSet);
    expect(result.errorMessage, contains('Device passcode or screen lock is not set'));
  });

  test('BiometricService maps UserCanceled platform exception without loud error', () async {
    final fakeAuth = FakeLocalAuthentication();
    fakeAuth.throwException = PlatformException(
      code: 'UserCancel',
      message: 'User pressed cancel',
    );

    final service = BiometricService(auth: fakeAuth);
    await service.init();

    final result = await service.authenticate(localizedReason: 'Test authentication');
    expect(result.success, isFalse);
    expect(result.isCanceled, isTrue);
    expect(result.errorType, BiometricErrorType.canceled);
  });

  test('BiometricService toggle setting persists in GetStorage', () async {
    final fakeAuth = FakeLocalAuthentication();
    fakeAuth.authenticateResult = true;

    final service = BiometricService(auth: fakeAuth);
    await service.init();

    expect(service.isBiometricEnabled.value, isTrue);

    // Disable
    await service.setBiometricEnabled(false);
    expect(service.isBiometricEnabled.value, isFalse);
    expect(GetStorage().read('biometric_enabled'), isFalse);
    expect(service.canLoginWithBiometrics, isFalse);

    // Re-enable (prompts verification)
    final success = await service.setBiometricEnabled(true, verifyBeforeEnable: true);
    expect(success, isTrue);
    expect(service.isBiometricEnabled.value, isTrue);
    expect(GetStorage().read('biometric_enabled'), isTrue);
  });

  test('BiometricService authenticateAndLogin performs authentication and MPIN login fallback', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      final bodyStr = await utf8.decoder.bind(request).join();
      final body = jsonDecode(bodyStr) as Map<String, dynamic>;

      request.response.headers.contentType = ContentType.json;
      request.response.statusCode = HttpStatus.ok;

      if (request.uri.path == '/api/v1/auth/mpin/login') {
        expect(body['mobileNumber'], '9123456789');
        expect(body['mpin'], '1234');
        request.response.write(jsonEncode({
          "success": true,
          "code": "OK",
          "message": "Login Successful",
          "data": {
            "accessToken": "mpin_jwt_token_valid",
            "refreshToken": "mpin_refresh_token_valid",
            "tokenType": "Bearer",
            "expiresIn": 3600
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        }));
      }
      await request.response.close();
    });

    final apiService = Get.put(ApiService());
    apiService.updateBaseUrl('http://${server.address.address}:${server.port}');

    GetStorage().write('saved_mpin', '1234');

    final fakeAuth = FakeLocalAuthentication();
    fakeAuth.authenticateResult = true;

    final service = BiometricService(auth: fakeAuth);
    await service.init();

    final success = await service.authenticateAndLogin(
      mobileNumber: '9123456789',
    );

    expect(success, isTrue);
    expect(AuthService.to.token, 'mpin_jwt_token_valid');
    expect(GetStorage().read('is_logged_in'), isTrue);

    await server.close();
  });

  testWidgets('BiometricService promptBiometricPermission displays permission dialog when biometrics is available', (tester) async {
    final fakeAuth = FakeLocalAuthentication();
    fakeAuth.isSupported = true;
    fakeAuth.canCheck = true;
    fakeAuth.available = [BiometricType.fingerprint];

    final service = Get.put(BiometricService(auth: fakeAuth));
    await service.init();

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  service.promptBiometricPermission(context);
                },
                child: const Text('Ask Permission'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ask Permission'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Enable'), findsWidgets);
    expect(find.text('Skip for Now'), findsOneWidget);
  });
}


