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
      // Check initial URI if app launched via deep link
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLinkUri(initialUri);
      }

      // Listen for incoming deep links while app is running
      _sub = _appLinks.uriLinkStream.listen(
        (uri) {
          _handleDeepLinkUri(uri);
        },
        onError: (err) {
          debugPrint("⚠️ [DeepLinkService] Link error: $err");
        },
      );
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
        urlString.startsWith("yappay://") ||
        urlString.contains("transcorpint.com/ppi-card") ||
        urlString.contains("transcorpint.com") ||
        urlString.contains("ppi-card")) {
      _handleResetPinDeepLink(uri);
      return;
    }

    if (urlString.startsWith("transwallet://card-details") ||
        urlString.startsWith("transwallet://card")) {
      _handleCardDetailsDeepLink(uri);
      return;
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
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      if (Get.isBottomSheetOpen ?? false) {
        Get.back();
      }
      if (Get.currentRoute != '/managecard' &&
          (Get.key.currentState != null && Get.key.currentState!.canPop())) {
        Get.key.currentState!.pop();
      }

      // 2. Redirect to Manage Card screen if not already on /managecard
      if (Get.currentRoute != '/managecard') {
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
          urlString.contains("transcorpint.com") ||
          urlString.contains("ppi-card") ||
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
