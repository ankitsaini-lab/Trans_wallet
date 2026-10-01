import 'package:get/get.dart';
import 'package:transwallet/modules/vkyc/controllers/vkyc_controller.dart';
import 'package:transwallet/modules/vkyc/services/vkyc_test_service.dart';

class VkycBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VkycTestService>(() => VkycTestService());
    Get.lazyPut<VkycController>(() => VkycController());
  }
}
