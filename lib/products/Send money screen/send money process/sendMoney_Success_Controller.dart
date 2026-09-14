import 'package:get/get.dart';

class SendMoneySuccessController extends GetxController {
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

  void goToDashboard() {
    Get.offAllNamed('/dashboard'); // Adjust to your actual dashboard route
  }

  void viewReceipt() {
    Get.toNamed('/SendMoneyReceiptView', arguments: {
      'amount': amount,
      'recipient': recipient,
      'note': note,
    });
  }
}
