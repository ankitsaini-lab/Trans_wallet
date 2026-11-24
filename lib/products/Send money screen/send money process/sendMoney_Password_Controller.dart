import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

class SendMoneyPasswordController extends GetxController {
  static const double minTransferAmount = 0.0;
  static const double maxTransferAmount = double.infinity;

  final RxString passcode = ''.obs;
  final RxBool isError = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString statusMessage = ''.obs;

  double amount = 0.0;
  Map<String, String>? recipient;
  String note = '';
  String? paymentMethod;
  String? paymentSource;
  String? senderUpi;

  bool get canUseBiometric {
    try {
      if (Get.isRegistered<BiometricService>()) {
        return BiometricService.to.canLoginWithBiometrics;
      }
    } catch (_) {}
    return false;
  }

  @override
  void onInit() {
    super.onInit();
    passcode.value = '';
    isError.value = false;
    errorMessage.value = '';
    isLoading.value = false;
    statusMessage.value = '';

    final args = Get.arguments;
    if (args != null && args is Map) {
      amount = (args['amount'] ?? 0.0).toDouble();
      if (args['recipient'] != null && args['recipient'] is Map) {
        recipient = Map<String, String>.from(
          (args['recipient'] as Map).map(
            (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
          ),
        );
      }
      note = args['note']?.toString() ?? '';
      paymentMethod = args['paymentMethod']?.toString();
      paymentSource = args['paymentSource']?.toString() ??
          args['paymentMode']?.toString();
      senderUpi = args['senderUpi']?.toString() ??
          args['upiId']?.toString() ??
          args['vpa']?.toString();
    }
  }

  void addDigit(String digit) {
    if (digit == 'back') {
      if (isLoading.value) {
        isLoading.value = false;
      }
      isError.value = false;
      errorMessage.value = '';
      if (passcode.value.isNotEmpty) {
        passcode.value = passcode.value.substring(0, passcode.value.length - 1);
      }
      return;
    }

    if (digit == 'clear') {
      if (isLoading.value) {
        isLoading.value = false;
      }
      isError.value = false;
      errorMessage.value = '';
      passcode.value = '';
      return;
    }

    if (isLoading.value) return;

    if (isError.value) {
      passcode.value = '';
      isError.value = false;
      errorMessage.value = '';
    }

    if (passcode.value.length < 4) {
      passcode.value += digit;
      HapticFeedback.lightImpact();

      if (passcode.value.length == 4) {
        verifyPasscode();
      }
    }
  }

  Future<void> authenticateWithBiometrics() async {
    if (isLoading.value || !canUseBiometric) return;

    if (amount <= 0 || amount > 999999.99) {
      AppSnackbar.error("Amount must be up to 6 digits");
      return;
    }

    try {
      final bioService = BiometricService.to;
      final result = await bioService.authenticate(
        localizedReason:
            "Authenticate to send ₹${amount % 1 == 0 ? amount.toInt() : amount.toStringAsFixed(2)} to ${recipient?['name'] ?? 'recipient'}",
      );

      if (result.success) {
        // ALWAYS verify against the live MPIN API inside so user CANNOT access or send funds if MPIN is locked!
        final savedMpin = box.read<String>('saved_mpin') ??
            box.read<String>('remembered_mpin') ??
            box.read('mpin')?.toString();

        if (savedMpin != null &&
            savedMpin.isNotEmpty &&
            Get.isRegistered<ApiService>()) {
          isLoading.value = true;
          statusMessage.value = "Verifying security credentials...";
          try {
            final mpinRes = await ApiService.to.verifyMpin(savedMpin);
            if (!mpinRes.isSuccess) {
              isLoading.value = false;
              isError.value = true;
              final msg = mpinRes.message.isNotEmpty
                  ? mpinRes.message
                  : "MPIN verification failed. Access denied.";
              errorMessage.value = msg;
              AppSnackbar.error(msg);
              return;
            }
          } finally {
            isLoading.value = false;
          }
        }

        if (Get.isRegistered<AppLockService>()) {
          AppLockService.to.clearMpinLockout();
        }
        await _performTransfer();
      }
    } catch (e) {
      developer.log('[SendMoneyPasswordController] Biometric auth error: $e');
    }
  }

  Future<void> verifyPasscode() async {
    if (isLoading.value) return;

    final enteredPin = passcode.value;
    if (enteredPin.length < 4) return;

    if (amount <= 0 || amount > 999999.99) {
      isError.value = true;
      errorMessage.value = "Amount must be up to 6 digits";
      passcode.value = enteredPin;
      AppSnackbar.error("Amount must be up to 6 digits");
      return;
    }

    // Resolve user's registered phone number from storage
    final rawPhone = box.read<String>('mobileNumber') ??
        box.read<String>('phone') ??
        box.read<String>('remembered_phone') ??
        box.read<String>('user_mobile');

    String userPhone = '';
    if (rawPhone != null && rawPhone.toString().isNotEmpty) {
      final clean = rawPhone.toString().replaceAll(RegExp(r'\D'), '');
      userPhone = clean.length > 10 ? clean.substring(clean.length - 10) : clean;
    }

    if (Get.isRegistered<ApiService>()) {
      try {
        isLoading.value = true;
        statusMessage.value = "Verifying MPIN...";

        final res = await ApiService.to.verifyMpin(
          enteredPin,
          mobileNumber: userPhone,
        );

        if (res.isSuccess) {
          if (Get.isRegistered<AppLockService>()) {
            AppLockService.to.clearMpinLockout();
          }
          HapticFeedback.mediumImpact();
          await _performTransfer();
          return;
        } else {
          HapticFeedback.heavyImpact();
          isLoading.value = false;
          isError.value = true;
          final msg = res.message;
          errorMessage.value = msg;
          passcode.value = enteredPin;
          AppSnackbar.error(msg);
          return;
        }
      } catch (e) {
        developer.log('[SendMoneyPasswordController] MPIN verification error: $e');
        HapticFeedback.heavyImpact();
        isLoading.value = false;
        isError.value = true;
        errorMessage.value = "Failed to verify MPIN. Please try again.";
        passcode.value = enteredPin;
        AppSnackbar.error("Failed to verify MPIN. Please try again.");
        return;
      }
    } else {
      // Local fallback if phone number is not available in storage
      final String? savedMpin = box.read<String>('saved_mpin') ??
          box.read('mpin')?.toString() ??
          box.read('remembered_mpin')?.toString() ??
          box.read('tx_pin')?.toString();

      bool isCorrect = false;
      if (savedMpin != null && savedMpin.isNotEmpty) {
        isCorrect = (enteredPin == savedMpin);
      }

      if (!isCorrect) {
        HapticFeedback.heavyImpact();
        isError.value = true;
        errorMessage.value = "Incorrect MPIN. Please try again.";
        passcode.value = enteredPin;
        return;
      }

      HapticFeedback.mediumImpact();

      try {
        await _performTransfer();
      } catch (e) {
        developer.log('[SendMoneyPasswordController] Error executing transfer: $e');
        isLoading.value = false;
        isError.value = true;
        errorMessage.value = "Transfer error. Please try again.";
        passcode.value = enteredPin;
        AppSnackbar.error("Transfer error. Please try again.");
      }
    }
  }

  Future<void> _performTransfer() async {
    if (amount <= 0 || amount > 999999.99) {
      isLoading.value = false;
      AppSnackbar.error("Amount must be up to 6 digits");
      isError.value = true;
      errorMessage.value = "Amount must be up to 6 digits";
      passcode.value = '';
      return;
    }
    final rawPhone = recipient?['phone'] ?? '';
    final cleanedPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    final toMobileNumber = cleanedPhone.length > 10
        ? cleanedPhone.substring(cleanedPhone.length - 10)
        : cleanedPhone;

    if (toMobileNumber.length < 10) {
      isLoading.value = false;
      AppSnackbar.error("Invalid recipient phone number");
      isError.value = true;
      errorMessage.value = "Invalid recipient phone number";
      passcode.value = '';
      return;
    }

    final box = GetStorage();
    if (box.read('is_blocked') == true ||
        box.read('is_card_blocked') == true ||
        box.read('is_frozen') == true) {
      isLoading.value = false;
      AppSnackbar.error(
        "Your card is currently frozen. Transfers are disabled while the card is frozen.",
        title: "Card Frozen",
      );
      isError.value = true;
      errorMessage.value = "Card is frozen. Cannot transfer money.";
      passcode.value = '';
      return;
    }
    if (box.read('is_permanently_blocked') == true ||
        box.read('is_card_permanently_blocked') == true) {
      isLoading.value = false;
      AppSnackbar.error(
        "Your card is permanently blocked. Send Money is disabled.",
        title: "Card Blocked",
      );
      isError.value = true;
      errorMessage.value = "Card is permanently blocked.";
      passcode.value = '';
      return;
    }

    try {
      isLoading.value = true;
      statusMessage.value = "Authorizing transfer...";

      final idempotencyKey = "C2C${DateTime.now().millisecondsSinceEpoch}";
      final description = note.isNotEmpty ? note : "Customer to customer transfer";

      final res = await ApiService.to.transferC2C(
        toMobileNumber: toMobileNumber,
        amount: amount,
        idempotencyKey: idempotencyKey,
        description: description,
      );

      if (res != null) {
        final status = res['status']?.toString().toUpperCase();
        final isSuccess =
            res['apiSuccess'] == true ||
            status == 'PAYMENT_SUCCESS' ||
            status == 'SUCCESS';

        if (isSuccess) {
          // Update local balance
          if (res['balance'] != null) {
            double newBalance = (res['balance'] as num).toDouble();
            box.write('balance', newBalance);
          } else {
            final storedBalance = box.read('balance');
            final double currentBalance = storedBalance is num
                ? storedBalance.toDouble()
                : (double.tryParse(storedBalance?.toString() ?? '') ?? 0.0);
            box.write(
              'balance',
              (currentBalance - amount).clamp(0.0, double.infinity),
            );
          }

          // Save recipient to recent_w2w_recipients in GetStorage
          if (recipient != null) {
            try {
              final raw = box.read('recent_w2w_recipients');
              List<Map<String, String>> list = [];
              if (raw != null && raw is List) {
                list = raw
                    .map((e) => Map<String, String>.from(e as Map))
                    .toList();
              }
              final phoneClean = (recipient!['phone'] ?? '').replaceAll(
                RegExp(r'\D'),
                '',
              );
              final phoneToCompare = phoneClean.length > 10
                  ? phoneClean.substring(phoneClean.length - 10)
                  : phoneClean;
              list.removeWhere((item) {
                final p = (item['phone'] ?? '').replaceAll(RegExp(r'\D'), '');
                final p10 = p.length > 10 ? p.substring(p.length - 10) : p;
                return p10 == phoneToCompare;
              });
              list.insert(0, Map<String, String>.from(recipient!));
              if (list.length > 20) list = list.sublist(0, 20);
              box.write('recent_w2w_recipients', list);
            } catch (e) {
              developer.log('Error saving recent recipient on success: $e');
            }
          }

          Get.offNamed(
            '/SendMoneySuccessView',
            arguments: {
              'amount': amount,
              'recipient': recipient,
              'note': note,
              'providerRef': res['providerRef'],
              'externalTransactionId':
                  res['externalTransactionId'] ?? idempotencyKey,
              'transactionType': res['transactionType'] ?? 'C2C',
              'balance': res['balance'],
              'paymentMethod':
                  paymentMethod ?? res['paymentMethod'] ?? 'Transcorp Wallet',
              'paymentSource': paymentSource ?? res['paymentSource'],
              'senderUpi': senderUpi ?? res['senderUpi'],
              'apiData': res,
              'timestamp': res['timestamp'] ?? res['createdAt'] ?? res['date'],
              'status': res['status'],
              'description': res['description'] ?? description,
            },
          );
        } else {
          final msg = res['message'] ??
              res['apiMessage'] ??
              "Transfer failed. Please try again.";
          AppSnackbar.error(msg);
          isError.value = true;
          errorMessage.value = msg;
          passcode.value = '';
        }
      } else {
        AppSnackbar.error(
          "Failed to process transfer. Please check network connection.",
        );
        isError.value = true;
        errorMessage.value = "Failed to process transfer.";
        passcode.value = '';
      }
    } catch (e) {
      AppSnackbar.error("An error occurred during transfer.");
      isError.value = true;
      errorMessage.value = "An error occurred during transfer.";
      passcode.value = '';
    } finally {
      isLoading.value = false;
      statusMessage.value = '';
    }
  }
}
