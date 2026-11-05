import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:confetti/confetti.dart';

class UpdateKycController extends GetxController {
  var isRedirecting = false.obs;
  var isLoading = false.obs;
  var redirectionStatus = "Initializing secure connection...".obs;
  var redirectionProgress = 0.0.obs;

  var vkycApplicationId = "".obs;
  var vkycLink = "".obs;
  var vkycStatus = "".obs;

  var isKycUnderReview = false.obs;
  var isKycCompleted = false.obs;

  Timer? _redirectTimer;

  @override
  void onInit() {
    super.onInit();
    checkInitialKycState();
  }

  void checkInitialKycState() {
    // Check fullKycCompleted: if true then KYC is done, otherwise always allow KYC
    final bool completed =
        box.read('full_kyc_completed') == true ||
        box.read('is_kyc_completed') == true;
    isKycCompleted.value = completed;
    isKycUnderReview.value = false;
  }

  /// Triggered on tap of "Get Started" button on Full KYC screen
  Future<void> onGetStartedPressed() async {
    checkInitialKycState();
    if (isKycCompleted.value) {
      AppSnackbar.success("Your Full KYC is already verified.");
      return;
    }
    await initiateVkycUpgrade();
  }

  /// Verifies that all mandatory permissions (Camera, Microphone, Location) are granted.
  /// If any are missing, requests them. If still not granted, shows a mandatory permissions dialog.
  Future<bool> checkAndRequestPermissions() async {
    try {
      // 1. Check current permission statuses
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;
      final locationStatus = await Permission.location.status;

      final bool allAlreadyGranted =
          cameraStatus.isGranted &&
          micStatus.isGranted &&
          locationStatus.isGranted;

      if (allAlreadyGranted) {
        return true;
      }

      // If any permission is already permanently denied, show explanation dialog immediately
      final bool anyPermanentlyDenied =
          cameraStatus.isPermanentlyDenied ||
          micStatus.isPermanentlyDenied ||
          locationStatus.isPermanentlyDenied;

      if (anyPermanentlyDenied) {
        _showPermissionRequiredDialog(
          cameraGranted: cameraStatus.isGranted,
          micGranted: micStatus.isGranted,
          locationGranted: locationStatus.isGranted,
          hasPermanentlyDenied: true,
        );
        return false;
      }

      // Guard external flow in AppLockService during OS permission dialog
      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.startExternalFlow(ExternalFlowType.vkyc);
      }

      // 2. Request all 3 mandatory permissions simultaneously
      final statuses = await [
        Permission.camera,
        Permission.microphone,
        Permission.location,
      ].request();

      final isCameraGranted = statuses[Permission.camera]?.isGranted ?? false;
      final isMicGranted = statuses[Permission.microphone]?.isGranted ?? false;
      final isLocationGranted =
          statuses[Permission.location]?.isGranted ?? false;

      if (isCameraGranted && isMicGranted && isLocationGranted) {
        // Permissions granted! Keep ExternalFlowType.vkyc active as we transition into VKYC
        return true;
      }

      // Only release external flow if permissions were not granted
      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.finishExternalFlow(ExternalFlowType.vkyc);
      }

      // Check if user permanently denied any permission
      final isPermDenied =
          (statuses[Permission.camera]?.isPermanentlyDenied ?? false) ||
          (statuses[Permission.microphone]?.isPermanentlyDenied ?? false) ||
          (statuses[Permission.location]?.isPermanentlyDenied ?? false);

      _showPermissionRequiredDialog(
        cameraGranted: isCameraGranted,
        micGranted: isMicGranted,
        locationGranted: isLocationGranted,
        hasPermanentlyDenied: isPermDenied,
      );

      return false;
    } catch (e) {
      log("⚠️ [VKYC Permissions Error]: $e");
      AppSnackbar.error(
        "Failed to verify device permissions. Please try again.",
      );
      return false;
    }
  }

  /// Displays a mandatory permissions dialog explaining why each permission is required for Video KYC
  void _showPermissionRequiredDialog({
    required bool cameraGranted,
    required bool micGranted,
    required bool locationGranted,
    required bool hasPermanentlyDenied,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Security Header Icon
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: primaryRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: primaryRed,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                "Mandatory Permissions for VKYC",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                "Under RBI regulatory guidelines, Video KYC requires live camera, two-way audio, and geographic location verification. All permissions are mandatory to complete your verification.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),

              // Permission Breakdown Cards
              _buildPermissionItem(
                icon: Icons.videocam_rounded,
                title: "Camera Access",
                description:
                    "Required for live face verification and video call with compliance officer.",
                isGranted: cameraGranted,
              ),
              const SizedBox(height: 10),
              _buildPermissionItem(
                icon: Icons.mic_rounded,
                title: "Microphone Access",
                description:
                    "Required for real-time two-way audio communication during the call.",
                isGranted: micGranted,
              ),
              const SizedBox(height: 10),
              _buildPermissionItem(
                icon: Icons.location_on_rounded,
                title: "Location Access",
                description:
                    "Mandatory regulatory requirement to confirm you are within India during VKYC.",
                isGranted: locationGranted,
              ),
              const SizedBox(height: 22),

              // Action Buttons
              if (hasPermanentlyDenied) ...[
                CustomButton(
                  text: "Open App Settings",
                  btncolor: primaryRed,
                  borderRadius: 14,
                  textsize: Get.context?.responsive(14) ?? 14,
                  onPressed: () async {
                    if (Get.isRegistered<AppLockService>()) {
                      AppLockService.to.startExternalFlow(
                        ExternalFlowType.vkyc,
                      );
                    }
                    Get.back();
                    await openAppSettings();
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ] else ...[
                CustomButton(
                  text: "Grant Permissions",
                  btncolor: primaryRed,
                  textsize: Get.context?.responsive(14) ?? 14,
                  borderRadius: 14,
                  onPressed: () async {
                    Get.back();
                    await onGetStartedPressed();
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isGranted ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGranted ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isGranted
                  ? const Color(0xFFDCFCE7)
                  : primaryRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isGranted ? const Color(0xFF16A34A) : primaryRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isGranted
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGranted ? Icons.check : Icons.priority_high,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isGranted ? "Granted" : "Required",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Call POST /api/v1/kyc/vkyc/upgrade on Full KYC screen after permissions verified
  Future<void> initiateVkycUpgrade() async {
    if (isLoading.value) return;

    // Enforce mandatory permissions first
    final hasPermissions = await checkAndRequestPermissions();
    if (!hasPermissions) {
      return;
    }

    isLoading.value = true;

    try {
      final res = await ApiService.to.upgradeVkyc();
      if (res != null) {
        log("check VKYC respo : $res");
        vkycApplicationId.value = res['applicationId']?.toString() ?? "";
        vkycLink.value =
            res['link']?.toString() ??
            res['url']?.toString() ??
            res['vkycUrl']?.toString() ??
            "";
        final st = (res['status']?.toString() ?? "").toLowerCase();
        vkycStatus.value = st;

        final bool isDone =
            res['fullKycCompleted'] == true ||
            res['completed'] == true ||
            st == 'completed' ||
            st == 'verified' ||
            st == 'approved';

        if (isDone) {
          box.write('kyc_status', 'completed');
          box.write('is_kyc_completed', true);
          box.write('full_kyc_completed', true);
          isKycCompleted.value = true;
          AppSnackbar.success("Your Full KYC is already verified.");
          return;
        }

        if (vkycLink.value.isNotEmpty) {
          Get.toNamed('/vkyc_webview', arguments: vkycLink.value)?.then((_) {
            checkInitialKycState();
            final bool isVkycPending =
                box.read('pending_vkyc_success_dialog') == true;
            final bool isDone =
                box.read('full_kyc_completed') == true ||
                box.read('is_kyc_completed') == true;
            if (isVkycPending || isDone) {
              Get.offAllNamed(
                '/dashboard',
                arguments: {'showVkycSuccess': true},
              );
            }
          });
          return;
        }
      }
      AppSnackbar.error(
        "Unable to retrieve VKYC verification link. Please try again.",
      );
    } catch (e) {
      AppSnackbar.error("Failed to initiate VKYC upgrade: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void startBrowserRedirection() {
    isRedirecting.value = true;
    redirectionProgress.value = 0.0;
    redirectionStatus.value = "Opening secure browser session...";

    _redirectTimer?.cancel();

    int elapsed = 0;
    _redirectTimer = Timer.periodic(const Duration(milliseconds: 1000), (
      timer,
    ) {
      elapsed++;
      redirectionProgress.value = (elapsed / 6) * 1.0;

      if (elapsed == 1) {
        redirectionStatus.value = "Launching secure KYC partner portal...";
      } else if (elapsed == 3) {
        redirectionStatus.value =
            "Awaiting verification completion on browser...";
      } else if (elapsed == 5) {
        redirectionStatus.value =
            "Biometric check & document signatures verified!";
      } else if (elapsed >= 6) {
        timer.cancel();
        isRedirecting.value = false;
        showKycSuccessPopup();
      }
    });
  }

  late ConfettiController confettiController = ConfettiController(
    duration: const Duration(seconds: 10),
  );

  void playAnimation() {
    confettiController.play();
  }

  @override
  void onClose() {
    _redirectTimer?.cancel();
    confettiController.dispose();
    super.onClose();
  }

  void showKycSuccessPopup() {
    // Write KYC status after the current frame to avoid reactive rebuild
    // colliding with an ongoing Navigator transition (navigator_debugLocked).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      box.write('is_kyc_completed', true);
      box.write('kyc_status', 'verified');
    });

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: true,
                  numberOfParticles: 40,
                  emissionFrequency: 0.08,
                  maxBlastForce: 25,
                  minBlastForce: 10,
                  gravity: 0.2,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.orange,
                    Colors.purple,
                    Colors.red,
                    Colors.yellow,
                    Colors.pink,
                    Colors.cyan,
                    Colors.teal,
                    Colors.amber,
                    Colors.indigo,
                    Colors.lime,
                    Color(0xFF00E5FF),
                    Color(0xFFFF4081),
                    Color(0xFFFFD740),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: Colors.green, size: 60),
                  const SizedBox(height: 10),
                  const Text(
                    "Congratulations 🎉",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Your Full KYC is Successfully Completed.\nYou can now enjoy all features!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: "Go to Dashboard",
                    btncolor: Colors.black,
                    textsize: Get.context?.responsive(14) ?? 14,
                    onPressed: () {
                      // Use offAllNamed only — calling Get.back() first
                      // while the dialog is still mounted causes the
                      // '!_debugLocked' Navigator assertion.
                      Get.offAllNamed("/dashboard");
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
    playAnimation();
  }
}
