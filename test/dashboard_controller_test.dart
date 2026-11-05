import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Dashboard%20screen/dashboardscreen_Controller.dart';
import 'package:transwallet/products/Dashboard%20screen/dashboardscreen_binding.dart';
import 'package:transwallet/products/Dashboard%20screen/dashboardscreen_view.dart';

void main() {
  setUp(() async {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  test('DashboardscreenBinding registers DashboardscreenController', () {
    final binding = DashboardscreenBinding();
    binding.dependencies();

    expect(Get.isRegistered<DashboardscreenController>(), isTrue);
    final ctrl = Get.find<DashboardscreenController>();
    expect(ctrl, isNotNull);
  });
}
