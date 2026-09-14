import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'widgets/animated_logout_dialog.dart';

class ProfilescreenController extends GetxController {
  var selectedIndex = 3.obs;
  var isKycVerified = false.obs;
  var biometricEnabled = true.obs;
  var profilePictureUrl = "".obs;
  var userName = "User".obs;
  var userPhone = "".obs;

  @override
  void onInit() {
    super.onInit();
    isKycVerified.value = box.read('is_kyc_completed') ?? false;
    profilePictureUrl.value = box.read('profilePictureUrl')?.toString() ?? '';
    if (Get.isRegistered<BiometricService>()) {
      biometricEnabled.value = BiometricService.to.isBiometricEnabled.value;
    } else {
      biometricEnabled.value = box.read('biometric_enabled') ?? true;
    }
    loadUserData();
    fetchFromApi();
  }

  void loadUserData() {
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

  Future<void> fetchFromApi() async {
    if (Get.isRegistered<ApiService>()) {
      final profile = await ApiService.to.fetchUserProfile();
      if (profile != null) {
        loadUserData();
        profilePictureUrl.value = box.read('profilePictureUrl')?.toString() ?? '';
      }
    }
  }

  Future<void> uploadProfilePicture() async {
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

    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.setPickingMedia(true);
    }

    try {
      // Safely check permission, fallback to native picker if plugin channel is unavailable
      try {
        if (source == ImageSource.gallery) {
          final photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted && !photosStatus.isLimited) {
            final storageStatus = await Permission.storage.request();
            if (!storageStatus.isGranted && (photosStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied)) {
              _showPermissionDeniedDialog(
                title: "Gallery Permission Required",
                message: "Please grant gallery access to select your profile picture.",
              );
              return;
            }
          }
        } else if (source == ImageSource.camera) {
          final cameraStatus = await Permission.camera.request();
          if (!cameraStatus.isGranted && cameraStatus.isPermanentlyDenied) {
            _showPermissionDeniedDialog(
              title: "Camera Permission Required",
              message: "Please grant camera access to take your profile picture.",
            );
            return;
          }
        }
      } catch (e) {
        log("PermissionHandler channel exception caught safely: $e");
      }

      XFile? pickedFile;
      try {
        final picker = ImagePicker();
        pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 85,
        );
      } on PlatformException catch (e) {
        log("ImagePicker PlatformException: ${e.code} - ${e.message}");
        if (e.code == 'photo_access_denied' || e.code == 'camera_access_denied' || e.message?.contains('permission') == true) {
          _showPermissionDeniedDialog(
            title: source == ImageSource.camera ? "Camera Permission Required" : "Gallery Permission Required",
            message: source == ImageSource.camera
                ? "Camera access was denied. Please allow access in Settings."
                : "Gallery access was denied. Please allow access in Settings.",
          );
        }
        return;
      } catch (e) {
        log("Error picking image: $e");
        return;
      }

      if (pickedFile == null) return;

      // Validate format (JPEG, PNG, WebP)
      final ext = pickedFile.name.split('.').last.toLowerCase();
      final allowedExts = ['jpg', 'jpeg', 'png', 'webp'];
      if (!allowedExts.contains(ext)) {
        AppSnackbar.error("Invalid format. Allowed formats: JPEG, PNG, WebP");
        return;
      }

      // Validate size (max 2MB = 2097152 bytes)
      final bytes = await pickedFile.readAsBytes();
      const maxSizeBytes = 2 * 1024 * 1024;
      if (bytes.length > maxSizeBytes) {
        AppSnackbar.error("Image size exceeds maximum limit of 2MB");
        return;
      }

      Get.dialog(
        const Center(child: CircularProgressIndicator(color: primaryRed)),
        barrierDismissible: false,
      );

      try {
        if (Get.isRegistered<ApiService>()) {
          final newUrl = await ApiService.to.uploadProfilePicture(pickedFile);
          if (Get.isDialogOpen ?? false) Get.back();

          if (newUrl != null && newUrl.isNotEmpty) {
            profilePictureUrl.value = newUrl;
            AppSnackbar.success("Profile picture updated successfully!");
          } else {
            AppSnackbar.error("Failed to upload profile picture");
          }
        } else {
          if (Get.isDialogOpen ?? false) Get.back();
          AppSnackbar.error("Network service unavailable");
        }
      } catch (e) {
        if (Get.isDialogOpen ?? false) Get.back();
        AppSnackbar.error("Error uploading profile picture: $e");
      }
    } finally {
      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.setPickingMedia(false);
      }
    }
  }

  Future<void> toggleBiometric(bool val) async {
    if (Get.isRegistered<BiometricService>()) {
      final success = await BiometricService.to.setBiometricEnabled(
        val,
        verifyBeforeEnable: val,
      );
      if (success) {
        biometricEnabled.value = val;
      }
    } else {
      biometricEnabled.value = val;
      box.write('biometric_enabled', val);
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
    } else {
      Get.toNamed('/updateKyc');
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
      barrierColor: Colors.black.withOpacity(0.25),
      barrierDismissible: false,
    );
  }

  Future<void> performLogout() async {
    if (Get.isRegistered<AuthService>()) {
      await AuthService.to.logout();
    }
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.isLocked.value = false;
      AppLockService.to.biometricFailedAttempts.value = 0;
    }
    Get.offAllNamed('/login_singupview');
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
