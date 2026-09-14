import 'package:get/get.dart';
import 'package:transwallet/utilities/getStorage.dart';

class SendMoneyPasswordController extends GetxController {
  var passcode = ''.obs;
  var isError = false.obs;

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

  void addDigit(String digit) {
    if (isError.value) {
      passcode.value = '';
      isError.value = false;
    }
    
    if (digit == 'back') {
      if (passcode.value.isNotEmpty) {
        passcode.value = passcode.value.substring(0, passcode.value.length - 1);
      }
      return;
    }

    if (passcode.value.length < 4) {
      passcode.value += digit;
      
      if (passcode.value.length == 4) {
        verifyPasscode();
      }
    }
  }

  void verifyPasscode() async {
    // For now, accept any 4 digit passcode or hardcoded "1234" 
    if (passcode.value == "1234" || passcode.value.length == 4) {
      // Simulate processing
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update balance
      double currentBalance = (box.read('balance') ?? 1600).toDouble();
      box.write('balance', currentBalance - amount);
      
      Get.offNamed('/SendMoneySuccessView', arguments: {
        'amount': amount,
        'recipient': recipient,
        'note': note,
      });
    } else {
      isError.value = true;
    }
  }
}
