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
  String? paymentMethod;
  String? paymentSource;
  String? senderUpi;
  Map<String, dynamic>? apiData;
  String? timestamp;
  String? status;
  String? description;

  String get referenceId =>
      providerRef ??
      externalTransactionId ??
      apiData?['providerRef']?.toString() ??
      apiData?['externalTransactionId']?.toString() ??
      "";

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map) {
      if (args['apiData'] != null && args['apiData'] is Map) {
        apiData = Map<String, dynamic>.from(args['apiData'] as Map);
      }
      amount = (args['amount'] ?? apiData?['amount'] ?? 0.0).toDouble();
      if (args['recipient'] != null && args['recipient'] is Map) {
        recipient = Map<String, String>.from(
          (args['recipient'] as Map).map(
            (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
          ),
        );
      }
      note = args['note']?.toString() ??
          args['description']?.toString() ??
          apiData?['description']?.toString() ??
          '';
      providerRef = args['providerRef']?.toString() ??
          apiData?['providerRef']?.toString();
      externalTransactionId = args['externalTransactionId']?.toString() ??
          apiData?['externalTransactionId']?.toString();
      transactionType = args['transactionType']?.toString() ??
          apiData?['transactionType']?.toString() ??
          'C2C';
      if (args['balance'] != null) {
        balance = (args['balance'] as num).toDouble();
      } else if (apiData?['balance'] != null) {
        balance = (apiData!['balance'] as num).toDouble();
      }
      paymentMethod = args['paymentMethod']?.toString() ??
          apiData?['paymentMethod']?.toString();
      paymentSource = args['paymentSource']?.toString() ??
          args['paymentMode']?.toString() ??
          apiData?['paymentSource']?.toString();
      senderUpi = args['senderUpi']?.toString() ??
          args['upiId']?.toString() ??
          args['vpa']?.toString() ??
          apiData?['senderUpi']?.toString();
      timestamp = args['timestamp']?.toString() ??
          apiData?['timestamp']?.toString() ??
          apiData?['createdAt']?.toString();
      status = args['status']?.toString() ?? apiData?['status']?.toString();
      description = args['description']?.toString() ??
          apiData?['description']?.toString();
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
      'paymentMethod': paymentMethod,
      'paymentSource': paymentSource,
      'senderUpi': senderUpi,
      'apiData': apiData,
      'timestamp': timestamp,
      'status': status,
      'description': description,
    });
  }
}
