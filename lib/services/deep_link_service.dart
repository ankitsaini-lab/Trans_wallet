import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:transwallet/modules/vkyc/controllers/vkyc_controller.dart';
import 'package:transwallet/modules/vkyc/services/vkyc_test_service.dart';

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
      _sub = _appLinks.uriLinkStream.listen((uri) {
        _handleDeepLinkUri(uri);
      }, onError: (err) {
        debugPrint("⚠️ [DeepLinkService] Link error: $err");
      });
    } catch (e) {
      debugPrint("⚠️ [DeepLinkService] Initialization error: $e");
    }
  }

  void _handleDeepLinkUri(Uri uri) async {
    final urlString = uri.toString();
    debugPrint("🔗 [DeepLinkService] Deep link detected: $urlString");

    if (urlString.startsWith("transwallet://vkyc/success")) {
      if (Get.currentRoute == '/vkyc_webview') {
        Get.back();
      }

      if (Get.isRegistered<VkycController>()) {
        await Get.find<VkycController>().onVkycSuccessDetected();
      } else {
        final vkycService = Get.isRegistered<VkycTestService>()
            ? VkycTestService.to
            : Get.put(VkycTestService());
        await vkycService.handleVkycSuccess();
        Get.offAllNamed('/dashboard');
      }
    } else if (urlString.startsWith("transwallet://vkyc/cancel")) {
      if (Get.currentRoute == '/vkyc_webview') {
        Get.back();
      }

      if (Get.isRegistered<VkycController>()) {
        Get.find<VkycController>().onVkycCancelDetected();
      } else {
        final vkycService = Get.isRegistered<VkycTestService>()
            ? VkycTestService.to
            : Get.put(VkycTestService());
        vkycService.handleVkycCancel();
      }
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
