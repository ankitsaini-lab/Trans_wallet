import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:transwallet/products/Dashboard%20screen/dashboardscreen_Controller.dart';
import 'package:transwallet/products/Profile%20screen/profilescreen_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

class ProfileDetailsController extends GetxController {
  final RxString name = "".obs;
  final RxString email = "".obs;
  final RxString phone = "".obs;
  final RxString customerId = "".obs;
  final RxString accountverification = "Verified Account".obs;
  final RxString address = "".obs;
  final RxString profilePictureUrl = "".obs;
  final RxString dob = "".obs;
  final RxString gender = "".obs;
  final RxString panNumber = "".obs;
  final RxString maskedPan = "".obs;

  final RxBool isKycCompleted = false.obs;
  final RxBool isMinKycCompleted = false.obs;
  final RxBool isSimBound = false.obs;
  final RxBool isRefreshing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProfileData();
    refreshProfile(showSnackbar: false);
  }

  void _loadProfileData() {
    name.value = box.read('name')?.toString() ?? "User";
    email.value = box.read('email')?.toString() ?? "";
    profilePictureUrl.value = box.read('profilePictureUrl')?.toString() ?? "";
    dob.value = box.read('dob')?.toString() ?? "";
    gender.value = box.read('gender')?.toString() ?? "";

    // User/Customer ID
    final rawUserId = box.read('userId')?.toString() ??
        box.read('user_id')?.toString() ??
        box.read('uuid')?.toString() ??
        '';
    customerId.value = rawUserId;

    // Phone formatting
    final storedPhone = box.read('phone')?.toString() ??
        box.read('mobileNumber')?.toString() ??
        box.read('user_mobile')?.toString() ??
        '';
    if (storedPhone.isNotEmpty) {
      if (storedPhone.startsWith('+')) {
        phone.value = storedPhone;
      } else if (storedPhone.length == 10) {
        phone.value =
            "+91 ${storedPhone.substring(0, 5)} ${storedPhone.substring(5)}";
      } else {
        phone.value = "+91 $storedPhone";
      }
    } else {
      phone.value = "";
    }

    // Address
    final rawAddress = box.read('address')?.toString() ?? '';
    address.value = rawAddress.isNotEmpty ? rawAddress : "";

    // PAN / Identity Document
    final rawPan = box.read('pan')?.toString() ??
        box.read('document_number')?.toString() ??
        '';
    panNumber.value = rawPan;
    if (rawPan.length == 10) {
      maskedPan.value =
          "${rawPan.substring(0, 5)}****${rawPan.substring(9)}".toUpperCase();
    } else if (rawPan.isNotEmpty) {
      maskedPan.value = rawPan.length > 4
          ? "${rawPan.substring(0, 2)}****${rawPan.substring(rawPan.length - 2)}"
          : rawPan;
    } else {
      maskedPan.value = "";
    }

    // KYC Status
    final bool fullKyc = box.read('is_kyc_completed') == true ||
        box.read('kyc_status')?.toString().toLowerCase() == 'verified' ||
        box.read('kyc_status')?.toString().toLowerCase() == 'completed' ||
        box.read('kyc_status')?.toString().toLowerCase() == 'approved';
    isKycCompleted.value = fullKyc;

    final bool minKyc = !fullKyc &&
        (box.read('min_kyc_completed') == true ||
            box.read('is_min_kyc_completed') == true);
    isMinKycCompleted.value = minKyc;

    if (isKycCompleted.value) {
      accountverification.value = "Full KYC Verified";
    } else if (isMinKycCompleted.value) {
      accountverification.value = "Min KYC Verified";
    } else {
      accountverification.value = "KYC Pending";
    }

    // SIM binding / Device trust
    isSimBound.value = box.read('is_sim_bound') == true ||
        box.read('deepid_sim_binding_verified') == true ||
        box.read('deepid_device_trusted') == true;
  }

  /// Pull-to-refresh & API sync
  Future<void> refreshProfile({bool showSnackbar = false}) async {
    isRefreshing.value = true;
    try {
      if (Get.isRegistered<ApiService>()) {
        final profile = await ApiService.to.fetchUserProfile();
        if (profile != null) {
          _loadProfileData();
          if (showSnackbar) {
            AppSnackbar.success("Profile refreshed successfully!");
          }
          return;
        }
      }
      _loadProfileData();
      if (showSnackbar) {
        AppSnackbar.info("Profile up to date.");
      }
    } catch (e) {
      developer.log('[ProfileDetails] Error refreshing: $e');
      if (showSnackbar) {
        AppSnackbar.error("Could not refresh profile. Please try again.");
      }
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Format Date of Birth to human-readable string (e.g., "15 Aug 1995")
  String get formattedDob {
    if (dob.value.trim().isEmpty) return '';
    try {
      final raw = dob.value.trim();
      if (raw.contains('T')) {
        final dt = DateTime.parse(raw);
        return _formatReadableDate(dt);
      }
      final parts = raw.split(RegExp(r'[-/]'));
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          final dt = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          return _formatReadableDate(dt);
        } else if (parts[2].length == 4) {
          final dt = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          return _formatReadableDate(dt);
        }
      }
    } catch (_) {}
    return dob.value;
  }

  String _formatReadableDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  /// Format Gender to clean display string
  String get formattedGender {
    if (gender.value.trim().isEmpty) return '';
    final g = gender.value.trim().toUpperCase();
    if (g == 'M' || g == 'MALE') return 'Male';
    if (g == 'F' || g == 'FEMALE') return 'Female';
    if (g == 'O' || g == 'OTHER') return 'Other';
    return gender.value;
  }

  /// Upload or change profile picture directly from profile details screen
  Future<void> uploadProfilePicture() async {
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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              "Change Profile Photo",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightprimaryred,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded, color: primaryRed),
              ),
              title: const Text(
                "Choose from Gallery",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightprimaryred,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: primaryRed),
              ),
              title: const Text(
                "Take a Photo",
                style: TextStyle(fontWeight: FontWeight.w600),
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
      try {
        if (source == ImageSource.gallery) {
          final photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted && !photosStatus.isLimited) {
            final storageStatus = await Permission.storage.request();
            if (!storageStatus.isGranted &&
                (photosStatus.isPermanentlyDenied ||
                    storageStatus.isPermanentlyDenied)) {
              _showPermissionDeniedDialog(
                title: "Gallery Permission Required",
                message:
                    "Please grant gallery access to select your profile picture.",
              );
              return;
            }
          }
        } else if (source == ImageSource.camera) {
          final cameraStatus = await Permission.camera.request();
          if (!cameraStatus.isGranted && cameraStatus.isPermanentlyDenied) {
            _showPermissionDeniedDialog(
              title: "Camera Permission Required",
              message:
                  "Please grant camera access to take your profile picture.",
            );
            return;
          }
        }
      } catch (e) {
        developer.log("Permission check handled safely: $e");
      }

      XFile? pickedFile;
      try {
        final picker = ImagePicker();
        pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 85,
        );
      } on PlatformException catch (e) {
        developer.log("ImagePicker PlatformException: ${e.code} - ${e.message}");
        if (e.code == 'photo_access_denied' ||
            e.code == 'camera_access_denied' ||
            e.message?.contains('permission') == true) {
          _showPermissionDeniedDialog(
            title: source == ImageSource.camera
                ? "Camera Permission Required"
                : "Gallery Permission Required",
            message: source == ImageSource.camera
                ? "Camera access was denied. Please allow access in Settings."
                : "Gallery access was denied. Please allow access in Settings.",
          );
        }
        return;
      } catch (e) {
        developer.log("Error picking image: $e");
        return;
      }

      if (pickedFile == null) return;

      // Validate format
      final ext = pickedFile.name.split('.').last.toLowerCase();
      const allowedExts = ['jpg', 'jpeg', 'png', 'webp'];
      if (!allowedExts.contains(ext)) {
        AppSnackbar.error("Invalid format. Allowed formats: JPEG, PNG, WebP");
        return;
      }

      // Validate size (max 2MB)
      final bytes = await pickedFile.readAsBytes();
      const maxSizeBytes = 2 * 1024 * 1024;
      if (bytes.length > maxSizeBytes) {
        AppSnackbar.error("Image size exceeds maximum limit of 2MB");
        return;
      }

      Get.dialog(
        const Center(
          child: CircularProgressIndicator(color: primaryRed),
        ),
        barrierDismissible: false,
      );

      try {
        if (Get.isRegistered<ApiService>()) {
          final newUrl = await ApiService.to.uploadProfilePicture(pickedFile);
          if (Get.isDialogOpen ?? false) Get.back();

          if (newUrl != null && newUrl.isNotEmpty) {
            profilePictureUrl.value = newUrl;
            box.write('profilePictureUrl', newUrl);

            // Synchronize with other active controllers
            if (Get.isRegistered<ProfilescreenController>()) {
              Get.find<ProfilescreenController>().profilePictureUrl.value =
                  newUrl;
            }
            if (Get.isRegistered<DashboardscreenController>()) {
              Get.find<DashboardscreenController>().profilePictureUrl.value =
                  newUrl;
            }

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

  void _showPermissionDeniedDialog({
    required String title,
    required String message,
  }) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Open Settings",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void handleKycAction() {
    if (isKycCompleted.value) {
      AppSnackbar.success("Your Full KYC is already verified and active.");
    } else {
      Get.toNamed('/updateKyc')?.then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadProfileData();
        });
      });
    }
  }

  void copyText(BuildContext context, String text, String label) {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: text));
    AppSnackbar.success("Copied $label to clipboard");
  }
}
