import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/modules/vkyc/controllers/vkyc_controller.dart';
import 'package:transwallet/modules/vkyc/services/vkyc_test_service.dart';
import 'package:transwallet/products/Dashboard screen/widgets/card_popups.dart';
import 'package:transwallet/products/Manage Card/managecard_Controller.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/products/Wallet Screen/Add Money/addmoney_Controller.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

class DeepLinkService extends GetxService {
  static DeepLinkService get to => Get.find<DeepLinkService>();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  Future<DeepLinkService> init() async {
    _appLinks = AppLinks();
    _initDeepLinkListener();
    return this;
  }

  void _initDeepLinkListener() async {
    try {
      // 1. Listen for incoming deep links first (foreground / background)
      _sub = _appLinks.uriLinkStream.listen(
        (uri) {
          debugPrint("🔗 [DeepLinkService] Received stream link: $uri");
          _handleDeepLinkUri(uri);
        },
        onError: (err) {
          debugPrint("⚠️ [DeepLinkService] Link error: $err");
        },
      );

      // 2. Check initial URI if app launched cold via deep link
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint("🔗 [DeepLinkService] Received initial link: $initialUri");
        _handleDeepLinkUri(initialUri);
      }
    } catch (e) {
      debugPrint("⚠️ [DeepLinkService] Initialization error: $e");
    }
  }

  void handleDeepLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      _handleDeepLinkUri(uri);
    }
  }

  void _handleDeepLinkUri(Uri uri) async {
    final urlString = uri.toString().toLowerCase();
    debugPrint("🔗 [DeepLinkService] Deep link detected: $urlString");

    if (urlString.startsWith("transwallet://vkyc")) {
      _handleVkycDeepLink(uri);
      return;
    }

    if (urlString.startsWith("transwallet://reset-pin") ||
        urlString.startsWith("transwallet://card-pin") ||
        urlString.startsWith("transwallet://set-pin") ||
        urlString.startsWith("transwallet://card/pin") ||
        urlString.startsWith("ppiapp://card-widget") ||
        urlString.startsWith("yappay://")) {
      _handleResetPinDeepLink(uri);
      return;
    }

    if (urlString.startsWith("transwallet://card-details") ||
        urlString.startsWith("transwallet://card")) {
      _handleCardDetailsDeepLink(uri);
      return;
    }

    if (urlString.startsWith("transwallet://addmoney") ||
        urlString.startsWith("transwallet://add-money") ||
        urlString.startsWith("transwallet://wallet") ||
        urlString.startsWith("transwallet://payment") ||
        urlString.startsWith("transwallet://payu") ||
        urlString.startsWith("transwallet://upi") ||
        urlString.startsWith("ppiapp://payment") ||
        urlString.startsWith("ppiapp://addmoney") ||
        urlString.startsWith("yappay://payment") ||
        urlString.contains("addmoney") ||
        urlString.contains("add-money") ||
        urlString.contains("payment_receipt") ||
        urlString.contains("payment-receipt") ||
        ((urlString.startsWith("transwallet://") ||
                urlString.startsWith("ppiapp://") ||
                urlString.startsWith("yappay://")) &&
            (uri.queryParameters.containsKey("status") ||
                uri.queryParameters.containsKey("txnstatus") ||
                uri.queryParameters.containsKey("txnid") ||
                uri.queryParameters.containsKey("transactionid") ||
                uri.queryParameters.containsKey("responsecode")))) {
      _handleAddMoneyDeepLink(uri);
      return;
    }
  }

  void _handleAddMoneyDeepLink(Uri uri) async {
    final urlString = uri.toString().toLowerCase();
    debugPrint(
      "💰 [DeepLinkService] Add Money / Payment deep link detected: $urlString",
    );

    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.startExternalFlow(ExternalFlowType.payment);
    }

    try {
      final queryParams = uri.queryParameters;
      final bool isCallback =
          urlString.contains("/success") ||
          urlString.contains("/approved") ||
          urlString.contains("/done") ||
          urlString.contains("/completed") ||
          urlString.contains("/fail") ||
          urlString.contains("/failed") ||
          urlString.contains("/error") ||
          urlString.contains("/rejected") ||
          urlString.contains("/cancel") ||
          urlString.contains("/cancelled") ||
          urlString.contains("/close") ||
          urlString.contains("/return") ||
          urlString.contains("payment_receipt") ||
          urlString.contains("payment-receipt") ||
          queryParams.containsKey("status") ||
          queryParams.containsKey("txnstatus") ||
          queryParams.containsKey("result") ||
          queryParams.containsKey("responsecode") ||
          queryParams.containsKey("event") ||
          queryParams.containsKey("action") ||
          queryParams.containsKey("txnid") ||
          queryParams.containsKey("transactionid") ||
          queryParams.containsKey("bank_ref_no") ||
          queryParams.containsKey("approvalrefno");

      if (!isCallback) {
        debugPrint(
          "💰 [DeepLinkService] Navigating to Add Money screen from deep link",
        );
        final token = GetStorage().read('token');
        if (token == null || token.toString().isEmpty) {
          Get.toNamed('/login');
          return;
        }

        final amountStr =
            queryParams['amount'] ?? queryParams['amt'] ?? queryParams['value'];

        if (Get.currentRoute == '/addmoney') {
          if (amountStr != null &&
              amountStr.isNotEmpty &&
              Get.isRegistered<AddmoneyController>()) {
            Get.find<AddmoneyController>().setExactAmount(amountStr);
          }
        } else {
          Get.toNamed('/addmoney');
          if (amountStr != null && amountStr.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (Get.isRegistered<AddmoneyController>()) {
                Get.find<AddmoneyController>().setExactAmount(amountStr);
              }
            });
          }
        }
        return;
      }

      // Close open dialog or bottom sheet if active
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      if (Get.isBottomSheetOpen ?? false) {
        Get.back();
      }

      final status = (queryParams['status'] ??
              queryParams['txnstatus'] ??
              queryParams['result'] ??
              queryParams['event'] ??
              queryParams['action'] ??
              queryParams['code'] ??
              '')
          .toLowerCase();
      final responseCode =
          queryParams['responsecode'] ?? queryParams['response_code'] ?? '';

      final txnId = queryParams['txnid'] ??
          queryParams['transactionid'] ??
          queryParams['transaction_id'] ??
          queryParams['transactionreference'] ??
          queryParams['referenceid'] ??
          queryParams['refno'] ??
          '';

      final bankRefNo = queryParams['bank_ref_no'] ??
          queryParams['bankrefno'] ??
          queryParams['approvalrefno'] ??
          queryParams['rrn'] ??
          queryParams['field1'] ??
          '';

      final mode = queryParams['mode'] ??
          queryParams['paymentmode'] ??
          queryParams['pg_type'] ??
          'UPI / PayU';

      final message = queryParams['message'] ??
          queryParams['msg'] ??
          queryParams['error_message'] ??
          queryParams['errormessage'] ??
          queryParams['desc'] ??
          queryParams['description'];

      final double amountVal = double.tryParse(
            queryParams['amount'] ?? queryParams['amt'] ?? '',
          ) ??
          0.0;

      final bool isSuccess =
          urlString.contains("/success") ||
          urlString.contains("/approved") ||
          urlString.contains("/done") ||
          urlString.contains("/completed") ||
          status == "success" ||
          status == "approved" ||
          status == "completed" ||
          status == "200" ||
          status == "00" ||
          status == "0" ||
          responseCode == "00" ||
          responseCode == "0" ||
          responseCode == "200";

      final bool isCancel =
          urlString.contains("/cancel") ||
          urlString.contains("/close") ||
          status == "cancel" ||
          status == "close" ||
          status == "cancelled" ||
          status == "user_cancelled";

      final bool isFailed =
          urlString.contains("/fail") ||
          urlString.contains("/error") ||
          urlString.contains("/rejected") ||
          status == "failed" ||
          status == "fail" ||
          status == "error" ||
          status == "rejected";

      if (Get.isRegistered<AddmoneyController>()) {
        final controller = Get.find<AddmoneyController>();
        final effectiveTxnId = txnId.isNotEmpty
            ? txnId
            : (controller.currentTxnRef ??
                "TXN${DateTime.now().millisecondsSinceEpoch}");
        final effectiveAmount = amountVal > 0 ? amountVal : controller.amount;

        if (isSuccess) {
          controller.onPaymentSuccess({
            'status': 'success',
            'txnid': effectiveTxnId,
            'transaction_id': effectiveTxnId,
            'amount': effectiveAmount,
            'bank_ref_no': bankRefNo,
            'mode': mode,
            'field9': message ?? 'Transaction Successful',
            'Error_Message': message ?? 'Transaction Successful',
          });
        } else if (isCancel) {
          controller.onPaymentCancel({
            'message': message ?? 'Payment was cancelled',
          });
        } else if (isFailed) {
          controller.onPaymentFailure({
            'status': 'failed',
            'txnid': effectiveTxnId,
            'transaction_id': effectiveTxnId,
            'amount': effectiveAmount,
            'bank_ref_no': bankRefNo,
            'mode': mode,
            'Error_Message': message ?? 'Payment Failed',
          });
        } else {
          // Default: if no failure or cancel detected, treat return callback as success
          controller.onPaymentSuccess({
            'status': 'success',
            'txnid': effectiveTxnId,
            'transaction_id': effectiveTxnId,
            'amount': effectiveAmount,
            'bank_ref_no': bankRefNo,
            'mode': mode,
            'field9': message ?? 'Transaction Successful',
            'Error_Message': message ?? 'Transaction Successful',
          });
        }
        return;
      }

      // Fallback when AddmoneyController is not in memory
      final box = GetStorage();
      final double currentBal = (box.read('balance') is num)
          ? (box.read('balance') as num).toDouble()
          : 0.0;
      final effectiveTxnId = txnId.isNotEmpty
          ? txnId
          : "TXN${DateTime.now().millisecondsSinceEpoch}";

      if (isSuccess) {
        if (effectiveTxnId.isNotEmpty && Get.isRegistered<ApiService>()) {
          ApiService.to
              .verifyWalletLoad(
                effectiveTxnId,
                verificationPayload: {
                  'txnid': effectiveTxnId,
                  'amount': amountVal,
                  'status': 'success',
                  'bank_ref_no': bankRefNo,
                },
              )
              .then((_) {
                ApiService.to.fetchWalletBalance();
              })
              .catchError((_) {
                ApiService.to.fetchWalletBalance();
              });
        }

        final newBal = currentBal + amountVal;
        box.write('balance', newBal);

        AppSnackbar.success(message ?? "Money added to wallet successfully!");
        Get.offAllNamed(
          '/payment_receipt',
          arguments: {
            'amount': amountVal,
            'balance': newBal,
            'paymentMode': mode,
            'status': 'Success',
            'txnId': effectiveTxnId,
            'transactionReference': effectiveTxnId,
            'bankRefNo': bankRefNo,
            'message': message ?? 'Transaction Successful',
          },
        );
      } else if (isCancel) {
        AppSnackbar.warning(
          message ?? "Payment process was cancelled.",
          title: "Cancelled",
        );
        if (Get.currentRoute != '/dashboard') {
          Get.offAllNamed('/dashboard');
        }
      } else {
        AppSnackbar.error(
          message ?? "Payment failed. Please try again.",
          title: "Payment Failed",
        );
        Get.offAllNamed(
          '/payment_receipt',
          arguments: {
            'amount': amountVal,
            'balance': currentBal,
            'paymentMode': mode,
            'status': 'Failed',
            'txnId': effectiveTxnId,
            'transactionReference': effectiveTxnId,
            'bankRefNo': bankRefNo,
            'message': message ?? 'Payment Failed',
          },
        );
      }
    } finally {
      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.finishExternalFlow(ExternalFlowType.payment);
      }
    }
  }

  void _handleCardDetailsDeepLink(Uri uri) async {
    final urlString = uri.toString().toLowerCase();
    debugPrint(
      "💳 [DeepLinkService] Card Details deep link detected: $urlString",
    );

    final bool isCallback =
        urlString.contains("/return") ||
        urlString.contains("/close") ||
        urlString.contains("/cancel") ||
        urlString.contains("/fail") ||
        urlString.contains("/error") ||
        urlString.contains("/success") ||
        uri.queryParameters.containsKey("status") ||
        uri.queryParameters.containsKey("result") ||
        uri.queryParameters.containsKey("event");

    if (!isCallback) {
      debugPrint("💳 [DeepLinkService] Opening Card Details from deep link");
      final token = GetStorage().read('token');
      if (token != null && token.toString().isNotEmpty) {
        final storedCards = GetStorage().read('user_cards');
        Map<String, dynamic> cardData = <String, dynamic>{};
        if (storedCards is List &&
            storedCards.isNotEmpty &&
            storedCards.first is Map) {
          cardData = Map<String, dynamic>.from(storedCards.first as Map);
        }
        Get.dialog(CardDetailsPopup(card: cardData), barrierDismissible: true);
      }
      return;
    }

    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.startExternalFlow(ExternalFlowType.customWebview);
    }

    try {
      // Close open card dialog or modal sheet if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      if (Get.isBottomSheetOpen ?? false) {
        Get.back();
      }
      if (Get.key.currentState != null && Get.key.currentState!.canPop()) {
        Get.key.currentState!.pop();
      }

      final queryParams = uri.queryParameters;
      final status =
          queryParams['status']?.toLowerCase() ??
          queryParams['result']?.toLowerCase() ??
          queryParams['event']?.toLowerCase() ??
          queryParams['action']?.toLowerCase() ??
          queryParams['code']?.toLowerCase();
      final message =
          queryParams['message'] ??
          queryParams['msg'] ??
          queryParams['desc'] ??
          queryParams['description'];

      final bool isCloseOrCancel =
          urlString.contains("/close") ||
          urlString.contains("/cancel") ||
          status == "close" ||
          status == "cancel" ||
          status == "cancelled";

      final bool isFailed =
          urlString.contains("/fail") ||
          urlString.contains("/error") ||
          status == "failed" ||
          status == "fail" ||
          status == "error";

      if (isFailed) {
        AppSnackbar.error(
          message ?? "Failed to load card details. Please try again.",
        );
      } else if (!isCloseOrCancel) {
        AppSnackbar.success(message ?? "Card details verified successfully.");
      }
    } finally {
      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.finishExternalFlow(ExternalFlowType.customWebview);
      }
    }
  }

  void _handleResetPinDeepLink(Uri uri) async {
    final urlString = uri.toString().toLowerCase();
    debugPrint(
      "🔐 [DeepLinkService] Card PIN Reset deep link detected: $urlString",
    );

    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.startExternalFlow(ExternalFlowType.customWebview);
    }

    try {
      // 1. Close Reset PIN modal or sheet if open
      ResetPinWebViewSheet.close();
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      if (Get.isBottomSheetOpen ?? false) {
        Get.back();
      }
      if (Get.currentRoute == '/reset-pin-webview') {
        Get.back();
      } else if (Get.currentRoute != '/managecard' &&
          (Get.key.currentState != null && Get.key.currentState!.canPop())) {
        Get.key.currentState!.pop();
      }

      // 2. Redirect to Manage Card screen if not already on /managecard
      if (Get.currentRoute != '/managecard' &&
          Get.currentRoute != '/reset-pin-webview') {
        final storedCards = GetStorage().read('user_cards');
        Map<String, dynamic> cardData = <String, dynamic>{};
        if (storedCards is List &&
            storedCards.isNotEmpty &&
            storedCards.first is Map) {
          cardData = Map<String, dynamic>.from(storedCards.first as Map);
        }
        Get.toNamed('/managecard', arguments: cardData);
      }

      final queryParams = uri.queryParameters;
      final status =
          queryParams['status']?.toLowerCase() ??
          queryParams['result']?.toLowerCase() ??
          queryParams['event']?.toLowerCase() ??
          queryParams['action']?.toLowerCase() ??
          queryParams['code']?.toLowerCase();
      final message =
          queryParams['message'] ??
          queryParams['msg'] ??
          queryParams['desc'] ??
          queryParams['description'];

      final bool isSuccess =
          urlString.contains("/success") ||
          urlString.contains("/approved") ||
          urlString.contains("/done") ||
          urlString.contains("/completed") ||
          status == "success" ||
          status == "approved" ||
          status == "completed" ||
          status == "200" ||
          status == "00";

      final bool isCancel =
          urlString.contains("/cancel") ||
          urlString.contains("/close") ||
          status == "cancel" ||
          status == "close" ||
          status == "cancelled";

      final bool isFailed =
          urlString.contains("/fail") ||
          urlString.contains("/error") ||
          urlString.contains("/rejected") ||
          status == "failed" ||
          status == "fail" ||
          status == "error" ||
          status == "rejected";

      if (isSuccess) {
        AppSnackbar.success(
          message ?? "Card PIN has been updated successfully!",
        );
        if (Get.isRegistered<ManagecardController>()) {
          Get.find<ManagecardController>().fetchCardDetails();
          Get.find<ManagecardController>().fetchCardPreferences();
        }
      } else if (isCancel) {
        AppSnackbar.info(message ?? "Card PIN reset was cancelled.");
      } else if (isFailed) {
        AppSnackbar.error(
          message ?? "Failed to reset Card PIN. Please try again.",
        );
      } else {
        // Fallback default for return callbacks
        AppSnackbar.success(
          message ?? "Card PIN reset action processed successfully!",
        );
        if (Get.isRegistered<ManagecardController>()) {
          Get.find<ManagecardController>().fetchCardDetails();
          Get.find<ManagecardController>().fetchCardPreferences();
        }
      }
    } finally {
      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.finishExternalFlow(ExternalFlowType.customWebview);
      }
    }
  }

  void _handleVkycDeepLink(Uri uri) async {
    final urlString = uri.toString().toLowerCase();

    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.startExternalFlow(ExternalFlowType.vkyc);
    }

    try {
      if (Get.currentRoute == '/vkyc_webview') {
        Get.back();
      }

      // 1. Success / Approved
      if (urlString.startsWith("transwallet://vkyc/success") ||
          urlString.startsWith("transwallet://vkyc/approved") ||
          urlString.contains("status=success") ||
          urlString.contains("status=approved") ||
          urlString.contains("status=completed")) {
        if (Get.isRegistered<VkycController>()) {
          await Get.find<VkycController>().onVkycSuccessDetected();
        } else {
          final vkycService = Get.isRegistered<VkycTestService>()
              ? VkycTestService.to
              : Get.put(VkycTestService());
          await vkycService.handleVkycSuccess();
          GetStorage().write('pending_vkyc_success_dialog', true);
          if (Get.isRegistered<ApiService>()) {
            await ApiService.to.fetchUserProfile(force: true);
          }
          if (Get.isRegistered<AppLockService>()) {
            AppLockService.to.finishExternalFlow(ExternalFlowType.vkyc);
          }
          Get.offAllNamed('/dashboard', arguments: {'showVkycSuccess': true});
        }
      }
      // 2. Under Review / In Progress / Pending
      else if (urlString.startsWith("transwallet://vkyc/under_review") ||
          urlString.startsWith("transwallet://vkyc/pending") ||
          urlString.startsWith("transwallet://vkyc/in_progress") ||
          urlString.startsWith("transwallet://vkyc/review") ||
          urlString.contains("status=under_review") ||
          urlString.contains("status=pending") ||
          urlString.contains("status=in_progress") ||
          urlString.contains("status=review")) {
        if (Get.isRegistered<VkycController>()) {
          await Get.find<VkycController>().onVkycReviewInProgressDetected();
        } else {
          final vkycService = Get.isRegistered<VkycTestService>()
              ? VkycTestService.to
              : Get.put(VkycTestService());
          await vkycService.handleVkycUnderReview();
          Get.offAllNamed('/dashboard');
        }
      }
      // 3. Failed / Rejected
      else if (urlString.startsWith("transwallet://vkyc/failed") ||
          urlString.startsWith("transwallet://vkyc/rejected") ||
          urlString.contains("status=failed") ||
          urlString.contains("status=rejected")) {
        if (Get.isRegistered<VkycController>()) {
          Get.find<VkycController>().onVkycRejectedDetected();
        } else {
          final vkycService = Get.isRegistered<VkycTestService>()
              ? VkycTestService.to
              : Get.put(VkycTestService());
          vkycService.handleVkycRejected();
        }
      }
      // 4. Cancel / Cancelled
      else if (urlString.startsWith("transwallet://vkyc/cancel") ||
          urlString.startsWith("transwallet://vkyc/cancelled") ||
          urlString.contains("status=cancel")) {
        if (Get.isRegistered<VkycController>()) {
          Get.find<VkycController>().onVkycCancelDetected();
        } else {
          final vkycService = Get.isRegistered<VkycTestService>()
              ? VkycTestService.to
              : Get.put(VkycTestService());
          vkycService.handleVkycCancel();
        }
      }
    } finally {
      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.finishExternalFlow(ExternalFlowType.vkyc);
      }
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
