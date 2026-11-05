import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Send%20money%20screen/sendMoney_Controller.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendMoney_Password_Controller.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendmoneyProcess_Controller.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendMoney_Success_Controller.dart';
import 'package:transwallet/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  HttpServer? mockServer;

  setUp(() async {
    HttpOverrides.global = null;
    tempDir = await Directory.systemTemp.createTemp('c2c_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );

    // Mock flutter_contacts permission so SendmoneyController doesn't hang
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('github.com/Quis/flutter_contacts'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'requestPermission') return true;
        if (methodCall.method == 'select') return [];
        return null;
      },
    );

    try {
      await GetStorage.init();
      await GetStorage().erase();
    } catch (_) {}
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() async {
    await mockServer?.close(force: true);
    Get.reset();
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('checkC2CRecipient calls /api/v1/wallet/transfer/c2c/check and parses response', () async {
    mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    mockServer!.listen((HttpRequest req) async {
      final bodyStr = await utf8.decoder.bind(req).join();
      final body = jsonDecode(bodyStr) as Map<String, dynamic>;

      expect(req.uri.path, '/api/v1/wallet/transfer/c2c/check');
      expect(body['toMobileNumber'], '9876543210');

      req.response.headers.contentType = ContentType.json;
      req.response.statusCode = HttpStatus.ok;
      req.response.write(jsonEncode({
        "success": true,
        "code": "OK",
        "message": "Success",
        "data": {
          "toMobileNumber": "9876543210",
          "exists": true,
          "hasEntityId": true,
          "kycLevel": "FULL",
          "kycStatus": "COMPLETED",
          "isFullKyc": true,
          "canReceiveW2W": true,
          "reasonCode": "FULL_KYC_REQUIRED",
          "message": "Recipient must complete full KYC before wallet transfer",
          "firstName": "Jane"
        },
        "timestamp": "2026-09-03T07:00:00.000Z"
      }));
      await req.response.close();
    });

    final api = Get.put(ApiService());
    api.updateBaseUrl('http://${mockServer!.address.address}:${mockServer!.port}');

    final res = await api.checkC2CRecipient(toMobileNumber: '9876543210');

    expect(res, isNotNull);
    expect(res!['exists'], isTrue);
    expect(res['canReceiveW2W'], isTrue);
    expect(res['firstName'], 'Jane');
    expect(res['isFullKyc'], isTrue);
    expect(res['kycStatus'], 'COMPLETED');
  });

  test('SendmoneyController verifyAndProceed handles valid recipient and extracts firstName', () async {
    mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    mockServer!.listen((HttpRequest req) async {
      req.response.headers.contentType = ContentType.json;
      req.response.statusCode = HttpStatus.ok;
      req.response.write(jsonEncode({
        "success": true,
        "code": "OK",
        "message": "Success",
        "data": {
          "toMobileNumber": "9876543210",
          "exists": true,
          "hasEntityId": true,
          "kycLevel": "FULL",
          "kycStatus": "COMPLETED",
          "isFullKyc": true,
          "canReceiveW2W": true,
          "firstName": "Jane"
        },
        "timestamp": "2026-09-03T07:00:00.000Z"
      }));
      await req.response.close();
    });

    final api = Get.put(ApiService());
    api.updateBaseUrl('http://${mockServer!.address.address}:${mockServer!.port}');

    final controller = Get.put(SendmoneyController());

    await controller.verifyAndProceed({
      "name": "User (9876543210)",
      "phone": "+91 9876543210",
    });

    final savedRecipients = GetStorage().read('recent_w2w_recipients') as List?;
    expect(savedRecipients, isNotNull);
    expect(savedRecipients!.first['name'], 'Jane');
    expect(savedRecipients.first['phone'], '+91 9876543210');
  });

  test('SendmoneyController verifyAndProceed blocks non-existent recipient', () async {
    mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    mockServer!.listen((HttpRequest req) async {
      req.response.headers.contentType = ContentType.json;
      req.response.statusCode = HttpStatus.ok;
      req.response.write(jsonEncode({
        "success": true,
        "code": "OK",
        "message": "Success",
        "data": {
          "toMobileNumber": "9111111111",
          "exists": false,
          "message": "User not registered"
        },
        "timestamp": "2026-09-03T07:00:00.000Z"
      }));
      await req.response.close();
    });

    final api = Get.put(ApiService());
    api.updateBaseUrl('http://${mockServer!.address.address}:${mockServer!.port}');

    final controller = Get.put(SendmoneyController());

    await controller.verifyAndProceed({
      "name": "Unknown",
      "phone": "+91 9111111111",
    });

    final savedRecipients = GetStorage().read('recent_w2w_recipients') as List?;
    expect(savedRecipients, isNull);
  });

  test('SendmoneyController verifyAndProceed blocks transfer when canReceiveW2W is false', () async {
    mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    mockServer!.listen((HttpRequest req) async {
      req.response.headers.contentType = ContentType.json;
      req.response.statusCode = HttpStatus.ok;
      req.response.write(jsonEncode({
        "success": true,
        "code": "OK",
        "message": "Success",
        "data": {
          "toMobileNumber": "9876543210",
          "exists": true,
          "hasEntityId": true,
          "kycLevel": "MIN",
          "kycStatus": "PENDING",
          "isFullKyc": false,
          "canReceiveW2W": false,
          "reasonCode": "FULL_KYC_REQUIRED",
          "message": "Recipient must complete full KYC before wallet transfer",
          "firstName": "Bob"
        },
        "timestamp": "2026-09-03T07:00:00.000Z"
      }));
      await req.response.close();
    });

    final api = Get.put(ApiService());
    api.updateBaseUrl('http://${mockServer!.address.address}:${mockServer!.port}');

    final controller = Get.put(SendmoneyController());

    await controller.verifyAndProceed({
      "name": "Bob",
      "phone": "+91 9876543210",
    });

    final savedRecipients = GetStorage().read('recent_w2w_recipients') as List?;
    expect(savedRecipients, isNull);
  });

  test('SendmoneyController blocks self-transfer without calling API', () async {
    GetStorage().write('mobileNumber', '9876543210');

    bool apiCalled = false;
    mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    mockServer!.listen((HttpRequest req) {
      apiCalled = true;
      req.response.statusCode = HttpStatus.ok;
      req.response.close();
    });

    final api = Get.put(ApiService());
    api.updateBaseUrl('http://${mockServer!.address.address}:${mockServer!.port}');

    final controller = Get.put(SendmoneyController());

    await controller.verifyAndProceed({
      "name": "Me",
      "phone": "+91 9876543210",
    });

    expect(apiCalled, isFalse);
  });

  test('transferC2C calls /api/v1/wallet/transfer/c2c with exact request schema and parses response', () async {
    mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    mockServer!.listen((HttpRequest req) async {
      final bodyStr = await utf8.decoder.bind(req).join();
      final body = jsonDecode(bodyStr) as Map<String, dynamic>;

      expect(req.uri.path, '/api/v1/wallet/transfer/c2c');
      expect(body['toMobileNumber'], '9876543210');
      expect(body['amount'], 100);
      expect(body['idempotencyKey'], 'C2C1789623452164');
      expect(body['description'], 'Customer to customer transfer');

      req.response.headers.contentType = ContentType.json;
      req.response.statusCode = HttpStatus.ok;
      req.response.write(jsonEncode({
        "success": true,
        "code": "OK",
        "message": "Success",
        "data": {
          "providerRef": "835133872",
          "status": "PAYMENT_SUCCESS",
          "balance": 90,
          "externalTransactionId": "C2C1789623452164",
          "transactionType": "C2C",
          "fromEntityId": "SENDER01",
          "toEntityId": "RECIPIENT01",
          "toMobileNumber": "9876543210",
          "amount": 100,
          "fromProductId": "GENERAL",
          "productId": "GENERAL"
        },
        "timestamp": "2026-09-03T07:00:00.000Z"
      }));
      await req.response.close();
    });

    final api = Get.put(ApiService());
    api.updateBaseUrl('http://${mockServer!.address.address}:${mockServer!.port}');

    final res = await api.transferC2C(
      toMobileNumber: '9876543210',
      amount: 100,
      idempotencyKey: 'C2C1789623452164',
      description: 'Customer to customer transfer',
    );

    expect(res, isNotNull);
    expect(res!['status'], 'PAYMENT_SUCCESS');
    expect(res['providerRef'], '835133872');
    expect(res['balance'], 90);
    expect(res['externalTransactionId'], 'C2C1789623452164');
    expect(res['transactionType'], 'C2C');
    expect(res['apiSuccess'], isTrue);
  });

  test('SendMoneyPasswordController calls /api/v1/auth/mpin/login and executes transferC2C on success', () async {
    bool transferCalled = false;
    bool mpinLoginCalled = false;

    mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    mockServer!.listen((HttpRequest req) async {
      if (req.uri.path == '/api/v1/auth/mpin/login') {
        mpinLoginCalled = true;
        final bodyStr = await utf8.decoder.bind(req).join();
        final body = jsonDecode(bodyStr) as Map<String, dynamic>;
        expect(body['mobileNumber'], '9876543210');
        expect(body['mpin'], '1234');

        req.response.headers.contentType = ContentType.json;
        req.response.statusCode = HttpStatus.ok;
        req.response.write(jsonEncode({
          "success": true,
          "code": "OK",
          "message": "Login successful",
          "data": {"token": "auth_token_xyz"}
        }));
      } else if (req.uri.path == '/api/v1/wallet/transfer/c2c') {
        transferCalled = true;
        final bodyStr = await utf8.decoder.bind(req).join();
        final body = jsonDecode(bodyStr) as Map<String, dynamic>;

        expect(body['toMobileNumber'], '9876543210');
        expect(body['amount'], 100.0);

        req.response.headers.contentType = ContentType.json;
        req.response.statusCode = HttpStatus.ok;
        req.response.write(jsonEncode({
          "success": true,
          "code": "OK",
          "message": "Success",
          "data": {
            "providerRef": "REF11111",
            "status": "PAYMENT_SUCCESS",
            "balance": 900.0,
            "externalTransactionId": "C2C_EXT_111",
            "transactionType": "C2C",
            "toMobileNumber": "9876543210",
            "amount": 100.0,
          },
          "timestamp": "2026-09-03T07:00:00.000Z"
        }));
      } else {
        req.response.statusCode = HttpStatus.notFound;
      }
      await req.response.close();
    });

    final api = Get.put(ApiService());
    api.updateBaseUrl('http://${mockServer!.address.address}:${mockServer!.port}');

    GetStorage().write('mobileNumber', '9876543210');
    GetStorage().write('balance', 1000.0);

    final controller = Get.put(SendMoneyPasswordController());
    controller.amount = 100.0;
    controller.recipient = {
      'name': 'Test Recipient',
      'phone': '9876543210',
    };

    // Enter 4-digit PIN: 1234
    controller.addDigit('1');
    controller.addDigit('2');
    controller.addDigit('3');
    controller.addDigit('4');

    // Wait for async MPIN verification and transfer
    await Future.delayed(const Duration(milliseconds: 200));

    expect(mpinLoginCalled, isTrue);
    expect(transferCalled, isTrue);
    expect(GetStorage().read('balance'), 900.0);
    expect(GetStorage().read('saved_mpin'), '1234');
  });

  test('SendMoneyPasswordController rejects incorrect MPIN via API without calling transfer API', () async {
    bool transferCalled = false;
    bool mpinLoginCalled = false;

    mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    mockServer!.listen((HttpRequest req) async {
      if (req.uri.path == '/api/v1/auth/mpin/login') {
        mpinLoginCalled = true;
        final bodyStr = await utf8.decoder.bind(req).join();
        final body = jsonDecode(bodyStr) as Map<String, dynamic>;
        expect(body['mpin'], '9999');

        req.response.headers.contentType = ContentType.json;
        req.response.statusCode = HttpStatus.unauthorized;
        req.response.write(jsonEncode({
          "success": false,
          "code": "INVALID_CREDENTIALS",
          "message": "Invalid MPIN"
        }));
      } else if (req.uri.path == '/api/v1/wallet/transfer/c2c') {
        transferCalled = true;
        req.response.statusCode = HttpStatus.ok;
      }
      await req.response.close();
    });

    final api = Get.put(ApiService());
    api.updateBaseUrl('http://${mockServer!.address.address}:${mockServer!.port}');

    GetStorage().write('mobileNumber', '9876543210');

    final controller = Get.put(SendMoneyPasswordController());
    controller.amount = 100.0;
    controller.recipient = {
      'name': 'Test Recipient',
      'phone': '9876543210',
    };

    // Enter wrong PIN: 9999
    controller.addDigit('9');
    controller.addDigit('9');
    controller.addDigit('9');
    controller.addDigit('9');

    await Future.delayed(const Duration(milliseconds: 150));

    expect(mpinLoginCalled, isTrue);
    expect(controller.isError.value, isTrue);
    expect(controller.errorMessage.value, "Invalid MPIN");
    expect(controller.passcode.value, '');
    expect(transferCalled, isFalse);
  });

  test('SendMoneySuccessController initializes details and copies reference ID', () {
    final controller = Get.put(SendMoneySuccessController());
    controller.amount = 250.0;
    controller.recipient = {'name': 'Jane', 'phone': '9876543210'};
    controller.providerRef = 'REF12345';
    controller.balance = 750.0;

    expect(controller.referenceId, 'REF12345');
    expect(controller.amount, 250.0);
    expect(controller.balance, 750.0);
  });

  test('SendmoneyprocessController enforces limit: Min 1 and Max 10,000', () {
    final controller = Get.put(SendmoneyprocessController());

    // Initially amount is 0 and canProceed is false
    expect(controller.amount, 0.0);
    expect(controller.canProceed, isFalse);

    // Enter 1 -> valid
    controller.setAmount('1');
    expect(controller.amount, 1.0);
    expect(controller.canProceed, isTrue);

    // Enter 0 -> 10, valid
    controller.setAmount('0');
    expect(controller.amount, 10.0);
    expect(controller.canProceed, isTrue);

    // Clear and set to 10000
    controller.setPreset(5000);
    expect(controller.amount, 5000.0);
    expect(controller.canProceed, isTrue);

    // Set to 10000 manually
    controller.enteredAmount.value = '';
    controller.setAmount('1');
    controller.setAmount('0');
    controller.setAmount('0');
    controller.setAmount('0');
    controller.setAmount('0');
    expect(controller.amount, 10000.0);
    expect(controller.canProceed, isTrue);

    // Attempt to type another 0 to make it 100,000 -> rejected
    controller.setAmount('0');
    expect(controller.amount, 10000.0);
    expect(controller.canProceed, isTrue);

    // Clear using back
    controller.setAmount('back');
    expect(controller.amount, 1000.0);
  });

  test('SendMoneyPasswordController blocks transfers with amount < 1 or > 10000', () async {
    bool transferCalled = false;
    mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    mockServer!.listen((HttpRequest req) {
      if (req.uri.path == '/api/v1/wallet/transfer/c2c') {
        transferCalled = true;
      }
      req.response.statusCode = HttpStatus.ok;
      req.response.close();
    });

    final api = Get.put(ApiService());
    api.updateBaseUrl('http://${mockServer!.address.address}:${mockServer!.port}');

    GetStorage().write('saved_mpin', '1234');

    // Case 1: Amount < 1 (e.g. 0.5)
    final controllerUnderMin = Get.put(SendMoneyPasswordController(), tag: 'under_min');
    controllerUnderMin.amount = 0.5;
    controllerUnderMin.recipient = {'name': 'Test', 'phone': '9876543210'};

    controllerUnderMin.addDigit('1');
    controllerUnderMin.addDigit('2');
    controllerUnderMin.addDigit('3');
    controllerUnderMin.addDigit('4');

    await Future.delayed(const Duration(milliseconds: 50));
    expect(controllerUnderMin.isError.value, isTrue);
    expect(transferCalled, isFalse);

    // Case 2: Amount > 10000 (e.g. 15000)
    final controllerOverMax = Get.put(SendMoneyPasswordController(), tag: 'over_max');
    controllerOverMax.amount = 15000.0;
    controllerOverMax.recipient = {'name': 'Test', 'phone': '9876543210'};

    controllerOverMax.addDigit('1');
    controllerOverMax.addDigit('2');
    controllerOverMax.addDigit('3');
    controllerOverMax.addDigit('4');

    await Future.delayed(const Duration(milliseconds: 50));
    expect(controllerOverMax.isError.value, isTrue);
    expect(transferCalled, isFalse);
  });
}
