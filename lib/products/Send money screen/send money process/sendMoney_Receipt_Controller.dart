import 'package:get/get.dart';

class SendMoneyReceiptController extends GetxController {
  late double amount;
  Map<String, String>? recipient;
  String note = '';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null) {
      amount = args['amount'] ?? 0.0;
      recipient = args['recipient'];
      note = args['note'] ?? '';
    }
  }
}
