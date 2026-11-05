import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/History%20screen/historyscreen_Controller.dart';
import 'package:transwallet/products/History%20screen/historyscreen_View.dart';
import 'package:transwallet/services/api_service.dart';

class MockHistoryApiService extends ApiService {
  final List<Map<String, dynamic>> recordedCalls = [];

  @override
  Future<Response<T>> getRequest<T>(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    recordedCalls.add({
      'path': path,
      'query': query != null ? Map<String, dynamic>.from(query) : null,
    });

    if (path == '/api/v1/transactions') {
      final pageNumber = int.tryParse(query?['pageNumber']?.toString() ?? '0') ?? 0;
      final pageSize = int.tryParse(query?['pageSize']?.toString() ?? '20') ?? 20;

      expect(pageSize, 20);

      if (pageNumber == 0) {
        // Return 20 items for page 0
        final items = List.generate(20, (i) {
          return {
            'type': i % 2 == 0 ? 'CREDIT' : 'DEBIT',
            'amount': (i + 1) * 50,
            'transactionStatus': 'SUCCESS',
            'time': '2026-11-03T10:00:00.000Z',
            'otherPartyName': 'Merchant $i',
            'txRef': 'TXN_REF_$i',
            'description': 'Transaction $i',
          };
        });

        return Response<T>(
          statusCode: 200,
          body: {
            "success": true,
            "code": "OK",
            "message": "Success",
            "data": {
              "items": items,
              "pageNumber": 0,
              "pageSize": 20,
            },
            "timestamp": "2026-11-03T10:00:00.000Z",
          } as T,
        );
      } else if (pageNumber == 1) {
        // Return 5 items for page 1 (indicating last page)
        final items = List.generate(5, (i) {
          final index = 20 + i;
          return {
            'type': index % 2 == 0 ? 'CREDIT' : 'DEBIT',
            'amount': (index + 1) * 50,
            'transactionStatus': 'SUCCESS',
            'time': '2026-11-02T10:00:00.000Z',
            'otherPartyName': 'Merchant $index',
            'txRef': 'TXN_REF_$index',
            'description': 'Transaction $index',
          };
        });

        return Response<T>(
          statusCode: 200,
          body: {
            "success": true,
            "code": "OK",
            "message": "Success",
            "data": {
              "items": items,
              "pageNumber": 1,
              "pageSize": 20,
            },
            "timestamp": "2026-11-03T10:00:00.000Z",
          } as T,
        );
      }
    }

    return Response<T>(statusCode: 404, statusText: 'Not found');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('history_test_');
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

  test('HistoryscreenController pagination logic fetches page 0 and appends page 1', () async {
    final mockApi = MockHistoryApiService();
    Get.put<ApiService>(mockApi);
    final controller = Get.put(HistoryscreenController());

    // Wait for initial load
    await Future.delayed(const Duration(milliseconds: 100));

    expect(controller.transactions.length, 20);
    expect(controller.hasMore.value, isTrue);
    expect(controller.currentPage, 0);

    // Call loadMore()
    await controller.loadMore();

    expect(controller.transactions.length, 25);
    expect(controller.hasMore.value, isFalse); // < 20 items returned on page 1
    expect(controller.currentPage, 1);

    // Verify API queries
    expect(mockApi.recordedCalls.length, 2);
    expect(mockApi.recordedCalls[0]['query']['pageNumber'], '0');
    expect(mockApi.recordedCalls[0]['query']['pageSize'], '20');
    expect(mockApi.recordedCalls[1]['query']['pageNumber'], '1');
    expect(mockApi.recordedCalls[1]['query']['pageSize'], '20');
  });

  testWidgets('HistoryscreenView shows Load More button when 20 items loaded and loads all', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put<ApiService>(MockHistoryApiService());

    await tester.pumpWidget(
      const GetMaterialApp(
        home: HistoryscreenView(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final controller = Get.find<HistoryscreenController>();
    expect(controller.transactions.length, 20);
    expect(controller.hasMore.value, isTrue);

    // Jump to bottom: triggers auto-scroll pagination
    controller.scrollController.jumpTo(controller.scrollController.position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 300));

    // Page 1 is auto-loaded: length is now 25, hasMore is false
    expect(controller.transactions.length, 25);
    expect(controller.hasMore.value, isFalse);

    // Jump to new maxScrollExtent where footer is rendered
    controller.scrollController.jumpTo(controller.scrollController.position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text("All transactions loaded"), findsOneWidget);
  });
}
