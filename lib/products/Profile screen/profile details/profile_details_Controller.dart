import 'dart:developer' as developer;
import 'dart:io';
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
import 'package:transwallet/services/auth_service.dart';
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
  final Rxn<File> localImageFile = Rxn<File>();
  final RxString dob = "".obs;
  final RxString gender = "".obs;
  final RxString panNumber = "".obs;
  final RxString maskedPan = "".obs;

  final RxBool isKycCompleted = false.obs;
  final RxBool isMinKycCompleted = false.obs;
  final RxBool isKycUnderReview = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isUploadingImage = false.obs;

  void clear() {
    name.value = "";
    email.value = "";
    phone.value = "";
    customerId.value = "";
    accountverification.value = "Verified Account";
    address.value = "";
    profilePictureUrl.value = "";
    localImageFile.value = null;
    dob.value = "";
    gender.value = "";
    panNumber.value = "";
    maskedPan.value = "";
    isKycCompleted.value = false;
    isMinKycCompleted.value = false;
    isKycUnderReview.value = false;
    isRefreshing.value = false;
    isUploadingImage.value = false;
  }

  bool get _canFetchProfile {
    final bool loggedIn = (box.read<bool>('is_logged_in') ?? false) &&
        (box.read<String>('accessToken') != null ||
            box.read<String>('auth_token') != null);
    final bool isLoggingOut =
        (Get.isRegistered<AuthService>() && AuthService.to.isLoggingOut) ||
        (Get.isRegistered<ApiService>() && ApiService.to.isLoggingOut);
    return loggedIn && !isLoggingOut;
  }

  @override
  void onInit() {
    super.onInit();
    _loadProfileData();
    if (_canFetchProfile) {
      refreshProfile(showSnackbar: false);
      _checkLostData();
    }
  }

  Future<void> _checkLostData() async {
    // 1. Check if fast-restore from Splash recovered the image
    final recoveredPath = box.read<String>('recovered_camera_image');
    if (recoveredPath != null && recoveredPath.isNotEmpty) {
      box.remove('recovered_camera_image');
      final file = File(recoveredPath);
      if (await file.exists()) {
        developer.log(
          "[ProfileDetails] Found recovered camera image from fast restore: $recoveredPath",
        );
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
        developer.log(
          "[ProfileDetails] Recovered lost image from camera: ${response.file!.path}",
        );
        box.remove('pending_camera_upload');
        await _processAndUploadFile(response.file!);
      } else if (response.files != null && response.files!.isNotEmpty) {
        developer.log(
          "[ProfileDetails] Recovered lost image from camera: ${response.files!.first.path}",
        );
        box.remove('pending_camera_upload');
        await _processAndUploadFile(response.files!.first);
      } else if (response.exception != null) {
        developer.log(
          "[ProfileDetails] LostDataResponse exception: ${response.exception}",
        );
      }
    } catch (e) {
      developer.log("[ProfileDetails] Error retrieving lost data: $e");
    }
  }

  void _loadProfileData() {
    name.value = box.read('name')?.toString() ?? "User";
    email.value = box.read('email')?.toString() ?? "";
    profilePictureUrl.value = box.read('profilePictureUrl')?.toString() ?? "";
    dob.value = box.read('dob')?.toString() ?? "";
    gender.value = box.read('gender')?.toString() ?? "";

    // User/Customer ID
    final rawUserId =
        box.read('userId')?.toString() ??
        box.read('user_id')?.toString() ??
        box.read('uuid')?.toString() ??
        '';
    customerId.value = rawUserId;

    // Phone formatting
    final storedPhone =
        box.read('phone')?.toString() ??
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
    final rawPan =
        box.read('pan')?.toString() ??
        box.read('document_number')?.toString() ??
        '';
    panNumber.value = rawPan;
    if (rawPan.length == 10) {
      maskedPan.value = "${rawPan.substring(0, 5)}****${rawPan.substring(9)}"
          .toUpperCase();
    } else if (rawPan.isNotEmpty) {
      maskedPan.value = rawPan.length > 4
          ? "${rawPan.substring(0, 2)}****${rawPan.substring(rawPan.length - 2)}"
          : rawPan;
    } else {
      maskedPan.value = "";
    }

    // KYC Status
    final rawKycStatus = box.read('kyc_status')?.toString().toLowerCase() ?? '';
    final bool fullKyc =
        box.read('full_kyc_completed') == true ||
        box.read('is_kyc_completed') == true ||
        rawKycStatus == 'verified' ||
        rawKycStatus == 'completed' ||
        rawKycStatus == 'approved';
    isKycCompleted.value = fullKyc;
    isKycUnderReview.value = false;

    final bool minKyc =
        !fullKyc &&
        (box.read('min_kyc_completed') == true ||
            box.read('is_min_kyc_completed') == true);
    isMinKycCompleted.value = minKyc;

    if (isKycCompleted.value) {
      accountverification.value = "Full KYC Verified";
    } else if (isKycUnderReview.value) {
      accountverification.value = "VKYC Under Review";
    } else if (isMinKycCompleted.value) {
      accountverification.value = "Min KYC Verified";
    } else {
      accountverification.value = "KYC Pending";
    }
  }

  /// Pull-to-refresh & API sync
  Future<void> refreshProfile({
    bool force = false,
    bool showSnackbar = false,
  }) async {
    if (!_canFetchProfile) return;
    isRefreshing.value = true;
    try {
      if (Get.isRegistered<ApiService>()) {
        final profile = await ApiService.to.fetchUserProfile(force: force);
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
    if (g == 'O' || g == 'OTHER') return 'Other';
    return gender.value;
  }

  /// Upload or change profile picture directly from profile details screen
  Future<void> uploadProfilePicture([BuildContext? context]) async {
    final ImageSource? source;
    if (context != null && context.mounted) {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
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
                const SizedBox(height: 10),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: lightprimaryred,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: primaryRed,
                    ),
                  ),
                  title: const Text(
                    "Choose from Gallery",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: lightprimaryred,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: primaryRed,
                    ),
                  ),
                  title: const Text(
                    "Take a Photo",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.camera),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      source = await Get.bottomSheet<ImageSource>(
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
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: lightprimaryred,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: primaryRed,
                  ),
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
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: primaryRed,
                  ),
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
    }

    if (source == null) return;

    // Allow bottomsheet modal transition to finish cleanly before camera activity launches
    await Future.delayed(const Duration(milliseconds: 200));

    if (isUploadingImage.value) return;
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
      // Record pending upload so if Android restarts the activity, route is restored
      box.write('pending_camera_upload', 'profile_details');

      XFile? pickedFile;
      try {
        final picker = ImagePicker();
        // Downscale to 800x800 at 75% quality to prevent Android LMK process death
        // Do NOT pass preferredCameraDevice: CameraDevice.front as it crashes MIUI/OEM camera intents
        pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 75,
        );
      } on PlatformException catch (e) {
        developer.log(
          "ImagePicker PlatformException: ${e.code} - ${e.message}",
        );
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
          // Retry with standard picker if OEM camera crashed on parameters
          try {
            final fallbackPicker = ImagePicker();
            pickedFile = await fallbackPicker.pickImage(
              source: source,
              maxWidth: 800,
              maxHeight: 800,
              imageQuality: 75,
            );
          } catch (retryError) {
            developer.log("Fallback camera pick failed: $retryError");
            AppSnackbar.error(
              "Failed to capture image: ${e.message ?? e.code}",
            );
          }
        }
        if (pickedFile == null) return;
      } catch (e) {
        developer.log(
          "Error picking image: $e, attempting standard fallback...",
        );
        try {
          final fallbackPicker = ImagePicker();
          pickedFile = await fallbackPicker.pickImage(
            source: source,
            maxWidth: 800,
            maxHeight: 800,
            imageQuality: 75,
          );
        } catch (retryError) {
          developer.log("Fallback camera pick failed: $retryError");
          AppSnackbar.error("Unable to pick image. Please try again.");
          return;
        }
      }

      if (pickedFile == null) {
        developer.log("[ProfileDetails] User cancelled image selection.");
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

        if (result.isSuccess && result.url != null && result.url!.isNotEmpty) {
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
      developer.log("[ProfileDetails] Upload error: $e");
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
    if (Get.isRegistered<ProfilescreenController>()) {
      final prof = Get.find<ProfilescreenController>();
      prof.profilePictureUrl.value = newUrl;
      prof.localImageFile.value = null;
      prof.profilePictureUrl.refresh();
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
    } else if (isKycUnderReview.value) {
      AppSnackbar.info(
        "Your Video KYC is currently under review. Verification typically completes within 24–48 hours.",
      );
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
