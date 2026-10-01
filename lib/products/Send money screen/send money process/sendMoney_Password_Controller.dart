import 'package:get/get.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

class SendMoneyPasswordController extends GetxController {
  var passcode = ''.obs;
  var isError = false.obs;
  var isLoading = false.obs;

  late double amount;
  Map<String, String>? recipient;
  String note = '';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null) {
      amount = (args['amount'] ?? 0.0).toDouble();
      recipient = args['recipient'];
      note = args['note'] ?? '';
    }
  }

  void addDigit(String digit) {
    if (isLoading.value) return;
    if (isError.value) {
      passcode.value = '';
      isError.value = false;
    }

    if (digit == 'back') {
      if (passcode.value.isNotEmpty) {
        passcode.value =
            passcode.value.substring(0, passcode.value.length - 1);
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

  Future<void> verifyPasscode() async {
    if (isLoading.value) return;

    final rawPhone = recipient?['phone'] ?? '';
    final cleanedPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    final toMobileNumber = cleanedPhone.length > 10
        ? cleanedPhone.substring(cleanedPhone.length - 10)
        : cleanedPhone;

    if (toMobileNumber.length < 10) {
      AppSnackbar.error("Invalid recipient phone number");
      isError.value = true;
      passcode.value = '';
      return;
    }

    try {
      isLoading.value = true;
      final idempotencyKey = "W2W${DateTime.now().millisecondsSinceEpoch}";
      final description = note.isNotEmpty ? note : "Wallet to wallet transfer";

      final res = await ApiService.to.transferW2W(
        toMobileNumber: toMobileNumber,
        amount: amount,
        idempotencyKey: idempotencyKey,
        description: description,
      );

      if (res != null) {
        final status = res['status']?.toString().toUpperCase();
        final isSuccess = res['apiSuccess'] == true ||
            status == 'PAYMENT_SUCCESS' ||
            status == 'SUCCESS';

        if (isSuccess) {
          // Update local balance
          if (res['balance'] != null) {
            double newBalance = (res['balance'] as num).toDouble();
            box.write('balance', newBalance);
          } else {
            double currentBalance = (box.read('balance') ?? 1600).toDouble();
            box.write('balance', currentBalance - amount);
          }

          Get.offNamed('/SendMoneySuccessView', arguments: {
            'amount': amount,
            'recipient': recipient,
            'note': note,
            'providerRef': res['providerRef'],
            'externalTransactionId':
                res['externalTransactionId'] ?? idempotencyKey,
          });
        } else {
          final msg = res['message'] ?? "Transfer failed. Please try again.";
          AppSnackbar.error(msg);
          isError.value = true;
          passcode.value = '';
        }
      } else {
        AppSnackbar.error(
          "Failed to process transfer. Please check network connection.",
        );
        isError.value = true;
        passcode.value = '';
      }
    } catch (e) {
      AppSnackbar.error("An error occurred during transfer.");
      isError.value = true;
      passcode.value = '';
    } finally {
      isLoading.value = false;
    }
  }
}
