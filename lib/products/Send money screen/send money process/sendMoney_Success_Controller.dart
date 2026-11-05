import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

class SendMoneySuccessController extends GetxController {
  double amount = 0.0;
  Map<String, String>? recipient;
  String note = '';
  String? providerRef;
  String? externalTransactionId;
  String? transactionType;
  double? balance;

  String get referenceId =>
      providerRef ??
      externalTransactionId ??
      "C2C${DateTime.now().millisecondsSinceEpoch}";

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
      if (args['balance'] != null) {
        balance = (args['balance'] as num).toDouble();
      }
    }

    if (balance == null) {
      final savedBalance = box.read('balance');
      if (savedBalance != null) {
        balance = (savedBalance as num).toDouble();
      }
    }

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  void copyReferenceId() {
    final ref = referenceId;
    Clipboard.setData(ClipboardData(text: ref));
    HapticFeedback.lightImpact();
    AppSnackbar.success("Reference ID copied to clipboard");
  }

  String get maskedAccountNumber {
    final explicitAccount = recipient?['accountNumber'] ??
        recipient?['account_number'] ??
        recipient?['accountNo'];
    if (explicitAccount != null && explicitAccount.isNotEmpty) {
      final clean = explicitAccount.replaceAll(RegExp(r'\s+'), '');
      if (clean.length > 4) {
        return "A/c •••• ${clean.substring(clean.length - 4)}";
      }
      return "A/c •••• $clean";
    }

    final rawPhone = recipient?['phone'] ?? '';
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 4) {
      final last4 = digits.substring(digits.length - 4);
      return "A/c linked to ••••• $last4";
    }
    return "Transwallet Account";
  }

  void goToDashboard() {
    Get.offAllNamed('/dashboard');
  }

  void downloadReceipt() {
    HapticFeedback.lightImpact();
    viewReceipt();
  }

  void viewReceipt() {
    Get.toNamed('/SendMoneyReceiptView', arguments: {
      'amount': amount,
      'recipient': recipient,
      'note': note,
      'providerRef': providerRef,
      'externalTransactionId': externalTransactionId,
      'transactionType': transactionType,
      'balance': balance,
    });
  }
}
