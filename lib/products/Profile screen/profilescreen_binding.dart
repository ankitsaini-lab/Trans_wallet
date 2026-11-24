import 'package:get/get.dart';
import 'package:transwallet/products/Profile%20screen/profilescreen_Controller.dart';

class ProfilescreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfilescreenController>(
      () => ProfilescreenController(),
      fenix: true,
    );
  }
}

