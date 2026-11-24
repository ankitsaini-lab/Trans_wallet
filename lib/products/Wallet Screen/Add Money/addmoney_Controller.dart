import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/custom_numeric_keypad.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/products/Dashboard screen/controllers/wallet_card_controller.dart';

class AddmoneyController extends GetxController
    implements PayUCheckoutProProtocol {
  // Wallet limits
  static const double minKycMaxWalletLimit = 10000.0; // ₹10,000 for Min KYC
  static const double fullKycMaxWalletLimit =
      200000.0; // ₹2,00,000 for Full KYC

  final RxDouble balance = 0.0.obs;
  final RxBool isFullKyc = false.obs;
  final RxBool isPermanentlyBlocked = false.obs;
  late PayUCheckoutProFlutter _payUCheckoutProFlutter;
  String? dynamicMerchantKey;
  String? dynamicMerchantSalt;
  String? apiHash;
  String? currentTxnRef;
  Map<String, String> apiHashesMap = {};
  Map<String, dynamic> lastPayUMap = {};

  /// Current wallet holding limit based on user's KYC tier
  double get maxWalletLimit =>
      isFullKyc.value ? fullKycMaxWalletLimit : minKycMaxWalletLimit;

  /// Maximum amount the user can add without exceeding their wallet holding limit:
  /// maxAddableAmount = max(0, maxWalletLimit - currentBalance)
  double get maxAddableAmount {
    final remaining = maxWalletLimit - balance.value;
    return remaining > 0 ? remaining : 0.0;
  }

  /// Whether current wallet balance has already reached or exceeded the holding limit
  bool get isLimitReached => balance.value >= maxWalletLimit;

  /// Whether currently entered amount exceeds the allowable addition
  bool get isAmountExceedingLimit => amount > maxAddableAmount;

  /// Whether the user can proceed with adding money
  bool get canProceed =>
      amount > 0 &&
      !isLimitReached &&
      !isAmountExceedingLimit &&
      !isProcessing.value &&
      !isPermanentlyBlocked.value;

  /// Evaluate whether card or user account is permanently blocked
  void checkBlockedStatus() {
    final box = GetStorage();

    // 1. Direct explicit flags in storage
    if (box.read('is_permanently_blocked') == true ||
        box.read('is_card_permanently_blocked') == true) {
      isPermanentlyBlocked.value = true;
      return;
    }

    // 2. User account status
    final userStatus = box.read('user_status')?.toString().toUpperCase() ?? '';
    if (userStatus == 'BLOCKED' ||
        userStatus == 'PERMANENT_BLOCK' ||
        userStatus == 'PERMANENTLY_BLOCKED') {
      isPermanentlyBlocked.value = true;
      return;
    }

    // 3. Check user_cards
    final storedCards = box.read('user_cards');
    if (storedCards is List && storedCards.isNotEmpty) {
      for (var c in storedCards) {
        if (c is Map) {
          final rawStatus = c['status']?.toString().toUpperCase() ?? '';
          if (rawStatus == 'BLOCKED' ||
              rawStatus == 'PERMANENT_BLOCK' ||
              rawStatus == 'PERMANENTLY_BLOCKED' ||
              c['isPermanentlyBlocked'] == true) {
            isPermanentlyBlocked.value = true;
            return;
          }
        }
      }
    }

    // 4. Check WalletCardController if active
    if (Get.isRegistered<WalletCardController>()) {
      final wcc = Get.find<WalletCardController>();
      if (wcc.cards.isNotEmpty) {
        if (wcc.cards.every((c) => c.isPermanentlyBlocked) ||
            wcc.cards.first.isPermanentlyBlocked) {
          isPermanentlyBlocked.value = true;
          return;
        }
      }
    }

    isPermanentlyBlocked.value = false;
  }

  /// Evaluate user's Full KYC status from storage
  void checkKycStatus() {
    final box = GetStorage();
    final rawStatus = box.read('kyc_status')?.toString().toLowerCase() ?? '';
    final currentLevel =
        box.read('kyc_current_level')?.toString().toUpperCase() ?? '';

    final bool completed =
        box.read('full_kyc_completed') == true ||
        box.read('is_kyc_completed') == true ||
        currentLevel == 'FULL' ||
        rawStatus == 'verified' ||
        rawStatus == 'completed' ||
        rawStatus == 'approved' ||
        rawStatus == 'upgrade_success';
    isFullKyc.value = completed;
  }

  /// Format numbers in Indian number format (e.g. 10,000 or 2,00,000)
  String formatCurrency(double val, {bool showDecimals = false}) {
    if (val >= 1000) {
      final intPart = val.toInt();
      final s = intPart.toString();
      String formatted;
      if (s.length <= 3) {
        formatted = s;
      } else {
        final lastThree = s.substring(s.length - 3);
        final otherNumbers = s.substring(0, s.length - 3);
        final otherFormatted = otherNumbers.replaceAllMapped(
          RegExp(r'\B(?=(\d{2})+(?!\d))'),
          (match) => ",",
        );
        formatted = "$otherFormatted,$lastThree";
      }
      if (showDecimals && val % 1 != 0) {
        final dec = (val - intPart).toStringAsFixed(2).substring(1);
        return "$formatted$dec";
      }
      return formatted;
    }
    return showDecimals ? val.toStringAsFixed(2) : val.toInt().toString();
  }

  Future<void> fetchWalletBalance() async {
    final stored = box.read('balance') ?? box.read('wallet_balance');
    if (stored is num) {
      balance.value = stored.toDouble();
    }
    if (Get.isRegistered<ApiService>()) {
      final res = await ApiService.to.fetchWalletBalance();
      if (res != null && res['balance'] != null) {
        final num apiBal = res['balance'] is num
            ? res['balance']
            : num.tryParse(res['balance'].toString()) ?? 0;
        balance.value = apiBal.toDouble();
        box.write('balance', balance.value);
        box.write('wallet_balance', balance.value);
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    checkBlockedStatus();
    checkKycStatus();
    fetchWalletBalance();
    _refreshUserData();
    _payUCheckoutProFlutter = PayUCheckoutProFlutter(this);
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.setPaymentFlowActive(true);
    }
  }

  Future<void> _refreshUserData() async {
    if (Get.isRegistered<ApiService>()) {
      try {
        await ApiService.to.fetchUserProfile();
        checkBlockedStatus();
        checkKycStatus();
      } catch (_) {}
    }
  }

  @override
  void onClose() {
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.setPaymentFlowActive(false);
    }
    super.onClose();
  }

  void resetInput() {
    enteredAmount.value = '0';
    selectedPreset.value = 0;
  }

  var enteredAmount = '0'.obs;
  var selectedPreset = 0.obs;
  var isProcessing = false.obs;
  var showSuccess = false.obs;
  var fundingSource = "PayU PG SDK".obs;

  final LocalAuthentication auth = LocalAuthentication();

  double get amount =>
      double.tryParse(
        enteredAmount.value.isEmpty ? "0" : enteredAmount.value,
      ) ??
      0;

  String formatAmount(String value) {
    if (value.isEmpty) return "0";
    if (value.contains('.')) {
      final parts = value.split('.');
      final intPart = int.tryParse(parts[0]) ?? 0;
      final formattedInt = intPart.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ",",
      );
      return "$formattedInt.${parts.length > 1 ? parts[1] : ''}";
    }
    final number = int.tryParse(value) ?? 0;
    return number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ",",
    );
  }

  void setAmount(String value) {
    if (value == 'back') {
      if (enteredAmount.value.isNotEmpty) {
        enteredAmount.value = enteredAmount.value.substring(
          0,
          enteredAmount.value.length - 1,
        );
        if (enteredAmount.value.isEmpty) {
          enteredAmount.value = '0';
        }
      }
    } else if (value == '.') {
      if (enteredAmount.value.contains('.')) return;
      if (enteredAmount.value.isEmpty || enteredAmount.value == '0') {
        enteredAmount.value = '0.';
      } else {
        enteredAmount.value += '.';
      }
    } else {
      if (isLimitReached) {
        if (!isFullKyc.value) {
          showUpgradeKycDialog();
        } else {
          AppSnackbar.error("Wallet limit of ₹2,00,000 reached.");
        }
        return;
      }

      if (enteredAmount.value == '0') {
        enteredAmount.value = value;
      } else if (enteredAmount.value.length < 9) {
        if (enteredAmount.value.contains('.')) {
          final parts = enteredAmount.value.split('.');
          if (parts.length > 1 && parts[1].length >= 2) return;
        }
        enteredAmount.value += value;
      }
    }
    _updateSelectedPreset();
  }

  void setPreset(int amountVal) {
    if (isLimitReached) {
      if (!isFullKyc.value) {
        showUpgradeKycDialog(attemptedAmount: amountVal.toDouble());
      } else {
        AppSnackbar.error(
          "Your wallet has reached the maximum limit of ₹2,00,000.",
        );
      }
      return;
    }

    if (amountVal > maxAddableAmount) {
      final allowedStr = formatCurrency(maxAddableAmount);
      if (!isFullKyc.value) {
        AppSnackbar.error(
          "Cannot add ₹$amountVal. With your current balance, you can add up to ₹$allowedStr (Min KYC limit: ₹10,000).",
        );
        showUpgradeKycDialog(attemptedAmount: amountVal.toDouble());
      } else {
        AppSnackbar.error(
          "Cannot add ₹$amountVal. With your current balance, you can add up to ₹$allowedStr (Full KYC limit: ₹2,00,000).",
        );
      }
      return;
    }

    enteredAmount.value = amountVal.toString();
    selectedPreset.value = amountVal;
  }

  void _updateSelectedPreset() {
    final currentAmount = double.tryParse(enteredAmount.value) ?? 0.0;
    if ([500, 1000, 2000, 5000].contains(currentAmount)) {
      selectedPreset.value = currentAmount.toInt();
    } else {
      selectedPreset.value = 0;
    }
  }

  /// Informative dialog shown when user attempts to exceed Min KYC limits
  void showUpgradeKycDialog({double? attemptedAmount}) {
    final allowedStr = formatCurrency(maxAddableAmount);
    final balStr = formatCurrency(balance.value, showDecimals: true);
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: primaryLightYellow,
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryYellow, width: 2),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: primaryRed,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Wallet Limit Restricted",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "KYC Status",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              isFullKyc.value ? "Full KYC" : "Min KYC",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isFullKyc.value
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16, thickness: 0.8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Holding Limit",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              "₹${formatCurrency(maxWalletLimit)}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Current Balance",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              "₹$balStr",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16, thickness: 0.8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Max You Can Add",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "₹$allowedStr",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: primaryRed,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    !isFullKyc.value
                        ? "Min KYC accounts can hold up to ₹10,000. Upgrade to Full KYC (VKYC) to increase your wallet limit to ₹2,00,000."
                        : "Your account is limited to a maximum holding balance of ₹2,00,000.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Get.back(),
                          child: const Text(
                            "Got It",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (!isFullKyc.value) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              Get.back();
                              Get.toNamed('/updateKyc');
                            },
                            child: const Text(
                              "Upgrade KYC",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> authenticate() async {
    if (Get.isRegistered<BiometricService>()) {
      final result = await BiometricService.to.authenticate(
        localizedReason: 'Confirm payment',
        biometricOnly: true,
      );
      return result.success;
    }
    try {
      final canCheck = await auth.canCheckBiometrics;
      if (!canCheck) return false;
      return await auth.authenticate(
        localizedReason: 'Confirm payment',
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }

  bool _hasCalledHashApi = false;
  final Map<String, String> _generatedHashesCache = {};

  // PayU CheckoutPro Protocol Implementations
  @override
  generateHash(Map response) async {
    final String hashName = response['hashName']?.toString() ?? '';
    final String hashString = response['hashString']?.toString() ?? '';
    final String hashType = response['hashType']?.toString() ?? 'V1';
    final String? postSaltRaw =
        response['postSalt']?.toString() ??
        response['CP_POST_SALT']?.toString();
    final String? postSalt =
        (postSaltRaw != null &&
            postSaltRaw.isNotEmpty &&
            postSaltRaw != 'string')
        ? postSaltRaw
        : null;

    debugPrint(
      '[PayU SDK generateHash Callback] hashName: $hashName, hashString: $hashString, hashType: $hashType, postSalt: $postSalt',
    );

    if (hashName.isEmpty) return;

    // Return cached hash if already generated for this hashName
    if (_generatedHashesCache.containsKey(hashName) &&
        _generatedHashesCache[hashName]!.isNotEmpty) {
      debugPrint('[PayU generateHash] Reusing cached hash for $hashName');
      _payUCheckoutProFlutter.hashGenerated(
        hash: {hashName: _generatedHashesCache[hashName]!},
      );
      return;
    }

    // Call Hash API ONLY ONE TIME per PayU checkout session
    if (!_hasCalledHashApi && Get.isRegistered<ApiService>()) {
      _hasCalledHashApi = true;
      try {
        final hashRes = await ApiService.to.generatePayUHash(
          hashName: hashName,
          hashString: hashString,
          hashType: hashType,
          postSalt: postSalt,
        );

        if (hashRes != null) {
          final String resHashName =
              hashRes['hashName']?.toString() ?? hashName;
          final String generatedHash = hashRes['hash']?.toString() ?? '';
          if (generatedHash.isNotEmpty) {
            debugPrint(
              '[PayU Hash API Success] $resHashName -> $generatedHash',
            );
            _generatedHashesCache[resHashName] = generatedHash;
            Map<String, String> hashMap = {resHashName: generatedHash};
            _payUCheckoutProFlutter.hashGenerated(hash: hashMap);
            return;
          }
        }
      } catch (e) {
        debugPrint('[PayU generateHash API Exception] $e');
      }
    }

    // Fallback: check cached hashes, pre-supplied API hashes, or dynamic salt calculation if Hash API was already called once or failed
    String hash =
        _generatedHashesCache[hashName] ?? apiHashesMap[hashName] ?? '';
    if (hash.isEmpty && apiHash != null && apiHash!.isNotEmpty) {
      hash = apiHash!;
    } else if (hash.isEmpty &&
        hashString.isNotEmpty &&
        dynamicMerchantSalt != null &&
        dynamicMerchantSalt!.isNotEmpty) {
      hash = sha512
          .convert(utf8.encode(hashString + dynamicMerchantSalt!))
          .toString();
    }

    if (hash.isNotEmpty) {
      _generatedHashesCache[hashName] = hash;
      Map<String, String> hashMap = {hashName: hash};
      _payUCheckoutProFlutter.hashGenerated(hash: hashMap);
    }
  }

  Map<String, dynamic> _parsePayUResponse(dynamic response) {
    Map<String, dynamic> payu = {};
    if (response is Map) {
      if (response['payuResponse'] != null && response['payuResponse'] is Map) {
        payu = Map<String, dynamic>.from(response['payuResponse'] as Map);
      } else {
        payu = Map<String, dynamic>.from(response);
      }
    } else if (response is String) {
      try {
        final decoded = json.decode(response);
        if (decoded is Map) {
          if (decoded['payuResponse'] != null &&
              decoded['payuResponse'] is Map) {
            payu = Map<String, dynamic>.from(decoded['payuResponse'] as Map);
          } else {
            payu = Map<String, dynamic>.from(decoded);
          }
        }
      } catch (_) {}
    }
    return payu;
  }

  @override
  onPaymentSuccess(dynamic response) {
    isProcessing.value = false;
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.setPaymentFlowActive(false);
    }
    debugPrint('[PayU Payment Success] $response');

    final payu = _parsePayUResponse(response);
    final status = payu['status']?.toString().toLowerCase() ?? 'success';
    final unmapped = payu['unmappedstatus']?.toString().toLowerCase() ?? '';
    final String resTxnId =
        payu['txnid']?.toString() ?? payu['transaction_id']?.toString() ?? '';
    final String bankRefNo =
        payu['bank_ref_no']?.toString() ?? payu['field1']?.toString() ?? '';
    final String mode =
        payu['mode']?.toString() ??
        payu['PG_TYPE']?.toString() ??
        'PayU PG SDK';
    final String msg =
        payu['field9']?.toString() ??
        payu['Error_Message']?.toString() ??
        'Transaction Successful';
    final double resAmount =
        double.tryParse(payu['amount']?.toString() ?? '') ?? amount;

    // Handle PENDING state
    if (status == 'pending' ||
        status == 'inprogress' ||
        unmapped == 'pending' ||
        unmapped == 'initiated') {
      fetchWalletBalance();
      AppSnackbar.warning(
        "Payment is pending confirmation from bank.",
        title: "Payment Pending",
      );
      Get.offNamed(
        '/payment_receipt',
        arguments: {
          'amount': resAmount,
          'balance': balance.value,
          'paymentMode': mode,
          'status': 'Pending',
          'txnId': resTxnId,
          'transactionReference': currentTxnRef ?? resTxnId,
          'bankRefNo': bankRefNo,
          'message': msg,
        },
      );
      return;
    }

    // Handle FAILURE state sent in success callback
    if (status == 'failure' ||
        status == 'failed' ||
        unmapped == 'failed' ||
        unmapped == 'bounced') {
      onPaymentFailure(response);
      return;
    }

    // Handle SUCCESS state
    final String activeTxnRef = resTxnId.isNotEmpty
        ? resTxnId
        : (currentTxnRef ?? '');

    if (activeTxnRef.isNotEmpty && Get.isRegistered<ApiService>()) {
      ApiService.to
          .verifyWalletLoad(
            activeTxnRef,
            verificationPayload: {
              'txnid': activeTxnRef,
              'amount': resAmount,
              'status': 'success',
              'bank_ref_no': bankRefNo,
              'payuResponse': payu,
            },
          )
          .then((verifyRes) {
            developer.log(
              '[AddMoneyController] /api/v1/wallet/loads/$activeTxnRef/verify response: $verifyRes',
            );
            debugPrint(
              '[AddMoneyController] /api/v1/wallet/loads/$activeTxnRef/verify response: $verifyRes',
            );
            fetchWalletBalance();
          })
          .catchError((e) {
            developer.log('[AddMoneyController] verifyWalletLoad error: $e');
            debugPrint('[AddMoneyController] verifyWalletLoad error: $e');
            fetchWalletBalance();
          });
    }

    balance.value += resAmount;
    box.write('balance', balance.value);
    fetchWalletBalance();

    Get.offNamed(
      '/payment_receipt',
      arguments: {
        'amount': resAmount,
        'balance': balance.value,
        'paymentMode': mode,
        'status': 'Success',
        'txnId': resTxnId,
        'transactionReference': currentTxnRef ?? resTxnId,
        'bankRefNo': bankRefNo,
        'message': msg,
      },
    );
  }

  @override
  onPaymentFailure(dynamic response) {
    isProcessing.value = false;
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.setPaymentFlowActive(false);
    }
    debugPrint('[PayU Payment Failure] $response');

    final payu = _parsePayUResponse(response);
    final String resTxnId =
        payu['txnid']?.toString() ?? payu['transaction_id']?.toString() ?? '';
    final String bankRefNo =
        payu['bank_ref_no']?.toString() ?? payu['field1']?.toString() ?? '';
    final String mode =
        payu['mode']?.toString() ??
        payu['PG_TYPE']?.toString() ??
        'PayU PG SDK';
    final String msg =
        payu['Error_Message']?.toString() ??
        payu['field9']?.toString() ??
        'Payment Failed';
    final double resAmount =
        double.tryParse(payu['amount']?.toString() ?? '') ?? amount;

    AppSnackbar.error(msg, title: "Payment Failed");

    Get.offNamed(
      '/payment_receipt',
      arguments: {
        'amount': resAmount,
        'balance': balance.value,
        'paymentMode': mode,
        'status': 'Failed',
        'txnId': resTxnId,
        'transactionReference': currentTxnRef ?? resTxnId,
        'bankRefNo': bankRefNo,
        'message': msg,
      },
    );
  }

  @override
  onPaymentCancel(dynamic response) {
    isProcessing.value = false;
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.setPaymentFlowActive(false);
    }
    debugPrint('[PayU Payment Cancel] $response');
    AppSnackbar.warning("Payment process was cancelled.", title: "Cancelled");
  }

  @override
  onError(dynamic response) {
    isProcessing.value = false;
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.setPaymentFlowActive(false);
    }
    debugPrint('[PayU Error] $response');
    AppSnackbar.error(
      "PayU Error: ${response?.toString() ?? 'Failed to initialize payment'}",
      title: "PayU Error",
    );
  }

  Future<void> openPayUCheckout() async {
    checkBlockedStatus();
    if (isPermanentlyBlocked.value) {
      AppSnackbar.error(
        "Your card is permanently blocked. You cannot add money to this wallet.",
        title: "Card Blocked",
      );
      return;
    }

    if (amount <= 0) {
      AppSnackbar.error("Please enter a valid amount");
      return;
    }

    if (isLimitReached || isAmountExceedingLimit) {
      final allowedStr = formatCurrency(maxAddableAmount);
      AppSnackbar.error(
        !isFullKyc.value
            ? "Cannot add ₹${formatCurrency(amount)}. Maximum allowed addition is ₹$allowedStr (Min KYC limit: ₹10,000)."
            : "Cannot add ₹${formatCurrency(amount)}. Maximum allowed addition is ₹$allowedStr (Full KYC limit: ₹2,00,000).",
      );
      return;
    }

    _hasCalledHashApi = false;
    _generatedHashesCache.clear();

    isProcessing.value = true;
    HapticFeedback.mediumImpact();

    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.startExternalFlow(ExternalFlowType.payment);
    }

    final String txnId = "TXN${DateTime.now().millisecondsSinceEpoch}";
    final String userPhone =
        box.read('phone')?.toString() ??
        box.read('mobileNumber')?.toString() ??
        "9999999999";
    final String userName = box.read('name')?.toString() ?? "Transwallet User";
    final String userEmail =
        box.read('email')?.toString() ?? "user@transwallet.com";

    Map<String, dynamic>? apiData;
    if (Get.isRegistered<ApiService>()) {
      try {
        apiData = await ApiService.to.initiateWalletLoad(
          amount: amount,
          idempotencyKey: txnId,
        );
        print('[AddMoneyController] /api/v1/wallet/loads response: $apiData');
        debugPrint(
          '[AddMoneyController] /api/v1/wallet/loads response: $apiData',
        );
      } catch (e) {
        debugPrint('[Wallet Load API Call Exception] $e');
      }
    }

    Map<String, dynamic> payuMap = {};
    if (apiData != null && apiData['payu'] != null && apiData['payu'] is Map) {
      payuMap = Map<String, dynamic>.from(apiData['payu'] as Map);
    } else if (apiData != null) {
      payuMap = apiData;
    } else {
      isProcessing.value = false;
      AppSnackbar.error("Failed to initiate payment. Please try again.");
      return;
    }

    final String activeKey =
        payuMap['key']?.toString() ??
        payuMap['merchantKey']?.toString() ??
        payuMap['merchant_key']?.toString() ??
        "";

    if (activeKey.isEmpty) {
      isProcessing.value = false;
      AppSnackbar.error("Merchant key missing in payment response");
      return;
    }

    dynamicMerchantKey = activeKey;
    dynamicMerchantSalt =
        payuMap['salt']?.toString() ??
        payuMap['merchantSalt']?.toString() ??
        payuMap['merchant_salt']?.toString();
    apiHash =
        payuMap['hash']?.toString() ??
        payuMap['payment_hash']?.toString() ??
        apiData['hash']?.toString();

    currentTxnRef =
        apiData['transactionReference']?.toString() ??
        payuMap['txnid']?.toString() ??
        txnId;

    lastPayUMap = payuMap;
    apiHashesMap.clear();
    final hashesObj =
        payuMap['hashes'] ??
        payuMap['hashesMap'] ??
        apiData['hashes'] ??
        apiData['hashesMap'];
    if (hashesObj is Map) {
      hashesObj.forEach((k, v) {
        if (k != null && v != null) {
          apiHashesMap[k.toString()] = v.toString();
        }
      });
    }

    final String activeTxnId =
        payuMap['txnid']?.toString() ??
        payuMap['transactionId']?.toString() ??
        apiData['transactionReference']?.toString() ??
        txnId;
    final String activeAmount =
        payuMap['amount']?.toString() ?? amount.toStringAsFixed(2);
    final String activeProductInfo =
        payuMap['productinfo']?.toString() ??
        payuMap['productInfo']?.toString() ??
        "Wallet top-up";
    final String activeFirstName =
        payuMap['firstname']?.toString() ??
        payuMap['firstName']?.toString() ??
        (userName.isNotEmpty ? userName : "User");
    final String activeEmail =
        payuMap['email']?.toString() ??
        (userEmail.isNotEmpty ? userEmail : "user@transwallet.com");
    final String activePhone =
        payuMap['phone']?.toString() ??
        (userPhone.isNotEmpty ? userPhone : "9999999999");
    // Always use PayU SDK callback URLs so PayU SDK intercepts response immediately without showing web success screens
    final String activeSurl = "https://cbk.payu.in/sdk/success";
    final String activeFurl = "https://cbk.payu.in/sdk/failure";
    final String envStr =
        payuMap['environment']?.toString().toUpperCase() ?? "TEST";
    final String activeEnv = (envStr == 'TEST' || envStr == '1') ? "1" : "0";
    final String userCred =
        payuMap['userCredential']?.toString() ??
        payuMap['user_credential']?.toString() ??
        "$activeKey:$activePhone";

    Map<String, dynamic> payUPaymentParams = {
      PayUPaymentParamKey.key: activeKey,
      PayUPaymentParamKey.amount: activeAmount,
      PayUPaymentParamKey.productInfo: activeProductInfo,
      PayUPaymentParamKey.firstName: activeFirstName,
      PayUPaymentParamKey.email: activeEmail,
      PayUPaymentParamKey.phone: activePhone,
      PayUPaymentParamKey.transactionId: activeTxnId,
      "surl": activeSurl,
      "furl": activeFurl,
      PayUPaymentParamKey.android_surl: activeSurl,
      PayUPaymentParamKey.android_furl: activeFurl,
      PayUPaymentParamKey.ios_surl: activeSurl,
      PayUPaymentParamKey.ios_furl: activeFurl,
      PayUPaymentParamKey.environment: activeEnv,
      PayUPaymentParamKey.userCredential: userCred,
    };

    Map<String, dynamic> payUCheckoutProConfig = {
      PayUCheckoutProConfigKeys.primaryColor: "#ED292A",
      PayUCheckoutProConfigKeys.secondaryColor: "#FFFFFF",
      PayUCheckoutProConfigKeys.merchantName: "Transwallet",
      PayUCheckoutProConfigKeys.merchantResponseTimeout: 0,
      PayUCheckoutProConfigKeys.waitingTime: 0,
      PayUCheckoutProConfigKeys.autoSelectOtp: true,
      PayUCheckoutProConfigKeys.autoApprove: true,
      PayUCheckoutProConfigKeys.showExitConfirmationOnPaymentScreen: false,
      PayUCheckoutProConfigKeys.showExitConfirmationOnCheckoutScreen: false,
    };

    print('[PayU Request Body Params] $payUPaymentParams');
    debugPrint('[PayU Request Body Params] $payUPaymentParams');
    developer.log('[PayU Request Body Params] $payUPaymentParams');

    print('[PayU Request Config] $payUCheckoutProConfig');
    debugPrint('[PayU Request Config] $payUCheckoutProConfig');
    developer.log('[PayU Request Config] $payUCheckoutProConfig');

    try {
      _payUCheckoutProFlutter.openCheckoutScreen(
        payUPaymentParams: payUPaymentParams,
        payUCheckoutProConfig: payUCheckoutProConfig,
      );
    } catch (e) {
      isProcessing.value = false;
      debugPrint("[PayU SDK Error] $e");
      AppSnackbar.error("Could not open PayU Checkout: $e");
    }
  }

  bool isTesting = true;
  Future<void> payNow() async {
    checkBlockedStatus();
    if (isPermanentlyBlocked.value) {
      AppSnackbar.error(
        "Your card is permanently blocked. You cannot add money to this wallet.",
        title: "Card Blocked",
      );
      return;
    }

    if (amount <= 0) {
      AppSnackbar.error("Please enter a valid amount");
      return;
    }

    if (isLimitReached) {
      if (!isFullKyc.value) {
        showUpgradeKycDialog(attemptedAmount: amount);
      } else {
        AppSnackbar.error(
          "Your wallet has reached the maximum limit of ₹2,00,000.",
        );
      }
      return;
    }

    if (isAmountExceedingLimit) {
      final allowedStr = formatCurrency(maxAddableAmount);
      final balStr = formatCurrency(balance.value, showDecimals: true);
      if (!isFullKyc.value) {
        AppSnackbar.error(
          "Max wallet limit is ₹10,000 for Min KYC. With current balance of ₹$balStr, you can add up to ₹$allowedStr. Complete Full KYC for ₹2,00,000 limit.",
        );
        showUpgradeKycDialog(attemptedAmount: amount);
      } else {
        AppSnackbar.error(
          "Max wallet limit is ₹2,00,000 for Full KYC. With current balance of ₹$balStr, you can add up to ₹$allowedStr.",
        );
      }
      return;
    }

    await openPayUCheckout();
  }

  Widget circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon),
      ),
    );
  }
}

class PaymentReceiptView extends StatefulWidget {
  final double amount;
  final double balance;
  final String paymentMode;
  final String status;
  final String? txnId;
  final String? transactionReference;
  final String? bankRefNo;
  final String? message;

  const PaymentReceiptView({
    super.key,
    required this.amount,
    required this.balance,
    required this.paymentMode,
    this.status = 'Success',
    this.txnId,
    this.transactionReference,
    this.bankRefNo,
    this.message,
  });

  @override
  State<PaymentReceiptView> createState() => _PaymentReceiptViewState();
}

class _PaymentReceiptViewState extends State<PaymentReceiptView>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  Map<String, dynamic>? _loadDetails;
  bool _detailsExpanded = false;

  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _fetchLoadDetails();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchLoadDetails() async {
    final String ref =
        (widget.transactionReference != null &&
            widget.transactionReference!.isNotEmpty)
        ? widget.transactionReference!
        : (widget.txnId ?? '');
    if (ref.isEmpty) return;

    if (Get.isRegistered<ApiService>()) {
      setState(() {
        _isLoading = true;
      });
      final details = await ApiService.to.fetchWalletLoadDetails(ref);
      developer.log("nathu payment payment>> $details");
      if (mounted) {
        setState(() {
          _loadDetails = details;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? payuMap =
        (_loadDetails != null && _loadDetails!['payu'] is Map)
        ? Map<String, dynamic>.from(_loadDetails!['payu'] as Map)
        : null;

    final String activeTxnRef =
        _loadDetails?['transactionReference']?.toString() ??
        (widget.transactionReference != null &&
                widget.transactionReference!.isNotEmpty
            ? widget.transactionReference!
            : (widget.txnId != null && widget.txnId!.isNotEmpty
                  ? widget.txnId!
                  : ''));

    final String payuTxnId =
        payuMap?['txnid']?.toString() ??
        (widget.txnId != null && widget.txnId != activeTxnRef
            ? widget.txnId!
            : '');

    final String rawStatus =
        _loadDetails?['status']?.toString() ?? widget.status;
    final double displayAmount = (_loadDetails?['amount'] is num)
        ? (_loadDetails!['amount'] as num).toDouble()
        : widget.amount;
    final String currency = _loadDetails?['currency']?.toString() ?? 'INR';
    final String formattedAmountStr = currency == 'INR'
        ? "₹${displayAmount.toStringAsFixed(0)}"
        : "$currency ${displayAmount.toStringAsFixed(0)}";
    final String paymentModeStr =
        payuMap?['mode']?.toString() ?? widget.paymentMode;
    final String timestampRaw =
        _loadDetails?['timestamp']?.toString() ??
        _loadDetails?['createdAt']?.toString() ??
        '';
    final String formattedDate = timestampRaw.isNotEmpty
        ? (timestampRaw.contains('T')
              ? timestampRaw.replaceAll('T', ' ').substring(0, 16)
              : timestampRaw)
        : DateTime.now().toString().substring(0, 16);

    final bool isSuccess =
        rawStatus.toLowerCase() == 'success' ||
        rawStatus.toLowerCase() == 'completed' ||
        rawStatus.toLowerCase() == 'ok';
    final bool isPending =
        rawStatus.toLowerCase() == 'pending' ||
        rawStatus.toLowerCase() == 'initiated';
    final bool isFailed =
        rawStatus.toLowerCase() == 'failed' ||
        rawStatus.toLowerCase() == 'failure';

    final Color statusColor = isSuccess
        ? Colors.green
        : (isPending ? Colors.orange : Colors.red);
    final IconData statusIcon = isSuccess
        ? Icons.check
        : (isPending ? Icons.access_time_rounded : Icons.close_rounded);
    final String titleText = isSuccess
        ? "Payment Successful"
        : (isPending ? "Payment Pending" : "Payment Failed");
    final String displayStatusStr = isSuccess
        ? "Success"
        : (isPending ? "Pending" : "Failed");

    // Status-dependent subtitle
    final String subtitleText = isSuccess
        ? 'Your payment was completed successfully.'
        : (isPending
              ? 'Your payment is currently under process.\nPlease wait or try again later.'
              : 'Your payment could not be processed.\nPlease try again.');

    const Color orange = Color(0xFFFF7A00);
    final Color pillColor = isSuccess
        ? const Color(0xFF4CAF50)
        : (isPending ? orange : const Color(0xFFE53935));

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double screenW = constraints.maxWidth;
          final double blobSize = screenW * 0.55;
          return Stack(
            children: [
              SafeArea(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) => FadeTransition(
                    opacity: _animController,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animController,
                              curve: Curves.easeOut,
                            ),
                          ),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenW * 0.06,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        height30,
                        height30,
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFF7A00),
                              ),
                            ),
                          ),

                        // ── Status icon circle with gradient ──
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: const Alignment(-0.3, -0.4),
                              radius: 0.7,
                              colors: [
                                statusColor.withValues(alpha: 0.95),
                                statusColor,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.10),
                                blurRadius: 24,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            statusIcon,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        height14,

                        // ── Title ──
                        Text(
                          titleText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                            letterSpacing: -0.5,
                          ),
                        ),
                        height6,

                        // ── Subtitle ──
                        Text(
                          subtitleText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF888888),
                            height: 1.5,
                          ),
                        ),
                        height14,

                        // ── Amount card with gradient ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color.fromARGB(187, 253, 236, 217),
                                Color.fromARGB(154, 253, 253, 253),
                                Color.fromARGB(187, 253, 236, 217),
                              ],
                              stops: [0.0, 0.55, 1.0],
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Amount',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFFAA7755),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              height6,
                              Text(
                                formattedAmountStr,
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),

                        // ── Receipt Details accordion ──
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _detailsExpanded
                                  ? Colors.grey.shade200
                                  : Colors.grey.shade100,
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: _detailsExpanded ? 0.045 : 0.025,
                                ),
                                blurRadius: _detailsExpanded ? 12 : 8,
                                spreadRadius: 0,
                                offset: Offset(0, _detailsExpanded ? 3 : 2),
                              ),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              initiallyExpanded: _detailsExpanded,
                              onExpansionChanged: (v) =>
                                  setState(() => _detailsExpanded = v),
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              childrenPadding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                bottom: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              collapsedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEEDE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Color(0xFFFF7A00),
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                'Summary',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                              trailing: AnimatedRotation(
                                turns: _detailsExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF7A00,
                                    ).withValues(alpha: 0.10),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFFFF7A00),
                                    size: 18,
                                  ),
                                ),
                              ),
                              children: [
                                _divider(),
                                const SizedBox(height: 4),
                                _receiptRow(
                                  icon: Icons.account_balance_rounded,
                                  iconColor: const Color(0xFF2196F3),
                                  iconBg: const Color(0xFFE3F2FD),
                                  label: 'Transaction Ref',
                                  value: activeTxnRef.isNotEmpty
                                      ? activeTxnRef
                                      : 'N/A',
                                ),
                                _divider(),
                                _receiptRow(
                                  icon: Icons.credit_card_rounded,
                                  iconColor: const Color(0xFF7B61FF),
                                  iconBg: const Color(0xFFEDE7FF),
                                  label: 'PayU Txn ID',
                                  value: payuTxnId.isNotEmpty
                                      ? payuTxnId
                                      : 'N/A',
                                ),
                                _divider(),
                                _receiptRow(
                                  icon: Icons.calendar_month_rounded,
                                  iconColor: const Color(0xFF43A047),
                                  iconBg: const Color(0xFFE8F5E9),
                                  label: 'Date',
                                  value: formattedDate,
                                ),
                                _divider(),
                                _receiptRow(
                                  icon: Icons.payment_rounded,
                                  iconColor: const Color(0xFFFF7A00),
                                  iconBg: const Color(0xFFFFEEDE),
                                  label: 'Payment Mode',
                                  value: paymentModeStr.isNotEmpty
                                      ? paymentModeStr
                                      : 'Online',
                                ),
                                _divider(),
                                _receiptRowStatus(
                                  label: 'Status',
                                  value: displayStatusStr,
                                  pillColor: pillColor,
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ── Continue button ──
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () => Get.offAllNamed('/dashboard'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF111111),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            child: Text(
                              'Go to Dashboard',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Helper: detail row with icon ──
  Widget _receiptRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF888888),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: status row with pill badge ──
  Widget _receiptRowStatus({
    required String label,
    required String value,
    required Color pillColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF6B6B9A),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: pillColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: pillColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF0F0F0));
}

class MpinVerifySheetForPayment extends StatefulWidget {
  final VoidCallback onSuccess;
  final String title;
  final String subtitle;

  const MpinVerifySheetForPayment({
    super.key,
    required this.onSuccess,
    required this.title,
    required this.subtitle,
  });

  @override
  State<MpinVerifySheetForPayment> createState() =>
      _MpinVerifySheetForPaymentState();
}

class _MpinVerifySheetForPaymentState extends State<MpinVerifySheetForPayment> {
  String _mpin = "";
  bool _isVerifying = false;
  bool _hasError = false;

  void _keypadPress(String value) {
    if (_isVerifying) return;

    setState(() {
      if (_hasError) {
        _hasError = false;
        _mpin = "";
      }
      if (_mpin.length < 4) {
        _mpin += value;
      }
    });

    if (_mpin.length == 4) {
      _verifyMpin();
    }
  }

  void _deletePress() {
    if (_isVerifying) {
      _isVerifying = false;
    }
    setState(() {
      _hasError = false;
      if (_mpin.isNotEmpty) {
        _mpin = _mpin.substring(0, _mpin.length - 1);
      }
    });
  }

  void _clearPress() {
    if (_isVerifying) {
      _isVerifying = false;
    }
    setState(() {
      _hasError = false;
      _mpin = "";
    });
  }

  Future<void> _verifyMpin() async {
    final pinToVerify = _mpin;
    setState(() {
      _isVerifying = true;
      _hasError = false;
    });

    MpinVerifyResponse res;
    if (Get.isRegistered<ApiService>()) {
      res = await ApiService.to.verifyMpin(pinToVerify);
    } else {
      final box = GetStorage();
      final savedMpin =
          box.read<String>('saved_mpin') ?? box.read('mpin')?.toString();
      final ok = savedMpin != null && savedMpin == pinToVerify;
      res = MpinVerifyResponse(
        isSuccess: ok,
        message: ok ? 'MPIN verified' : 'Incorrect MPIN. Please try again.',
      );
    }

    if (mounted) {
      if (res.isSuccess) {
        if (Get.isRegistered<AppLockService>()) {
          AppLockService.to.clearMpinLockout();
        }
        HapticFeedback.mediumImpact();
        Get.back();
        widget.onSuccess();
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _mpin = pinToVerify;
          _isVerifying = false;
          _hasError = true;
        });
        if (res.message.isNotEmpty) {
          AppSnackbar.error(res.message);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFED292A);
    const Color textColor = Color(0xFF111111);
    const Color secondaryText = Color(0xFF6B7280);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFECECEC),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryRed.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xFF111111),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: const TextStyle(color: secondaryText, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final bool isFilled = index < _mpin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isVerifying
                        ? primaryRed.withOpacity(0.3)
                        : (isFilled
                            ? (_hasError ? Colors.red : primaryRed)
                            : const Color(0xFFECECEC)),
                    border: Border.all(
                      color: _hasError && isFilled
                          ? Colors.red
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            if (_isVerifying) ...[
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_hasError) ...[
              const Text(
                "Invalid MPIN. Try again.",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const SizedBox(height: 36),
            ],
            CustomNumericKeypad(
              onDigitTap: _keypadPress,
              onDeleteTap: _deletePress,
              onClear: _clearPress,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
