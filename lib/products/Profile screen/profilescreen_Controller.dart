import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/products/Dashboard%20screen/dashboardscreen_Controller.dart';
import 'package:transwallet/products/Profile%20screen/profile%20details/profile_details_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/products/login_singupscreen/login_singupscreen_Controller.dart';
import 'widgets/animated_logout_dialog.dart';

class ProfilescreenController extends GetxController {
  static ProfilescreenController get to {
    if (!Get.isRegistered<ProfilescreenController>()) {
      return Get.put(ProfilescreenController());
    }
    return Get.find<ProfilescreenController>();
  }

  var selectedIndex = 3.obs;
  var isKycVerified = false.obs;
  var isKycUnderReview = false.obs;
  var biometricEnabled = true.obs;
  var appLockEnabled = true.obs;
  var appLockTimeout = 30.obs;
  var profilePictureUrl = "".obs;
  final Rxn<File> localImageFile = Rxn<File>();
  final RxBool isUploadingImage = false.obs;
  var userName = "User".obs;
  var userPhone = "".obs;

  void clear() {
    userName.value = "User";
    userPhone.value = "";
    profilePictureUrl.value = "";
    localImageFile.value = null;
    isKycVerified.value = false;
    isKycUnderReview.value = false;
    biometricEnabled.value = false;
    appLockEnabled.value = false;
    isUploadingImage.value = false;
  }

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    profilePictureUrl.value = box.read('profilePictureUrl')?.toString() ?? '';
    biometricEnabled.value = false;
    box.write('biometric_enabled', false);
    if (Get.isRegistered<AppLockService>()) {
      appLockTimeout.value = AppLockService.to.appLockTimeoutSeconds;
      appLockEnabled.value = AppLockService.to.isAppLockEnabled;
    } else {
      appLockTimeout.value = box.read('app_lock_timeout_seconds') ?? 30;
      appLockEnabled.value = (box.read<bool>('app_lock_enabled') ?? false) &&
          (box.read<bool>('app_lock_disabled') != true);
    }
    loadUserData();
    fetchFromApi();
    _checkLostData();
  }

  Future<void> _checkLostData() async {
    // 1. Check if fast-restore from Splash recovered the image
    final recoveredPath = box.read<String>('recovered_camera_image');
    if (recoveredPath != null && recoveredPath.isNotEmpty) {
      box.remove('recovered_camera_image');
      final file = File(recoveredPath);
      if (await file.exists()) {
        log("[Profile] Uploading recovered camera image from Splash: $recoveredPath");
        await _processAndUploadFile(XFile(recoveredPath));
        return;
      }
    }

    // 2. Direct retrieveLostData check as secondary safeguard
    if (!Platform.isAndroid) return;
    try {
      final picker = ImagePicker();
      final LostDataResponse response = await picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null) {
        log("[Profile] Recovered lost image from camera: ${response.file!.path}");
        box.remove('pending_camera_upload');
        await _processAndUploadFile(response.file!);
      } else if (response.files != null && response.files!.isNotEmpty) {
        log("[Profile] Recovered lost image from camera: ${response.files!.first.path}");
        box.remove('pending_camera_upload');
        await _processAndUploadFile(response.files!.first);
      } else if (response.exception != null) {
        log("[Profile] LostDataResponse exception: ${response.exception}");
      }
    } catch (e) {
      log("[Profile] Error retrieving lost data: $e");
    }
  }

  void loadUserData() {
    final rawStatus = box.read('kyc_status')?.toString().toLowerCase() ?? '';
    final bool underReview = rawStatus == 'under_review' ||
        rawStatus == 'in_progress' ||
        rawStatus == 'review_in_progress';
    isKycUnderReview.value = underReview;

    isKycVerified.value = !underReview &&
        (box.read('is_kyc_completed') == true ||
            box.read('full_kyc_completed') == true ||
            rawStatus == 'verified' ||
            rawStatus == 'completed' ||
            rawStatus == 'approved' ||
            rawStatus == 'upgrade_success');
    userName.value = box.read('name')?.toString() ?? "User";
    final rawPhone = box.read('phone')?.toString() ??
        box.read('mobileNumber')?.toString() ??
        box.read('user_mobile')?.toString() ??
        '';
    if (rawPhone.isNotEmpty) {
      if (rawPhone.startsWith('+')) {
        userPhone.value = rawPhone;
      } else if (rawPhone.length == 10) {
        userPhone.value = "+91 ${rawPhone.substring(0, 5)} ${rawPhone.substring(5)}";
      } else {
        userPhone.value = "+91 $rawPhone";
      }
    } else {
      userPhone.value = "";
    }
  }

  Future<void> fetchFromApi({bool force = false}) async {
    if (Get.isRegistered<ApiService>()) {
      final profile = await ApiService.to.fetchUserProfile(force: force);
      if (profile != null) {
        loadUserData();
        profilePictureUrl.value = box.read('profilePictureUrl')?.toString() ?? '';
      }
    }
  }

  Future<void> uploadProfilePicture() async {
    if (isUploadingImage.value) return;

    log("uploadProfilePicture triggered");
    final ImageSource? source = await Get.bottomSheet<ImageSource>(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Image Source",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library, color: primaryRed),
              title: const Text(
                "Gallery",
                style: TextStyle(color: Colors.black),
              ),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primaryRed),
              title: const Text(
                "Camera",
                style: TextStyle(color: Colors.black),
              ),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    // Allow bottomsheet modal transition to finish cleanly before camera activity launches
    await Future.delayed(const Duration(milliseconds: 200));

    isUploadingImage.value = true;
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.setPickingMedia(true);
    }

    try {
      if (source == ImageSource.camera) {
        var cameraStatus = await Permission.camera.status;
        if (!cameraStatus.isGranted) {
          cameraStatus = await Permission.camera.request();
        }
        if (!cameraStatus.isGranted) {
          if (cameraStatus.isPermanentlyDenied) {
            _showPermissionDeniedDialog(
              title: "Camera Permission Required",
              message:
                  "Camera access is permanently denied. Please allow camera access in Settings to take a profile picture.",
            );
          } else {
            AppSnackbar.error("Camera access was denied.");
          }
          return;
        }
      } else if (source == ImageSource.gallery) {
        if (Platform.isIOS) {
          var photosStatus = await Permission.photos.status;
          if (!photosStatus.isGranted && !photosStatus.isLimited) {
            photosStatus = await Permission.photos.request();
          }
          if (!photosStatus.isGranted && !photosStatus.isLimited) {
            if (photosStatus.isPermanentlyDenied) {
              _showPermissionDeniedDialog(
                title: "Gallery Permission Required",
                message:
                    "Photo library access is permanently denied. Please allow access in Settings to select a profile picture.",
              );
            } else {
              AppSnackbar.error("Gallery access was denied.");
            }
            return;
          }
        }
      }

      // Free Flutter image caches before external camera/gallery app launches to avoid Android Low Memory Killer (LMK)
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      if (source == ImageSource.camera) {
        box.write('pending_camera_upload', 'profile');
      }

      XFile? pickedFile;
      try {
        final picker = ImagePicker();
        // Downscale to 800x800 at 75% quality to prevent Android LMK process death
        // Do NOT pass preferredCameraDevice: CameraDevice.front as it crashes MIUI/OEM camera intents
        pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );
      } on PlatformException catch (e) {
        log("ImagePicker PlatformException: ${e.code} - ${e.message}");
        if (e.code == 'photo_access_denied' ||
            e.code == 'camera_access_denied' ||
            e.message?.toLowerCase().contains('permission') == true) {
          _showPermissionDeniedDialog(
            title: source == ImageSource.camera
                ? "Camera Permission Required"
                : "Gallery Permission Required",
            message: source == ImageSource.camera
                ? "Camera access was denied. Please allow access in Settings."
                : "Gallery access was denied. Please allow access in Settings.",
          );
        } else {
          try {
            final fallbackPicker = ImagePicker();
            pickedFile = await fallbackPicker.pickImage(source: source);
          } catch (retryError) {
            log("Fallback camera pick failed: $retryError");
            AppSnackbar.error("Failed to capture image: ${e.message ?? e.code}");
          }
        }
        if (pickedFile == null) return;
      } catch (e) {
        log("Error picking image: $e, attempting standard fallback...");
        try {
          final fallbackPicker = ImagePicker();
          pickedFile = await fallbackPicker.pickImage(source: source);
        } catch (retryError) {
          log("Fallback camera pick failed: $retryError");
          AppSnackbar.error("Unable to pick image. Please try again.");
          return;
        }
      }

      if (pickedFile == null) {
        log("[Profile] User cancelled image selection.");
        return;
      }

      await _processAndUploadFile(pickedFile);
    } finally {
      box.remove('pending_camera_upload');
      isUploadingImage.value = false;
      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.setPickingMedia(false);
      }
    }
  }

  Future<void> _processAndUploadFile(XFile pickedFile) async {
    if (isClosed) return;

    final path = pickedFile.path.toLowerCase();
    final ext = path.split('.').last;
    const allowedExts = ['jpg', 'jpeg', 'png', 'webp', 'heic'];
    if (!allowedExts.contains(ext)) {
      AppSnackbar.error("Invalid format. Allowed formats: JPEG, PNG, WebP");
      return;
    }

    final localFile = File(pickedFile.path);
    if (!await localFile.exists()) {
      AppSnackbar.error("Failed to access captured image file.");
      return;
    }

    final fileSize = await localFile.length();
    const maxSizeBytes = 5 * 1024 * 1024;
    if (fileSize > maxSizeBytes) {
      AppSnackbar.error("Image size exceeds maximum limit of 5MB");
      return;
    }

    // Set optimistic preview and set in-place avatar loading state (no route-popping Get.dialog!)
    localImageFile.value = localFile;
    profilePictureUrl.refresh();
    isUploadingImage.value = true;

    try {
      if (Get.isRegistered<ApiService>()) {
        final result = await ApiService.to.uploadProfilePicture(pickedFile);

        if (isClosed) return;

        if (result.isSuccess &&
            result.url != null &&
            result.url!.isNotEmpty) {
          final newUrl = result.url!;
          _evictImageCaches(newUrl, profilePictureUrl.value);

          box.write('profilePictureUrl', newUrl);
          profilePictureUrl.value = newUrl;
          localImageFile.value = null;
          profilePictureUrl.refresh();

          _syncProfilePictureAcrossControllers(newUrl);

          AppSnackbar.success("Profile picture updated successfully!");
        } else {
          localImageFile.value = null;
          profilePictureUrl.refresh();
          AppSnackbar.error(
            result.errorMessage ?? "Failed to upload profile picture",
          );
        }
      } else {
        localImageFile.value = null;
        profilePictureUrl.refresh();
        AppSnackbar.error("Network service unavailable");
      }
    } catch (e) {
      log("[Profile] Upload error: $e");
      localImageFile.value = null;
      profilePictureUrl.refresh();
      AppSnackbar.error("Error uploading profile picture: $e");
    } finally {
      isUploadingImage.value = false;
    }
  }

  void _evictImageCaches(String newUrl, String oldUrl) {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      if (newUrl.startsWith('http://') || newUrl.startsWith('https://')) {
        NetworkImage(newUrl).evict();
      }
      if (oldUrl.isNotEmpty &&
          (oldUrl.startsWith('http://') || oldUrl.startsWith('https://'))) {
        NetworkImage(oldUrl).evict();
      }
    } catch (_) {}
  }

  void _syncProfilePictureAcrossControllers(String newUrl) {
    if (Get.isRegistered<DashboardscreenController>()) {
      final dash = Get.find<DashboardscreenController>();
      dash.profilePictureUrl.value = newUrl;
      dash.profilePictureUrl.refresh();
      dash.loadUserData();
    }
    if (Get.isRegistered<ProfileDetailsController>()) {
      final details = Get.find<ProfileDetailsController>();
      details.profilePictureUrl.value = newUrl;
      details.localImageFile.value = null;
      details.profilePictureUrl.refresh();
    }
  }

  Future<void> toggleBiometric(bool val) async {
    biometricEnabled.value = false;
    box.write('biometric_enabled', false);
  }

  void toggleAppLock(bool val) {
    appLockEnabled.value = val;
    box.write('app_lock_enabled', val);
    box.write('app_lock_disabled', !val);
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.setAppLockEnabled(val);
    }
  }

  void updateLockTimeout(int seconds) {
    appLockTimeout.value = seconds;
    box.write('app_lock_timeout_seconds', seconds);
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.setAppLockTimeout(seconds);
    }
  }

  void handleKycTap() {
    if (isKycVerified.value) {
      Get.snackbar(
        "Already Verified",
        "Your KYC is already completed.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF111111),
        colorText: Colors.white,
      );
    } else if (isKycUnderReview.value) {
      Get.snackbar(
        "Verification Under Review",
        "Your Video KYC is currently under review. Please allow 24–48 hours for verification.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF111111),
        colorText: Colors.white,
      );
    } else {
      Get.toNamed('/updateKyc')?.then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          loadUserData();
          fetchFromApi(force: true);
        });
      });
    }
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  void onMenuTap(String title) {}
  Widget menuItem(
    String title,
    String icon, {
    VoidCallback? onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(icon.toString(), height: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: isLogout ? Colors.redAccent : Colors.black,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 12,
        color: Colors.black38,
      ),
      onTap: onTap,
    );
  }

  void showLuxuryLogoutDialog(BuildContext context) {
    Get.dialog(
      AnimatedLogoutDialog(
        onConfirm: () async {
          Get.back();
          await performLogout();
        },
        onCancel: () => Get.back(),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.25),
      barrierDismissible: false,
    );
  }

  Future<void> performLogout() async {
    if (Get.isRegistered<AuthService>() && AuthService.to.isLoggingOut) return;
    if (Get.isRegistered<AuthService>()) {
      await AuthService.to.logout(navigateToLogin: true);
    } else {
      Get.offAllNamed('/login_singupview');
    }
  }

  void _showPermissionDeniedDialog({
    required String title,
    required String message,
  }) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        content: Text(message, style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text("Open Settings", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
