import 'package:get/get.dart';
import 'package:transwallet/products/Dashboard%20screen/dashboardscreen_Controller.dart';

class DashboardscreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardscreenController>(
      () => DashboardscreenController(),
      fenix: true,
    );
  }
}
