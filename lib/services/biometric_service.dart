import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:transwallet/products/Dashboard screen/widgets/mpin_verify_sheet.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

/// Error categories for biometric authentication
enum BiometricErrorType {
  notEnrolled,
  passcodeNotSet,
  notAvailable,
  lockedOut,
  permanentlyLockedOut,
  canceled,
  unknown,
}

/// Result object containing status and diagnostic info
class BiometricAuthResult {
  final bool success;
  final String? errorMessage;
  final BiometricErrorType? errorType;

  const BiometricAuthResult({
    required this.success,
    this.errorMessage,
    this.errorType,
  });

  bool get isCanceled => errorType == BiometricErrorType.canceled;
}

/// Centralized production-ready service managing biometric hardware detection,
/// authentication prompts, secure settings persistence, and session unlock.
class BiometricService extends GetxService {
  static BiometricService get to => Get.find<BiometricService>();

  final LocalAuthentication _auth;
  final GetStorage _storage;

  BiometricService({LocalAuthentication? auth, GetStorage? storage})
    : _auth = auth ?? LocalAuthentication(),
      _storage = storage ?? GetStorage();

  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyBiometricQuickLogin = 'biometric_quick_login_enabled';
  static const String _keyEnrolledBiometricsHash = 'enrolled_biometrics_hash';
  static const String _keyDeviceId = 'device_id';

  // Reactive state
  final RxBool isHardwareSupported = false.obs;
  final RxBool canCheckBiometrics = false.obs;
  final RxList<BiometricType> availableBiometrics = <BiometricType>[].obs;
  final RxBool isBiometricEnabled = false.obs;
  final RxBool isAuthenticating = false.obs;
  final RxString deviceId = ''.obs;

  /// Synchronizes in-memory reactive state with persistent storage
  void syncBiometricState() {
    isBiometricEnabled.value = false;
    _storage.write(_keyBiometricEnabled, false);
    _storage.write(_keyBiometricQuickLogin, false);
    _storage.write('pending_biometric_app_lock_prompt', false);
  }

  /// Checks if biometric setup has been completed and enabled by user
  bool get isBiometricSetup => false;

  /// Returns true if biometric quick login is enabled by user
  bool get isBiometricQuickLoginEnabled => false;

  /// Returns true if user has remembered phone or user identifier
  bool get hasRememberedUser {
    final phone =
        _storage.read<String>('remembered_phone') ??
        _storage.read<String>('phone') ??
        _storage.read<String>('mobileNumber') ??
        _storage.read<String>('user_id');
    return (phone != null && phone.isNotEmpty);
  }

  /// Returns true if biometric quick login can be performed on launch
  bool get canQuickLogin => false;

  /// Checks if hardware exists and at least one biometric is enrolled
  bool get isBiometricAvailable => false;

  /// Checks if biometrics can be used for login (available + enabled by user)
  bool get canLoginWithBiometrics => false;

  /// Checks if Face ID / Face recognition is available
  bool get hasFaceId =>
      availableBiometrics.contains(BiometricType.face) ||
      availableBiometrics.contains(BiometricType.weak);

  /// Checks if Fingerprint / Touch ID is available
  bool get hasFingerprint =>
      availableBiometrics.contains(BiometricType.fingerprint) ||
      availableBiometrics.contains(BiometricType.strong);

  /// User-friendly label for current biometric hardware
  String get biometricTypeLabel {
    if (Platform.isIOS) {
      if (hasFaceId && hasFingerprint) return 'Face ID / Touch ID';
      if (hasFaceId) return 'Face ID';
      if (hasFingerprint) return 'Touch ID';
      return 'Face ID';
    }
    // Android and other platforms:
    if (hasFaceId && hasFingerprint) {
      return 'Face Lock or Fingerprint';
    }
    if (hasFaceId) {
      return 'Face Lock';
    }
    if (hasFingerprint) {
      return 'Fingerprint';
    }
    return 'Biometrics';
  }

  /// Appropriate icon for current biometric hardware
  IconData get biometricIcon {
    if (hasFaceId && !hasFingerprint) {
      return Icons.face_rounded;
    }
    if (hasFingerprint && !hasFaceId) {
      return Icons.fingerprint_rounded;
    }
    if (hasFaceId && hasFingerprint) {
      return Icons.fingerprint_rounded;
    }
    return hasFaceId ? Icons.face_rounded : Icons.fingerprint_rounded;
  }

  /// Action prompt adapted to hardware (Face Lock / Face ID / Fingerprint / Touch ID)
  String get biometricActionPrompt {
    if (Platform.isIOS) {
      if (hasFaceId) return 'Scan Face ID to unlock';
      if (hasFingerprint) return 'Touch to scan Touch ID';
      return 'Scan Face ID or touch sensor';
    }
    if (hasFaceId && !hasFingerprint) {
      return 'Scan face to unlock';
    }
    return 'Scan face or touch sensor to unlock';
  }

  /// Secondary helper hint
  String get biometricHint {
    if (Platform.isIOS) {
      if (hasFaceId) return 'Look directly at your phone to unlock';
      return 'Place your registered finger on sensor';
    }
    if (hasFaceId && !hasFingerprint) {
      return 'Look at the front camera to unlock';
    }
    return 'Glance at camera or place finger on sensor';
  }

  /// Returns current platform identifier ("IOS" or "ANDROID")
  String get currentPlatform {
    if (Platform.isIOS) return 'IOS';
    if (Platform.isAndroid) return 'ANDROID';
    return 'UNKNOWN';
  }

  /// Retrieves or generates a persistent deviceId (UUID v4)
  String getOrCreateDeviceId() {
    String? storedId =
        _storage.read<String>(_keyDeviceId) ??
        _storage.read<String>('deviceId');
    if (storedId != null && storedId.isNotEmpty) {
      deviceId.value = storedId;
      return storedId;
    }

    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // Version 4
    values[8] = (values[8] & 0x3f) | 0x80; // Variant 1
    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final newId =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';

    _storage.write(_keyDeviceId, newId);
    _storage.write('deviceId', newId);
    deviceId.value = newId;
    return newId;
  }

  /// Initializes the service and inspects device capabilities
  Future<BiometricService> init() async {
    isBiometricEnabled.value =
        _storage.read<bool>(_keyBiometricEnabled) ??
        _storage.read<bool>(_keyBiometricQuickLogin) ??
        false;
    getOrCreateDeviceId();
    await checkBiometricSupport();
    return this;
  }

  /// Refreshes device capabilities and enrolled biometrics
  Future<void> checkBiometricSupport() async {
    try {
      final supported = await _auth.isDeviceSupported();
      isHardwareSupported.value = supported;

      if (supported) {
        final canCheck = await _auth.canCheckBiometrics;
        canCheckBiometrics.value = canCheck;

        final types = await _auth.getAvailableBiometrics();
        availableBiometrics.assignAll(types);

        // Check if biometric enrollment configuration changed on device
        _verifyBiometricEnrollmentIntegrity(types);
      } else {
        canCheckBiometrics.value = false;
        availableBiometrics.clear();
      }

      developer.log(
        '[BiometricService] Supported: ${isHardwareSupported.value}, '
        'CanCheck: ${canCheckBiometrics.value}, Available: $availableBiometrics',
      );
    } catch (e) {
      developer.log('[BiometricService] Error checking support: $e');
      isHardwareSupported.value = false;
      canCheckBiometrics.value = false;
      availableBiometrics.clear();
    }
  }

  void _verifyBiometricEnrollmentIntegrity(List<BiometricType> currentTypes) {
    final currentHash = currentTypes.map((e) => e.toString()).join(',');
    final savedHash = _storage.read<String>(_keyEnrolledBiometricsHash);

    if (savedHash != null && savedHash.isNotEmpty && savedHash != currentHash) {
      developer.log(
        '⚠️ [BiometricService] Device biometric enrollment changed! Saved: $savedHash, Current: $currentHash. Invalidating quick login for security.',
      );
      // Require re-authentication according to fintech security guidelines
      _storage.write(_keyBiometricQuickLogin, false);
      _storage.write(_keyBiometricEnabled, false);
      isBiometricEnabled.value = false;
      AppSnackbar.warning(
        'Biometric settings changed on your device. Please log in with MPIN/OTP to re-enable biometric login.',
      );
    }
    _storage.write(_keyEnrolledBiometricsHash, currentHash);
  }

  /// User-friendly notifications when biometrics cannot be used
  void notifyBiometricDisabled() {
    HapticFeedback.lightImpact();
    AppSnackbar.info(
      'Biometric authentication is disabled. Please enable it in Profile Settings.',
      title: 'Biometrics Disabled',
    );
  }

  void notifyBiometricUnavailable() {
    HapticFeedback.lightImpact();
    AppSnackbar.info(
      'Biometric authentication is not supported or enrolled on this device.',
      title: 'Biometrics Unavailable',
    );
  }

  /// Prompts user to confirm their MPIN before changing biometric or security settings
  Future<bool> promptMpinConfirmation({
    String title = "Confirm MPIN",
    String subtitle = "Enter your 4-digit MPIN for confirmation",
  }) async {
    return await MpinVerifySheet.show(
      title: title,
      subtitle: subtitle,
    );
  }

  /// Toggle biometric setting with mandatory MPIN verification before enabling
  Future<bool> setBiometricEnabled(
    bool enabled, {
    bool verifyBeforeEnable = true,
  }) async {
    isBiometricEnabled.value = false;
    await _storage.write(_keyBiometricEnabled, false);
    await _storage.write(_keyBiometricQuickLogin, false);
    await _storage.write('pending_biometric_app_lock_prompt', false);
    developer.log('[BiometricService] Biometrics permanently disabled.');
    return false;
  }

  /// Prompts user with a Transwallet-themed dialog to enable biometric login after MPIN creation or setup
  Future<void> promptBiometricPermission(
    BuildContext context, {
    VoidCallback? onComplete,
  }) async {
    await _storage.write('pending_app_lock_prompt', false);
    await _storage.write('pending_biometric_app_lock_prompt', false);
    onComplete?.call();
    return;
  }

  /// Authenticates using native BiometricPrompt (Android) / LocalAuthentication (iOS)
  Future<BiometricAuthResult> authenticate({
    String localizedReason = 'Please authenticate to proceed',
    bool biometricOnly = true,
    bool checkEnabled = true,
  }) async {
    return const BiometricAuthResult(
      success: false,
      errorMessage: 'Biometric authentication is disabled.',
      errorType: BiometricErrorType.notAvailable,
    );
  }

  /// Cancels any currently active biometric authentication session
  Future<void> cancelAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (e) {
      developer.log('[BiometricService] Error stopping authentication: $e');
    }
  }

  /// High-level method: Performs biometric authentication and logs the user in.
  Future<bool> authenticateAndLogin({
    String? mobileNumber,
    String? apiEndpoint,
    Map<String, dynamic>? customPayload,
  }) async {
    return false;
  }
}
