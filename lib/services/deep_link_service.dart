import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/modules/vkyc/controllers/vkyc_controller.dart';
import 'package:transwallet/modules/vkyc/services/vkyc_test_service.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';

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

  void _handleDeepLinkUri(Uri uri) async {
    final urlString = uri.toString().toLowerCase();
    debugPrint("🔗 [DeepLinkService] Deep link detected: $urlString");

    if (!urlString.startsWith("transwallet://vkyc")) return;

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
