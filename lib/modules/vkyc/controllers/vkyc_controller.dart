import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:transwallet/modules/vkyc/services/vkyc_test_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

class VkycController extends GetxController {
  late final VkycTestService _vkycService;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  bool _isProcessing = false;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<VkycTestService>()) {
      _vkycService = VkycTestService.to;
    } else {
      _vkycService = Get.put(VkycTestService());
    }
  }

  VkycStatus get currentStatus => _vkycService.status.value;

  void startTestVkyc() {
    _isProcessing = false;
    _vkycService.startVkyc();
    Get.toNamed('/vkyc_webview');
  }

  Future<void> onVkycSuccessDetected() async {
    if (_isProcessing) return;
    _isProcessing = true;
    isLoading.value = true;
    debugPrint("✅ [VkycController] Processing VKYC success...");

    try {
      await _vkycService.handleVkycSuccess();
      AppSnackbar.success("VKYC Completed Successfully!", title: "Approved");
      
      // Navigate to existing Dashboard route
      Get.offAllNamed('/dashboard');
    } catch (e) {
      errorMessage.value = "Failed to verify VKYC status: $e";
      AppSnackbar.error("VKYC verification failed");
    } finally {
      isLoading.value = false;
      _isProcessing = false;
    }
  }

  void onVkycCancelDetected() {
    if (_isProcessing) return;
    _isProcessing = true;
    debugPrint("🚫 [VkycController] Processing VKYC cancel...");
    _vkycService.handleVkycCancel();
    AppSnackbar.info("VKYC process cancelled.");
    
    // Return to previous screen
    if (Get.currentRoute == '/vkyc_webview') {
      Get.back();
    }
    _isProcessing = false;
  }

  void onClosePressed() {
    if (Get.currentRoute == '/vkyc_webview') {
      Get.back();
    }
  }
}

