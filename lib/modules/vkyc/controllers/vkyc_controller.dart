import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:transwallet/modules/vkyc/services/vkyc_test_service.dart';
import 'package:transwallet/products/Dashboard screen/dashboardscreen_Controller.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
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

  Future<void> startTestVkyc() async {
    _isProcessing = false;
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    final loc = await Permission.location.status;

    if (!camera.isGranted || !mic.isGranted || !loc.isGranted) {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
        Permission.location,
      ].request();

      final allGranted =
          (statuses[Permission.camera]?.isGranted ?? false) &&
          (statuses[Permission.microphone]?.isGranted ?? false) &&
          (statuses[Permission.location]?.isGranted ?? false);

      if (!allGranted) {
        AppSnackbar.error(
          "Camera, Microphone, and Location permissions are mandatory for Video KYC.",
        );
        return;
      }
    }

    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.startExternalFlow(ExternalFlowType.vkyc);
    }
    _vkycService.startVkyc();
    Get.toNamed('/vkyc_webview');
  }

  Future<void> onVkycSuccessDetected() async {
    if (_isProcessing) return;
    _isProcessing = true;
    isLoading.value = true;
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.startExternalFlow(ExternalFlowType.vkyc);
    }
    debugPrint("✅ [VkycController] Processing VKYC success...");

    try {
      await _vkycService.handleVkycSuccess();

      final box = GetStorage();
      box.write('pending_vkyc_success_dialog', true);
      box.write('is_kyc_completed', true);
      box.write('full_kyc_completed', true);
      box.write('kyc_status', 'completed');
      box.write('kyc_current_level', 'FULL');

      // Fetch authoritative user profile & live KYC data from /api/v1/users/me
      if (Get.isRegistered<ApiService>()) {
        await ApiService.to.fetchUserProfile(force: true);
      }

      // Sync live dashboard controller in memory if available
      if (Get.isRegistered<DashboardscreenController>()) {
        final dashCtrl = Get.find<DashboardscreenController>();
        dashCtrl.loadUserData();
        dashCtrl.refreshDashboardData(force: true);
      }

      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.finishExternalFlow(ExternalFlowType.vkyc);
      }
      // Navigate to existing Dashboard route with success argument
      Get.offAllNamed('/dashboard', arguments: {'showVkycSuccess': true});
    } catch (e) {
      errorMessage.value = "Failed to verify VKYC status: $e";
      AppSnackbar.error("VKYC verification failed");
    } finally {
      isLoading.value = false;
      _isProcessing = false;
      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.finishExternalFlow(ExternalFlowType.vkyc);
      }
    }
  }

  Future<void> onVkycReviewInProgressDetected({
    String? message,
    String? applicationId,
  }) async {
    if (_isProcessing) return;
    _isProcessing = true;
    isLoading.value = true;
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.startExternalFlow(ExternalFlowType.vkyc);
    }
    debugPrint("⏳ [VkycController] Processing VKYC review in progress...");

    try {
      await _vkycService.handleVkycUnderReview();

      if (applicationId != null && applicationId.isNotEmpty) {
        final box = GetStorage();
        box.write('vkyc_application_id', applicationId);
      }

      // Fetch authoritative user profile & live KYC data from /api/v1/users/me
      if (Get.isRegistered<ApiService>()) {
        await ApiService.to.fetchUserProfile(force: true);
      }

      final box = GetStorage();
      final rawStatus = box.read('kyc_status')?.toString().toLowerCase() ?? '';
      final bool isCompleted =
          box.read('is_kyc_completed') == true ||
          box.read('full_kyc_completed') == true;

      if (isCompleted) {
        AppSnackbar.success(
          "Full KYC Verified Successfully!",
          title: "Approved",
        );
      } else if (rawStatus == 'under_review' || rawStatus == 'in_progress') {
        AppSnackbar.info(
          message ??
              "Video KYC submitted successfully and is currently under review. This usually takes 24–48 hours.",
          title: "Review In Progress",
        );
      } else {
        AppSnackbar.info(
          message ?? "KYC data synced from server.",
          title: "KYC Status",
        );
      }

      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.finishExternalFlow(ExternalFlowType.vkyc);
      }
      // Navigate back to Dashboard
      Get.offAllNamed('/dashboard');
    } catch (e) {
      errorMessage.value = "Failed to update VKYC status: $e";
      AppSnackbar.error("Failed to process VKYC status");
    } finally {
      isLoading.value = false;
      _isProcessing = false;
      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.finishExternalFlow(ExternalFlowType.vkyc);
      }
    }
  }

  Future<void> onVkycRejectedDetected({String? reason}) async {
    if (_isProcessing) return;
    _isProcessing = true;
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.startExternalFlow(ExternalFlowType.vkyc);
    }
    debugPrint("❌ [VkycController] Processing VKYC rejection...");

    try {
      await _vkycService.handleVkycRejected();
      final box = GetStorage();
      box.write('is_kyc_completed', false);
      box.write('kyc_status', 'rejected');
      AppSnackbar.error(
        reason ??
            "Video KYC verification was not approved. You can try again or contact customer support.",
        title: "Verification Incomplete",
      );

      if (Get.currentRoute == '/vkyc_webview' &&
          (Get.key.currentState?.canPop() ?? false)) {
        Get.back();
      }
    } finally {
      _isProcessing = false;
      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.finishExternalFlow(ExternalFlowType.vkyc);
      }
    }
  }

  void onVkycCancelDetected() {
    if (_isProcessing) return;
    _isProcessing = true;
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.startExternalFlow(ExternalFlowType.vkyc);
    }
    debugPrint("🚫 [VkycController] Processing VKYC cancel...");
    _vkycService.handleVkycCancel();
    AppSnackbar.info("VKYC process cancelled.");

    // Return to previous screen
    if (Get.currentRoute == '/vkyc_webview' &&
        (Get.key.currentState?.canPop() ?? false)) {
      Get.back();
    }
    _isProcessing = false;
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.finishExternalFlow(ExternalFlowType.vkyc);
    }
  }

  void onClosePressed() {
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.finishExternalFlow(ExternalFlowType.vkyc);
    }
    if (Get.currentRoute == '/vkyc_webview' &&
        (Get.key.currentState?.canPop() ?? false)) {
      Get.back();
    }
  }

  @override
  void onClose() {
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.finishExternalFlow(ExternalFlowType.vkyc);
    }
    super.onClose();
  }
}
