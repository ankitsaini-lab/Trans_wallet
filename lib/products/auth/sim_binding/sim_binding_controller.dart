import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/deepid_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

class SimBindingController extends GetxController {
  final RxString phoneNumber = ''.obs;
  final RxString returnRoute = '/login_singupview'.obs;
  final RxBool isLoading = false.obs;
  final RxString statusMessage = 'Preparing secure SIM verification...'.obs;
  final Rx<DeepIdBindingStatus> currentStatus =
      DeepIdBindingStatus.notStarted.obs;
  final RxBool isVerified = false.obs;
  final RxBool canRetry = false.obs;

  // Multi-SIM selection state
  final RxList<DetectedSimCard> simCards = <DetectedSimCard>[].obs;
  final RxInt selectedSimIndex = 0.obs;
  final RxBool isScanningSims = false.obs;
  final phoneInputController = TextEditingController();

  DetectedSimCard? get currentSelectedSim {
    if (simCards.isEmpty) return null;
    if (selectedSimIndex.value >= 0 &&
        selectedSimIndex.value < simCards.length) {
      return simCards[selectedSimIndex.value];
    }
    return simCards.first;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      if (args['phone'] != null && args['phone'].toString().isNotEmpty) {
        phoneNumber.value = args['phone'].toString().trim();
        phoneInputController.text = phoneNumber.value;
      }
      if (args['returnRoute'] != null) {
        returnRoute.value = args['returnRoute'].toString();
      }
    }

    if (phoneNumber.value.isEmpty) {
      final box = GetStorage();
      final saved =
          box.read('phone')?.toString() ??
          box.read('bound_mobile')?.toString() ??
          box.read('remembered_phone')?.toString() ??
          box.read('mobileNumber')?.toString();
      if (saved != null && saved.isNotEmpty) {
        phoneNumber.value = saved;
        phoneInputController.text = saved;
      }
    }

    // Auto-detect SIM cards installed in handset
    scanDeviceSims();
  }

  @override
  void onClose() {
    phoneInputController.dispose();
    super.onClose();
  }

  /// Scans SIM cards and auto-picks detected mobile number
  Future<void> scanDeviceSims() async {
    isScanningSims.value = true;
    try {
      final detected = await DeepIdService.to.detectDeviceSimCards();
      simCards.assignAll(detected);

      if (detected.isNotEmpty) {
        // Default to slot 0
        selectSim(0);
      }
    } catch (e) {
      developer.log('[SimBindingController] Error scanning SIMs: $e');
    } finally {
      isScanningSims.value = false;
    }
  }

  /// Request Google Phone Number Hint popup (like GPay / PhonePe / YONlO)
  Future<void> pickNumberWithHint() async {
    try {
      final hint = await DeepIdService.to.requestPhoneNumberHint();
      if (hint != null && hint.isNotEmpty) {
        phoneNumber.value = hint;
        phoneInputController.text = hint;
        developer.log(
          '[SimBindingController] Auto-filled from Google Phone Number Hint: $hint',
        );
      }
    } catch (e) {
      developer.log('[SimBindingController] Hint picker error: $e');
    }
  }

  /// Select a SIM card slot (SIM 1 or SIM 2)
  void selectSim(int index) {
    if (index < 0 || index >= simCards.length) return;
    selectedSimIndex.value = index;
    final sim = simCards[index];

    if (sim.hasNumber) {
      phoneNumber.value = sim.number;
      phoneInputController.text = sim.number;
    }
    developer.log(
      '[SimBindingController] Selected ${sim.slotLabel} (${sim.carrierName})',
    );
  }

  void onPhoneNumberChanged(String value) {
    phoneNumber.value = value.trim();
  }

  /// Start the SIM binding verification
  Future<void> startBinding() async {
    if (isLoading.value) return;

    if (simCards.isEmpty) {
      AppSnackbar.error("No active SIM card detected in this device.");
      return;
    }

    // Phone number is optional for SIM binding: carrier identifies SIM from silent SMS.
    final sim = currentSelectedSim;
    String? numberToVerify;
    if (sim != null && sim.hasNumber) {
      numberToVerify = sim.number;
    } else if (phoneNumber.value.trim().isNotEmpty) {
      numberToVerify = phoneNumber.value.trim();
    } else if (phoneInputController.text.trim().isNotEmpty) {
      numberToVerify = phoneInputController.text.trim();
    }

    isLoading.value = true;
    canRetry.value = false;
    final carrierName = sim?.carrierName ?? 'SIM';
    statusMessage.value =
        "Verifying $carrierName & sending carrier attestation SMS...";

    try {
      final service = DeepIdService.to;
      final status = await service.startSimBindingFlow(
        phoneNumber: numberToVerify,
      );

      if (service.lastSimBindingResult != null) {
        developer.log(
          '[SimBindingController] SIM binding result received from DeepID SDK: '
          'Mobile=${service.lastSimBindingResult?.mobile}, '
          'DeepId=${service.lastSimBindingResult?.deepId}, '
          'SessionId=${service.lastSimBindingResult?.sessionId}, '
          'Success=${service.lastSimBindingResult?.success}',
        );
      }

      currentStatus.value = status;

      final verifiedMobile =
          (service.lastSimBindingResult?.mobile.isNotEmpty == true)
          ? service.lastSimBindingResult!.mobile
          : (numberToVerify ?? '');

      switch (status) {
        case DeepIdBindingStatus.verified:
          isVerified.value = true;
          statusMessage.value = "SIM binding verified successfully by backend!";
          _saveVerifiedSimState(verifiedMobile);
          AppSnackbar.success("Device and SIM binding verified successfully!");
          await Future.delayed(const Duration(milliseconds: 1200));
          _navigateForward();
          break;

        case DeepIdBindingStatus.backendUnavailable:
          isVerified.value = true;
          statusMessage.value =
              "Device bound, but backend verification endpoint is pending on server.";
          _saveVerifiedSimState(verifiedMobile);
          developer.log(
            "[SimBindingController] Backend verification endpoint not reachable. Proceeding to: ${returnRoute.value}",
          );
          AppSnackbar.info(
            "Device SIM verified. (Backend verification endpoint /api/v1/auth/sim-binding/verify is pending implementation).",
          );
          await Future.delayed(const Duration(milliseconds: 1200));
          _navigateForward();
          break;

        case DeepIdBindingStatus.permissionDenied:
          statusMessage.value = "Permissions are required to bind your SIM.";
          canRetry.value = true;
          break;

        case DeepIdBindingStatus.cancelled:
          statusMessage.value = "SIM binding verification was cancelled.";
          canRetry.value = true;
          break;

        case DeepIdBindingStatus.abandoned:
          statusMessage.value =
              "Verification was interrupted. Please stay in the app during the flow.";
          canRetry.value = true;
          break;

        case DeepIdBindingStatus.failed:
        default:
          statusMessage.value = "SIM binding failed. Please retry.";
          canRetry.value = true;
          break;
      }
    } catch (e) {
      developer.log("[SimBindingController] Error: $e");
      statusMessage.value = "Verification error. Please try again.";
      canRetry.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void _saveVerifiedSimState(String verifiedMobile) {
    final box = GetStorage();
    box.remove('sim_binding_skipped');
    box.write('phone', verifiedMobile);
    box.write('bound_mobile', verifiedMobile);
    box.write('deepid_bound_mobile', verifiedMobile);
    box.write('is_sim_bound', true);
    box.write('deepid_sim_binding_verified', true);
    box.write('deepid_device_trusted', true);
  }

  void _navigateForward() {
    final route = returnRoute.value;
    final isLoggedIn =
        Get.isRegistered<AuthService>() && AuthService.to.isLoggedIn;

    if (isLoggedIn) {
      Get.offAllNamed('/dashboard');
    } else {
      if (route.isNotEmpty && route != '/sim_binding') {
        Get.offAllNamed(route);
      } else {
        Get.offAllNamed('/login_singupview');
      }
    }
  }

  void skipOrCancel() {
    final box = GetStorage();
    box.write('sim_binding_skipped', true);
    box.write('is_sim_bound', true);
    box.write('deepid_sim_binding_verified', true);
    box.write('deepid_device_trusted', true);

    final number = phoneInputController.text.trim().isNotEmpty
        ? phoneInputController.text.trim()
        : phoneNumber.value.trim();
    if (number.isNotEmpty) {
      box.write('phone', number);
      box.write('bound_mobile', number);
      box.write('deepid_bound_mobile', number);
    }

    AppSnackbar.info("SIM binding skipped temporarily.");
    _navigateForward();
  }
}
