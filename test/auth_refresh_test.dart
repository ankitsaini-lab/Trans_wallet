import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/minKYCScreen/minkycScreen_Controller.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    HttpOverrides.global = null;
    tempDir = await Directory.systemTemp.createTemp('get_storage_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );
    await GetStorage.init();
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('AuthService saves and retrieves refreshToken and accessToken', () async {
    final authService = Get.put(AuthService());
    await authService.init();

    await authService.saveSession(
      token: 'access_123',
      refreshToken: 'refresh_456',
      userId: 'user_789',
      userData: {'name': 'Test User'},
    );

    expect(authService.token, 'access_123');
    expect(authService.refreshToken, 'refresh_456');
    expect(authService.userId, 'user_789');
    expect(authService.isLoggedIn, true);

    // Update tokens
    await authService.updateTokens(
      accessToken: 'access_new_999',
      refreshToken: 'refresh_new_888',
    );

    expect(authService.token, 'access_new_999');
    expect(authService.refreshToken, 'refresh_new_888');

    // Logout clears tokens
    await authService.logout();
    expect(authService.token, isNull);
    expect(authService.refreshToken, isNull);
    expect(authService.isLoggedIn, false);
  });

  test('ApiService.refreshToken calls /api/v1/auth/refresh and updates tokens', () async {
    int refreshCallCount = 0;
    String? receivedBody;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      if (request.uri.path == '/api/v1/auth/refresh') {
        refreshCallCount++;
        receivedBody = await utf8.decoder.bind(request).join();
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "accessToken": "fresh_access_token_abc",
            "refreshToken": "fresh_refresh_token_xyz",
            "tokenType": "Bearer",
            "expiresIn": 7200
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        }));
        await request.response.close();
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    });

    final authService = Get.put(AuthService());
    await authService.init();
    await authService.saveSession(
      token: 'old_expired_access',
      refreshToken: 'old_refresh_token_123',
      userId: 'user_1',
    );

    final apiService = Get.put(ApiService());
    apiService.updateBaseUrl('http://${server.address.address}:${server.port}');

    final result = await apiService.refreshToken();
    expect(result, isTrue);
    expect(refreshCallCount, 1);
    expect(receivedBody, contains('"refreshToken":"old_refresh_token_123"'));

    // Check storage & AuthService updated
    expect(authService.token, 'fresh_access_token_abc');
    expect(authService.refreshToken, 'fresh_refresh_token_xyz');
    expect(GetStorage().read('accessToken'), 'fresh_access_token_abc');
    expect(GetStorage().read('refreshToken'), 'fresh_refresh_token_xyz');

    await server.close();
  });

  test('ApiService automatically refreshes on 401 and retries original request', () async {
    int protectedCallCount = 0;
    int refreshCallCount = 0;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      if (request.uri.path == '/api/v1/auth/refresh') {
        refreshCallCount++;
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "accessToken": "brand_new_token_999",
            "refreshToken": "brand_new_refresh_888",
            "tokenType": "Bearer",
            "expiresIn": 3600
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        }));
        await request.response.close();
      } else if (request.uri.path == '/api/v1/wallet/balance') {
        protectedCallCount++;
        final authHeader = request.headers.value(HttpHeaders.authorizationHeader);
        if (authHeader == 'Bearer brand_new_token_999') {
          request.response.headers.contentType = ContentType.json;
          request.response.statusCode = HttpStatus.ok;
          request.response.write(jsonEncode({
            "success": true,
            "code": "OK",
            "data": {"balance": 15000}
          }));
          await request.response.close();
        } else {
          // Token expired -> return 401
          request.response.headers.contentType = ContentType.json;
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write(jsonEncode({
            "success": false,
            "code": "UNAUTHORIZED",
            "message": "Access token expired"
          }));
          await request.response.close();
        }
      }
    });

    final authService = Get.put(AuthService());
    await authService.init();
    await authService.saveSession(
      token: 'expired_access_token',
      refreshToken: 'valid_refresh_token',
      userId: 'user_1',
    );

    final apiService = Get.put(ApiService());
    apiService.updateBaseUrl('http://${server.address.address}:${server.port}');

    // Make protected call with expired token
    final response = await apiService.getRequest<Map<String, dynamic>>('/api/v1/wallet/balance');

    expect(response.statusCode, 200);
    expect(response.body?['success'], true);
    expect(response.body?['data']['balance'], 15000);

    // Verified that 401 was received on initial call, refresh was called once, and request was retried
    expect(refreshCallCount, 1);
    expect(protectedCallCount, 2);
    expect(authService.token, 'brand_new_token_999');
    expect(authService.refreshToken, 'brand_new_refresh_888');

    await server.close();
  });

  test('Concurrent refreshToken calls are coalesced into a single network call', () async {
    int refreshCallCount = 0;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      if (request.uri.path == '/api/v1/auth/refresh') {
        refreshCallCount++;
        // Slight delay to simulate network latency and test concurrency
        await Future.delayed(const Duration(milliseconds: 50));
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "accessToken": "coalesced_access_token",
            "refreshToken": "coalesced_refresh_token",
            "tokenType": "Bearer",
            "expiresIn": 3600
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        }));
        await request.response.close();
      }
    });

    final authService = Get.put(AuthService());
    await authService.init();
    await authService.saveSession(
      token: 'old_token',
      refreshToken: 'old_refresh',
      userId: 'user_1',
    );

    final apiService = Get.put(ApiService());
    apiService.updateBaseUrl('http://${server.address.address}:${server.port}');

    // Fire 3 refresh calls simultaneously
    final results = await Future.wait([
      apiService.refreshToken(),
      apiService.refreshToken(),
      apiService.refreshToken(),
    ]);

    expect(results, [true, true, true]);
    // Exactly 1 network call occurred thanks to the Completer mutex!
    expect(refreshCallCount, 1);
    expect(authService.token, 'coalesced_access_token');
    expect(authService.refreshToken, 'coalesced_refresh_token');

    await server.close();
  });

  test('completeRegistration parses empty parameters as blank strings', () async {
    Map<String, dynamic>? capturedBody;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      if (request.uri.path == '/api/v1/auth/register/complete') {
        final bodyStr = await utf8.decoder.bind(request).join();
        capturedBody = jsonDecode(bodyStr) as Map<String, dynamic>;
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "accessToken": "reg_access_token_123",
            "refreshToken": "reg_refresh_token_456",
            "tokenType": "Bearer",
            "expiresIn": 3600
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        }));
        await request.response.close();
      }
    });

    final authService = Get.put(AuthService());
    await authService.init();

    final apiService = Get.put(ApiService());
    apiService.updateBaseUrl('http://${server.address.address}:${server.port}');

    final kycController = Get.put(MinkycscreenController());
    // Explicitly set PAN to a test PAN
    kycController.pan.value = "ABCDE1234F";

    await kycController.completeRegistration();

    expect(capturedBody, isNotNull);
    // Verify empty parameters are parsed as blank string ("") and NOT null or dummy data
    expect(capturedBody!['title'], '');
    expect(capturedBody!['firstName'], '');
    expect(capturedBody!['middleName'], '');
    expect(capturedBody!['lastName'], '');
    expect(capturedBody!['gender'], '');
    expect(capturedBody!['email'], '');
    expect(capturedBody!['dob'], '');
    expect(capturedBody!['kitNumber'], '');
    expect(capturedBody!['addressLine1'], '');
    expect(capturedBody!['addressLine2'], '');
    expect(capturedBody!['pincode'], '');
    expect(capturedBody!['country'], '');
    expect(capturedBody!['state'], '');
    expect(capturedBody!['city'], '');
    expect(capturedBody!['panNumber'], 'ABCDE1234F');
    expect(capturedBody!['hasActivationCode'], isA<bool>());

    // Verify fresh tokens were stored
    expect(GetStorage().read('accessToken'), 'reg_access_token_123');
    expect(GetStorage().read('refreshToken'), 'reg_refresh_token_456');

    await server.close();
  });

  test('verifyPan calls /api/v1/auth/pan/verify and extracts registeredName and verification status', () async {
    Map<String, dynamic>? capturedBody;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      if (request.uri.path == '/api/v1/auth/pan/verify') {
        final bodyStr = await utf8.decoder.bind(request).join();
        capturedBody = jsonDecode(bodyStr) as Map<String, dynamic>;
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "source": "CASHFREE",
            "status": "VERIFIED",
            "registrationToken": {},
            "panLast4": "1234",
            "valid": true,
            "panStatus": "VALID",
            "panStatusDesc": "Existing and Valid",
            "panType": "Individual",
            "registeredName": "JOHN DOE",
            "nameOnPanCard": "JOHN DOE",
            "message": "PAN verified successfully",
            "aadhaarSeedingStatus": "Y",
            "aadhaarSeedingStatusDesc": "Aadhaar is linked to PAN",
            "lastUpdatedAt": "01/01/2019",
            "nameMatchScore": 100,
            "nameMatchResult": "DIRECT_MATCH",
            "referenceId": 161
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        }));
        await request.response.close();
      }
    });

    final authService = Get.put(AuthService());
    await authService.init();

    final apiService = Get.put(ApiService());
    apiService.updateBaseUrl('http://${server.address.address}:${server.port}');

    final box = GetStorage();
    await box.write('registrationToken', 'test_reg_token_abc');

    final kycController = Get.put(MinkycscreenController());
    kycController.pan.value = "ABCDE1234F";

    await kycController.verifyPan();

    expect(capturedBody, isNotNull);
    expect(capturedBody!['registrationToken'], 'test_reg_token_abc');
    expect(capturedBody!['panNumber'], 'ABCDE1234F');

    // Verify PAN was marked as verified and name extracted
    expect(kycController.isPanVerified.value, isTrue);
    expect(box.read('name'), 'JOHN DOE');
    expect(box.read('pan'), 'ABCDE1234F');

    await server.close();
  });

  test('handleButtonAction calls completeRegistration when isPanVerified is true', () async {
    bool completeApiCalled = false;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      if (request.uri.path == '/api/v1/auth/register/complete') {
        completeApiCalled = true;
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "accessToken": "access_xyz",
            "refreshToken": "refresh_xyz",
            "tokenType": "Bearer",
            "expiresIn": 3600
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        }));
        await request.response.close();
      }
    });

    final authService = Get.put(AuthService());
    await authService.init();

    final apiService = Get.put(ApiService());
    apiService.updateBaseUrl('http://${server.address.address}:${server.port}');

    final kycController = Get.put(MinkycscreenController());
    kycController.isPanVerified.value = true;
    kycController.pan.value = "ABCDE1234F";

    // Simulate Continue button click
    kycController.handleButtonAction();

    // Allow async microtasks to complete
    await Future.delayed(const Duration(milliseconds: 100));

    expect(completeApiCalled, isTrue);

    await server.close();
  });

  test('verifyPpiOtp calls /api/v1/auth/register/ppi-otp with registrationToken and otp', () async {
    Map<String, dynamic>? capturedBody;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      if (request.uri.path == '/api/v1/auth/register/ppi-otp') {
        final bodyStr = await utf8.decoder.bind(request).join();
        capturedBody = jsonDecode(bodyStr) as Map<String, dynamic>;
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "flow": "M2P_OTP_SENT",
            "m2pOtpRequired": true,
            "registrationToken": "new_reg_token_999",
            "accessToken": "ppi_access_token_888",
            "refreshToken": "ppi_refresh_token_777",
            "tokenType": "Bearer",
            "expiresIn": 3600,
            "debugOtp": "482617"
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        }));
        await request.response.close();
      }
    });

    final box = GetStorage();
    box.write('registrationToken', 'reg_token_test_123');

    final authService = Get.put(AuthService());
    await authService.init();

    final apiService = Get.put(ApiService());
    apiService.updateBaseUrl('http://${server.address.address}:${server.port}');

    final kycController = Get.put(MinkycscreenController());

    final result = await kycController.verifyPpiOtp('482617');

    expect(result, isTrue);
    expect(capturedBody, isNotNull);
    expect(capturedBody!['registrationToken'], 'reg_token_test_123');
    expect(capturedBody!['otp'], '482617');

    // Verify storage updated with response tokens
    expect(box.read('accessToken'), 'ppi_access_token_888');
    expect(box.read('refreshToken'), 'ppi_refresh_token_777');
    expect(box.read('registrationToken'), 'new_reg_token_999');
    expect(box.read('debugOtp'), '482617');

    await server.close();
  });

  test('completeRegistration handles M2P_OTP_SENT response schema and stores debugOtp and flow', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      if (request.uri.path == '/api/v1/auth/register/complete') {
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "flow": "M2P_OTP_SENT",
            "m2pOtpRequired": true,
            "registrationToken": {},
            "accessToken": {},
            "refreshToken": {},
            "tokenType": "Bearer",
            "expiresIn": {},
            "debugOtp": "987654"
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        }));
        await request.response.close();
      }
    });

    final box = GetStorage();
    box.erase();
    box.write('registrationToken', 'test_reg_token');

    final authService = Get.put(AuthService());
    await authService.init();

    final apiService = Get.put(ApiService());
    apiService.updateBaseUrl('http://${server.address.address}:${server.port}');

    final kycController = Get.put(MinkycscreenController());
    kycController.pan.value = "ABCDE1234F";

    await kycController.completeRegistration();

    expect(box.read('registration_flow'), 'M2P_OTP_SENT');
    expect(box.read('m2pOtpRequired'), true);
    expect(box.read('debugOtp'), '987654');
    expect(kycController.debugOtp.value, '987654');

    await server.close();
  });

  test('completeRegistration uses registrationToken received from pan verify api response', () async {
    Map<String, dynamic>? registerCompleteCapturedBody;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      if (request.uri.path == '/api/v1/auth/pan/verify') {
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "source": "CASHFREE",
            "status": "VERIFIED",
            "registrationToken": "pan_verified_token_abc_xyz",
            "registeredName": "JANE DOE",
            "valid": true
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        }));
        await request.response.close();
      } else if (request.uri.path == '/api/v1/auth/register/complete') {
        final bodyStr = await utf8.decoder.bind(request).join();
        registerCompleteCapturedBody = jsonDecode(bodyStr) as Map<String, dynamic>;
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "flow": "M2P_OTP_SENT",
            "m2pOtpRequired": true,
            "registrationToken": "pan_verified_token_abc_xyz"
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        }));
        await request.response.close();
      }
    });

    final box = GetStorage();
    box.erase();
    box.write('registrationToken', 'initial_create_account_token');

    final authService = Get.put(AuthService());
    await authService.init();

    final apiService = Get.put(ApiService());
    apiService.updateBaseUrl('http://${server.address.address}:${server.port}');

    final kycController = Get.put(MinkycscreenController());
    kycController.pan.value = "ABCDE1234F";

    // 1. Verify PAN
    await kycController.verifyPan();

    // Verify panVerifyRegistrationToken updated
    expect(kycController.panVerifyRegistrationToken.value, 'pan_verified_token_abc_xyz');
    expect(box.read('registrationToken'), 'pan_verified_token_abc_xyz');

    // 2. Call Complete Registration on Continue
    await kycController.completeRegistration();

    // Expect completeRegistration used the token from PAN verify
    expect(registerCompleteCapturedBody, isNotNull);
    expect(
      registerCompleteCapturedBody!['registrationToken'],
      'pan_verified_token_abc_xyz',
    );

    await server.close();
  });

  test('set MPIN calls /api/v1/auth/mpin/set with mpin body and handles status UPDATED', () async {
    Map<String, dynamic>? capturedBody;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      if (request.uri.path == '/api/v1/auth/mpin/set') {
        final bodyStr = await utf8.decoder.bind(request).join();
        capturedBody = jsonDecode(bodyStr) as Map<String, dynamic>;
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "status": "UPDATED"
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        }));
        await request.response.close();
      }
    });

    final box = GetStorage();
    box.write('accessToken', 'mock_access_token_123');

    final apiService = Get.put(ApiService());
    apiService.updateBaseUrl('http://${server.address.address}:${server.port}');

    final response = await apiService.postRequest<Map<String, dynamic>>(
      '/api/v1/auth/mpin/set',
      {"mpin": "1234"},
      headers: {'Authorization': 'Bearer mock_access_token_123'},
    );

    expect(capturedBody, isNotNull);
    expect(capturedBody!['mpin'], '1234');
    expect(response.status.isOk, isTrue);
    expect(response.body!['success'], isTrue);
    expect(response.body!['data']['status'], 'UPDATED');

    await server.close();
  });

  test('Login with MPIN calls /api/v1/auth/mpin/login and stores tokens for subsequent requests', () async {
    Map<String, dynamic>? capturedLoginBody;
    String? capturedAuthHeader;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      if (request.uri.path == '/api/v1/auth/mpin/login') {
        final bodyStr = await utf8.decoder.bind(request).join();
        capturedLoginBody = jsonDecode(bodyStr) as Map<String, dynamic>;
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "accessToken": "mpin_access_token_xyz",
            "refreshToken": "mpin_refresh_token_abc",
            "tokenType": "Bearer",
            "expiresIn": 86400
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        }));
        await request.response.close();
      } else if (request.uri.path == '/api/v1/wallet/balance') {
        capturedAuthHeader = request.headers.value('authorization');
        request.response.headers.contentType = ContentType.json;
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {"balance": 5000}
        }));
        await request.response.close();
      }
    });

    final authService = Get.put(AuthService());
    await authService.init();
    final apiService = Get.put(ApiService());
    apiService.updateBaseUrl('http://${server.address.address}:${server.port}');

    final response = await apiService.postRequest<Map<String, dynamic>>(
      '/api/v1/auth/mpin/login',
      {
        "mobileNumber": "9876543210",
        "mpin": "1234",
      },
    );

    expect(capturedLoginBody, isNotNull);
    expect(capturedLoginBody!['mobileNumber'], '9876543210');
    expect(capturedLoginBody!['mpin'], '1234');
    expect(response.status.isOk, isTrue);
    expect(response.body!['success'], isTrue);
    expect(response.body!['data']['accessToken'], 'mpin_access_token_xyz');
    expect(response.body!['data']['refreshToken'], 'mpin_refresh_token_abc');
    expect(response.body!['data']['tokenType'], 'Bearer');
    expect(response.body!['data']['expiresIn'], 86400);

    // Simulate saving tokens as login controller does
    final data = response.body!['data'];
    await AuthService.to.saveSession(
      token: data['accessToken'],
      refreshToken: data['refreshToken'],
      tokenType: data['tokenType'],
      expiresIn: data['expiresIn'],
      userId: '9876543210',
    );

    // Verify AuthService getters
    expect(AuthService.to.token, 'mpin_access_token_xyz');
    expect(AuthService.to.accessToken, 'mpin_access_token_xyz');
    expect(AuthService.to.refreshToken, 'mpin_refresh_token_abc');
    expect(AuthService.to.tokenType, 'Bearer');
    expect(AuthService.to.expiresIn, 86400);

    // Verify that subsequent inside API calls automatically include the Authorization header
    await apiService.getRequest<Map<String, dynamic>>('/api/v1/wallet/balance');
    expect(capturedAuthHeader, 'Bearer mpin_access_token_xyz');

    await server.close();
  });
}

