import 'package:get/get.dart';

class SendMoneyReceiptController extends GetxController {
  late double amount;
  Map<String, String>? recipient;
  String note = '';
  String? providerRef;
  String? externalTransactionId;
  String? transactionType;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null) {
      amount = (args['amount'] ?? 0.0).toDouble();
      recipient = args['recipient'];
      note = args['note'] ?? '';
      providerRef = args['providerRef']?.toString();
      externalTransactionId = args['externalTransactionId']?.toString();
      transactionType = args['transactionType']?.toString() ?? 'C2C';
    }
  }
}
