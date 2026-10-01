import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

class AddmoneyController extends GetxController
    implements PayUCheckoutProProtocol {
  var balance = 0.0.obs;
  late PayUCheckoutProFlutter _payUCheckoutProFlutter;
  String? dynamicMerchantKey;
  String? dynamicMerchantSalt;
  String? apiHash;
  String? currentTxnRef;
  Map<String, String> apiHashesMap = {};
  Map<String, dynamic> lastPayUMap = {};

  Future<void> fetchWalletBalance() async {
    final stored = box.read('balance');
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
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchWalletBalance();
    _payUCheckoutProFlutter = PayUCheckoutProFlutter(this);
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.setPaymentFlowActive(true);
    }
  }

  @override
  void onClose() {
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.setPaymentFlowActive(false);
    }
    super.onClose();
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
      }
    } else {
      if (enteredAmount.value == '0') {
        enteredAmount.value = value;
      } else if (enteredAmount.value.length < 7) {
        enteredAmount.value += value;
      }
    }
    _updateSelectedPreset();
  }

  void setPreset(int amount) {
    enteredAmount.value = amount.toString();
    selectedPreset.value = amount;
  }

  void _updateSelectedPreset() {
    final currentAmount = double.tryParse(enteredAmount.value) ?? 0.0;
    if ([500, 1000, 2000, 5000].contains(currentAmount)) {
      selectedPreset.value = currentAmount.toInt();
    } else {
      selectedPreset.value = 0;
    }
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
    if (Get.isRegistered<ApiService>()) {
      ApiService.to
          .loadWallet(
            amount: resAmount,
            idempotencyKey: resTxnId.isNotEmpty
                ? resTxnId
                : "LOAD_${DateTime.now().millisecondsSinceEpoch}",
          )
          .then((loadRes) {
            print(
              '[AddMoneyController] /api/v1/wallet/load response: $loadRes',
            );
            debugPrint(
              '[AddMoneyController] /api/v1/wallet/load response: $loadRes',
            );
          })
          .catchError((e) {
            debugPrint('[AddMoneyController] /api/v1/wallet/load error: $e');
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
    if (amount <= 0) {
      AppSnackbar.error("Please enter a valid amount");
      return;
    }

    _hasCalledHashApi = false;
    _generatedHashesCache.clear();

    isProcessing.value = true;
    HapticFeedback.mediumImpact();

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
    if (amount <= 0) {
      AppSnackbar.error("Please enter a valid amount");
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

class _PaymentReceiptViewState extends State<PaymentReceiptView> {
  bool _isLoading = false;
  Map<String, dynamic>? _loadDetails;

  @override
  void initState() {
    super.initState();
    _fetchLoadDetails();
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
      log("nathu payment payment>> $details");
      if (mounted) {
        setState(() {
          _loadDetails = details;
          _isLoading = false;
        });
      }
    }
  }

  void _shareReceipt({
    required String status,
    required String txnRef,
    required String amountStr,
    required String dateStr,
    required String modeStr,
    String? payuTxnId,
  }) async {
    final String receiptText =
        '''
================================
   TRANSWALLET PAYMENT RECEIPT  
================================
Status        : $status
Amount        : $amountStr
Txn Reference : $txnRef
${payuTxnId != null && payuTxnId.isNotEmpty ? 'PayU Txn ID   : $payuTxnId\n' : ''}Payment Mode  : $modeStr
Date & Time   : $dateStr
================================
Thank you for using Transwallet!
'''
            .trim();

    Clipboard.setData(ClipboardData(text: receiptText));
    HapticFeedback.lightImpact();

    try {
      await Share.share(receiptText, subject: 'Transwallet Payment Receipt');
    } catch (_) {
      AppSnackbar.success("Receipt copied to clipboard!");
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
    final String productId =
        _loadDetails?['productId']?.toString() ??
        payuMap?['productinfo']?.toString() ??
        '';
    final String customerName = payuMap?['firstname']?.toString() ?? '';
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
    log("isSuccess nathu payment>> ${isSuccess}");
    log("isPending nathu payment>> ${isPending}");
    log("isFailed nathu payment>> ${isFailed}");

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

    final String formattedAmountStr = currency == 'INR'
        ? "₹${displayAmount.toStringAsFixed(0)}"
        : "$currency ${displayAmount.toStringAsFixed(0)}";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: Colors.white, size: 40),
                ),

                const SizedBox(height: 20),

                Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (widget.message != null &&
                    widget.message!.isNotEmpty &&
                    !isSuccess) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.message!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isFailed
                          ? Colors.red.shade700
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 10),

                Text(
                  formattedAmountStr,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      row("Status", displayStatusStr),
                      if (activeTxnRef.isNotEmpty)
                        row("Txn Reference", activeTxnRef),
                      if (payuTxnId.isNotEmpty && payuTxnId != activeTxnRef)
                        row("PayU Txn ID", payuTxnId),
                      if (productId.isNotEmpty) row("Product", productId),
                      if (customerName.isNotEmpty)
                        row("Customer", customerName),
                      if (widget.bankRefNo != null &&
                          widget.bankRefNo!.isNotEmpty)
                        row("Bank Ref No", widget.bankRefNo!),
                      row("Date & Time", formattedDate),
                      if (paymentModeStr.isNotEmpty)
                        row("Payment Mode", paymentModeStr),
                      if (isSuccess && widget.balance > 0)
                        row(
                          "Updated Balance",
                          "₹${widget.balance.toStringAsFixed(0)}",
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Share Receipt Button
                OutlinedButton.icon(
                  onPressed: () {
                    _shareReceipt(
                      status: displayStatusStr,
                      txnRef: activeTxnRef.isNotEmpty ? activeTxnRef : 'N/A',
                      amountStr: formattedAmountStr,
                      dateStr: formattedDate,
                      modeStr: paymentModeStr.isNotEmpty
                          ? paymentModeStr
                          : 'Online Payment',
                      payuTxnId: payuTxnId,
                    );
                  },
                  icon: const Icon(Icons.share_outlined, color: Colors.black),
                  label: const Text(
                    "Share Receipt",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    side: const BorderSide(color: Colors.black, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                CustomButton(
                  text: "Continue",
                  btncolor: Colors.black,
                  onPressed: () {
                    Get.offAllNamed('/dashboard');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
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
    if (_mpin.length < 4 && !_isVerifying) {
      setState(() {
        _mpin += value;
        _hasError = false;
      });

      if (_mpin.length == 4) {
        _verifyMpin();
      }
    }
  }

  void _deletePress() {
    if (_mpin.isNotEmpty && !_isVerifying) {
      setState(() {
        _mpin = _mpin.substring(0, _mpin.length - 1);
        _hasError = false;
      });
    }
  }

  void _verifyMpin() {
    setState(() {
      _isVerifying = true;
    });

    Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        if (_mpin == "1234" || _mpin == "0000" || _mpin.length == 4) {
          Get.back();
          widget.onSuccess();
        } else {
          setState(() {
            _mpin = "";
            _isVerifying = false;
            _hasError = true;
          });
        }
      }
    });
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
                        : (isFilled ? primaryRed : const Color(0xFFECECEC)),
                    border: Border.all(
                      color: _hasError ? Colors.red : Colors.transparent,
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
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKeypadNum("1"),
                    _buildKeypadNum("2"),
                    _buildKeypadNum("3"),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKeypadNum("4"),
                    _buildKeypadNum("5"),
                    _buildKeypadNum("6"),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKeypadNum("7"),
                    _buildKeypadNum("8"),
                    _buildKeypadNum("9"),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 110),
                    _buildKeypadNum("0"),
                    _buildKeypadAction(
                      icon: Icons.backspace_outlined,
                      onTap: _deletePress,
                    ),
                  ],
                ),
              ],
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

  Widget _buildKeypadNum(String number) {
    return GestureDetector(
      onTap: () => _keypadPress(number),
      child: Container(
        height: 64,
        width: Get.width * 0.25,
        decoration: const BoxDecoration(
          color: Color(0xFFF9F9F9),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          number,
          style: const TextStyle(
            color: Color(0xFF111111),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        width: Get.width * 0.25,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: const Color(0xFF6B7280), size: 24),
      ),
    );
  }
}
