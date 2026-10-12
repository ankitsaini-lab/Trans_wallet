import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/auth_service.dart';
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
  final RxBool isBiometricEnabled = true.obs;
  final RxBool isAuthenticating = false.obs;
  final RxString deviceId = ''.obs;

  /// Synchronizes in-memory reactive state with persistent storage
  void syncBiometricState() {
    final enabled = _storage.read<bool>(_keyBiometricEnabled) ?? false;
    final quickLogin = _storage.read<bool>(_keyBiometricQuickLogin) ?? false;
    isBiometricEnabled.value = enabled || quickLogin;
  }

  /// Checks if biometric setup has been completed and enabled by user
  bool get isBiometricSetup {
    final enabled = _storage.read<bool>(_keyBiometricEnabled) ?? false;
    final quickLogin = _storage.read<bool>(_keyBiometricQuickLogin) ?? false;
    final isEnabledInStorage = enabled || quickLogin;
    if (isBiometricEnabled.value != isEnabledInStorage) {
      isBiometricEnabled.value = isEnabledInStorage;
    }
    return isEnabledInStorage;
  }

  /// Returns true if biometric quick login is enabled by user
  bool get isBiometricQuickLoginEnabled {
    final enabled = _storage.read<bool>(_keyBiometricQuickLogin) ??
        _storage.read<bool>(_keyBiometricEnabled) ??
        false;
    return enabled;
  }

  /// Returns true if user has remembered phone or user identifier
  bool get hasRememberedUser {
    final phone = _storage.read<String>('remembered_phone') ??
        _storage.read<String>('phone') ??
        _storage.read<String>('mobileNumber') ??
        _storage.read<String>('user_id');
    return (phone != null && phone.isNotEmpty);
  }

  /// Returns true if biometric quick login can be performed on launch
  bool get canQuickLogin =>
      isBiometricAvailable && isBiometricSetup && isBiometricQuickLoginEnabled && hasRememberedUser;

  /// Checks if hardware exists and at least one biometric is enrolled
  bool get isBiometricAvailable =>
      isHardwareSupported.value && canCheckBiometrics.value;

  /// Checks if biometrics can be used for login (available + enabled by user)
  bool get canLoginWithBiometrics =>
      isBiometricAvailable && isBiometricSetup;

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

  /// Toggle biometric setting with optional native verification before enabling
  Future<bool> setBiometricEnabled(
    bool enabled, {
    bool verifyBeforeEnable = true,
  }) async {
    if (enabled && verifyBeforeEnable) {
      if (!isBiometricAvailable) {
        AppSnackbar.error(
          'Biometrics is not available or not enrolled on this device',
        );
        return false;
      }

      final result = await authenticate(
        localizedReason: 'Scan to enable $biometricTypeLabel authentication',
      );
      if (!result.success) {
        if (!result.isCanceled && result.errorMessage != null) {
          AppSnackbar.error(result.errorMessage!);
        }
        return false;
      }
    }

    isBiometricEnabled.value = enabled;
    await _storage.write(_keyBiometricEnabled, enabled);
    await _storage.write(_keyBiometricQuickLogin, enabled);
    developer.log('[BiometricService] Biometric enabled set to: $enabled');
    return true;
  }

  /// Prompts user with a Transwallet-themed dialog to enable biometric login after MPIN creation or setup
  Future<void> promptBiometricPermission(
    BuildContext context, {
    VoidCallback? onComplete,
  }) async {
    await checkBiometricSupport();

    if (!isBiometricAvailable) {
      onComplete?.call();
      return;
    }

    final String label = biometricTypeLabel;
    final IconData icon = biometricIcon;

    if (!context.mounted) return;

    const Color primaryRedColor = Color(0xFFED292A);
    const Color textColor = Color(0xFF111111);
    const Color secondaryText = Color(0xFF6B7280);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Colors.white,
          elevation: 12,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Icon Header Container
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: primaryRedColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryRedColor.withValues(alpha: 0.25),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryRedColor.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 36,
                    color: primaryRedColor,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  "Enable $label Login?",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  "Use $label for quick, seamless, and secure access to Transwallet without entering your 4-digit MPIN every time.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: secondaryText,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                // Feature Highlights Badge Container
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFECECEC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: primaryRedColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Bank-grade security with instant biometric unlock",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Enable Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRedColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: primaryRedColor.withValues(alpha: 0.3),
                    ),
                    icon: Icon(icon, size: 20),
                    label: Text(
                      "Enable $label",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      final success = await setBiometricEnabled(
                        true,
                        verifyBeforeEnable: true,
                      );
                      if (success) {
                        AppSnackbar.success("$label enabled successfully");
                      }
                      onComplete?.call();
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Skip Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: secondaryText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Skip for Now",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await setBiometricEnabled(
                        false,
                        verifyBeforeEnable: false,
                      );
                      onComplete?.call();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Authenticates using native BiometricPrompt (Android) / LocalAuthentication (iOS)
  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
    bool biometricOnly = true,
  }) async {
    if (isAuthenticating.value) {
      developer.log('[BiometricService] Authentication already in progress');
      return const BiometricAuthResult(
        success: false,
        errorMessage: 'Authentication already in progress',
        errorType: BiometricErrorType.unknown,
      );
    }

    try {
      isAuthenticating.value = true;

      // Re-verify support
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;

      if (!supported || !canCheck) {
        return const BiometricAuthResult(
          success: false,
          errorMessage:
              'Biometric authentication is not supported or set up on this device.',
          errorType: BiometricErrorType.notAvailable,
        );
      }

      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: biometricOnly,
      );

      if (authenticated) {
        developer.log('[BiometricService] Authentication successful');
        return const BiometricAuthResult(success: true);
      } else {
        developer.log('[BiometricService] Authentication canceled or failed');
        return const BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.canceled,
        );
      }
    } on PlatformException catch (e) {
      developer.log(
        '[BiometricService] PlatformException: ${e.code} - ${e.message}',
      );
      return _mapPlatformException(e);
    } catch (e) {
      developer.log('[BiometricService] Unexpected error: $e');
      return BiometricAuthResult(
        success: false,
        errorMessage: 'An unexpected biometric error occurred: $e',
        errorType: BiometricErrorType.unknown,
      );
    } finally {
      isAuthenticating.value = false;
    }
  }

  /// Cancels any currently active biometric authentication session
  Future<void> cancelAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (e) {
      developer.log('[BiometricService] Error stopping authentication: $e');
    }
  }

  /// Maps native platform exception codes to user-friendly diagnostics
  BiometricAuthResult _mapPlatformException(PlatformException e) {
    final code = e.code.toLowerCase();
    if (code.contains('notenrolled')) {
      return const BiometricAuthResult(
        success: false,
        errorMessage:
            'No biometric credentials enrolled. Please register your fingerprint or Face ID in device settings.',
        errorType: BiometricErrorType.notEnrolled,
      );
    } else if (code.contains('passcodenotset')) {
      return const BiometricAuthResult(
        success: false,
        errorMessage:
            'Device passcode or screen lock is not set. Please set a screen lock first.',
        errorType: BiometricErrorType.passcodeNotSet,
      );
    } else if (code.contains('notavailable')) {
      return const BiometricAuthResult(
        success: false,
        errorMessage: 'Biometric hardware is currently not available.',
        errorType: BiometricErrorType.notAvailable,
      );
    } else if (code.contains('permanentlylockedout')) {
      return const BiometricAuthResult(
        success: false,
        errorMessage:
            'Biometric authentication locked out permanently. Please unlock with your device PIN or password.',
        errorType: BiometricErrorType.permanentlyLockedOut,
      );
    } else if (code.contains('lockedout')) {
      return const BiometricAuthResult(
        success: false,
        errorMessage:
            'Biometric authentication temporarily locked due to multiple failed attempts. Try again in 30 seconds.',
        errorType: BiometricErrorType.lockedOut,
      );
    } else if (code.contains('cancel')) {
      return const BiometricAuthResult(
        success: false,
        errorType: BiometricErrorType.canceled,
      );
    } else {
      return BiometricAuthResult(
        success: false,
        errorMessage: e.message ?? 'Biometric verification failed',
        errorType: BiometricErrorType.unknown,
      );
    }
  }

  /// High-level method: Performs biometric authentication and logs the user in.
  /// 1. Prompts user with native biometric scanner (Face ID / Touch ID / Fingerprint).
  /// 2. Executes API login call if endpoint or stored MPIN credentials are available.
  Future<bool> authenticateAndLogin({
    String? mobileNumber,
    String? apiEndpoint,
    Map<String, dynamic>? customPayload,
  }) async {
    final phone = mobileNumber ?? _storage.read<String>('phone');

    // 1. Perform native biometric prompt (Face ID / Touch ID / Fingerprint)
    final result = await authenticate(
      localizedReason:
          'Log in with $biometricTypeLabel to access your Transwallet',
    );

    if (!result.success) {
      if (!result.isCanceled && result.errorMessage != null) {
        AppSnackbar.error(result.errorMessage!);
      }
      return false;
    }

    // 2. Custom API endpoint if provided
    if (apiEndpoint != null && apiEndpoint.isNotEmpty) {
      try {
        final payload =
            customPayload ?? {'phone': phone, 'biometricVerified': true};
        final response = await ApiService.to.postRequest<Map<String, dynamic>>(
          apiEndpoint,
          payload,
        );
        if (response.status.isOk && response.body != null) {
          final body = response.body!;
          if (body['success'] == true || body['code'] == 'OK') {
            final data = body['data'];
            if (data is Map) {
              final token =
                  data['accessToken']?.toString() ?? data['token']?.toString();
              if (token != null) {
                await AuthService.to.saveSession(
                  token: token,
                  refreshToken: data['refreshToken']?.toString(),
                  tokenType: data['tokenType']?.toString() ?? 'Bearer',
                  expiresIn: data['expiresIn'],
                  userId: phone ?? 'user',
                );
              }
            }
            AppSnackbar.success('Biometric login successful');
            Get.offAllNamed('/dashboard');
            return true;
          }
        }
        AppSnackbar.error('Server error. Please try again after some time.');
        return false;
      } catch (e) {
        developer.log('[BiometricService] Custom API error: $e');
        AppSnackbar.error('Server error. Please try again after some time.');
        return false;
      }
    }

    // 3. Authenticate returning user session using saved MPIN & stored mobile number
    final rawPhone = mobileNumber ??
        _storage.read<String>('remembered_phone') ??
        _storage.read<String>('phone') ??
        _storage.read<String>('mobileNumber') ??
        _storage.read<String>('user_id') ??
        '';

    // Clean phone number to 10 digits for API if needed
    String cleanPhone = rawPhone
        .replaceAll('+91', '')
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .trim();
    if (cleanPhone.length > 10) {
      cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
    }

    final savedPhone = cleanPhone.isNotEmpty ? cleanPhone : rawPhone;
    final savedMpin = _storage.read<String>('saved_mpin') ??
        _storage.read<String>('remembered_mpin') ??
        _storage.read<String>('mpin');

    if (savedPhone.isNotEmpty && savedMpin != null && savedMpin.isNotEmpty) {
      try {
        developer.log(
          '[BiometricService] Calling /api/v1/auth/mpin/login with phone: $savedPhone',
        );
        final response = await ApiService.to.postRequest<Map<String, dynamic>>(
          '/api/v1/auth/mpin/login',
          {"mobileNumber": savedPhone, "mpin": savedMpin},
        );

        if (response.status.isOk && response.body != null) {
          final body = response.body!;
          final bool isSuccess =
              body['success'] == true || body['code'] == 'OK';

          if (isSuccess) {
            final data = body['data'];
            if (data is Map) {
              final accessToken =
                  data['accessToken']?.toString() ??
                  data['token']?.toString() ??
                  data['authToken']?.toString();
              final refreshToken = data['refreshToken']?.toString();
              final tokenType = data['tokenType']?.toString() ?? 'Bearer';
              final expiresIn = data['expiresIn'];

              // Extract user details
              final Map userMap = (data['user'] is Map)
                  ? (data['user'] as Map)
                  : data;
              final String extractedName =
                  userMap['name']?.toString() ??
                  userMap['fullName']?.toString() ??
                  '${userMap['firstName'] ?? ''} ${userMap['lastName'] ?? ''}'
                      .trim();

              if (extractedName.isNotEmpty) {
                _storage.write('name', extractedName);
                _storage.write('remembered_name', extractedName);
              }
              if (userMap['email'] != null) {
                _storage.write('email', userMap['email']);
              }
              if (userMap['profilePictureUrl'] != null) {
                _storage.write(
                  'profilePictureUrl',
                  userMap['profilePictureUrl'],
                );
              }

              if (accessToken != null && accessToken.isNotEmpty) {
                _storage.write('accessToken', accessToken);
                _storage.write('auth_token', accessToken);
                _storage.write('token', accessToken);
              }
              if (refreshToken != null && refreshToken.isNotEmpty) {
                _storage.write('refreshToken', refreshToken);
                _storage.write('refresh_token', refreshToken);
              }
              if (tokenType.isNotEmpty) _storage.write('tokenType', tokenType);
              if (expiresIn != null) _storage.write('expiresIn', expiresIn);

              await AuthService.to.saveSession(
                token: accessToken ?? '',
                refreshToken: refreshToken,
                tokenType: tokenType,
                expiresIn: expiresIn,
                userId: savedPhone,
                userData: Map<String, dynamic>.from(userMap),
              );
            }

            _storage.write('phone', savedPhone);
            _storage.write('remembered_phone', savedPhone);
            _storage.write('saved_mpin', savedMpin);
            _storage.write('remembered_mpin', savedMpin);
            _storage.write('is_logged_in', true);
            AppSnackbar.success('Biometric login successful');
            Get.offAllNamed('/dashboard');
            return true;
          } else {
            final errorMsg =
                body['message']?.toString() ??
                body['error']?.toString() ??
                "Biometric authentication failed";
            AppSnackbar.error(errorMsg);
            return false;
          }
        }
      } catch (e) {
        developer.log('[BiometricService] MPIN re-auth failed: $e');
      }
    }

    // Fallback: If native biometric scan succeeded on trusted device, restore session locally
    if (savedPhone.isNotEmpty) {
      _storage.write('phone', savedPhone);
      _storage.write('remembered_phone', savedPhone);
      _storage.write('is_logged_in', true);
      AppSnackbar.success('Biometric login successful');
      Get.offAllNamed('/dashboard');
      return true;
    }

    AppSnackbar.warning(
      'Please log in once with mobile number/MPIN to enable biometric login.',
    );
    return false;
  }
}
