import 'package:get/get.dart';
import 'package:transwallet/products/History%20screen/historyscreen_Controller.dart';

class HistoryscreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HistoryscreenController>(
      () => HistoryscreenController(),
      fenix: true,
    );
  }
}

