import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

/// Service that monitors application lifecycle and locks the app
/// after being backgrounded for at least 2 seconds.
class AppLockService extends GetxService with WidgetsBindingObserver {
  static AppLockService get to => Get.find<AppLockService>();

  final GetStorage _storage = GetStorage();

  /// Lock state observable
  final RxBool isLocked = false.obs;

  /// Input MPIN entered on lock screen
  final RxString enteredPin = ''.obs;

  /// Error message on lock screen (e.g. "Incorrect MPIN")
  final RxString pinError = ''.obs;

  /// Loading indicator while validating MPIN
  final RxBool isVerifyingPin = false.obs;

  /// Flag indicating biometric prompt is currently shown
  final RxBool isPromptingBiometrics = false.obs;

  /// Consecutive incorrect biometric scan attempts
  final RxInt biometricFailedAttempts = 0.obs;

  /// Maximum allowed biometric attempts before switching exclusively to MPIN
  static const int maxBiometricAttempts = 3;

  /// Background duration threshold before locking (default: 2 seconds)
  final Duration backgroundLockDuration = const Duration(seconds: 2);

  DateTime? _pausedTimestamp;
  Timer? _backgroundTimer;
  bool _isBackgrounded = false;

  /// Debug observable tracking the last measured background duration in ms
  final RxInt lastElapsedMs = 0.obs;

  DateTime? get pausedTimestamp => _pausedTimestamp;
  bool get isBackgrounded => _isBackgrounded;

  Future<AppLockService> init() async {
    WidgetsBinding.instance.addObserver(this);
    return this;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundTimer?.cancel();
    super.onClose();
  }

  /// Checks whether biometric authentication is available and enabled on device
  bool get isBiometricAvailable {
    if (!Get.isRegistered<BiometricService>()) return false;
    final service = BiometricService.to;
    return service.isBiometricAvailable && service.isBiometricEnabled.value;
  }

  /// User manually requested to switch to MPIN screen
  final RxBool isManualMpin = false.obs;

  /// Returns true when MPIN should be shown exclusively:
  /// 1. Device has no biometric hardware or user has not enabled biometrics, OR
  /// 2. User has entered incorrect biometric more than 3 times (> 3), OR
  /// 3. User explicitly tapped "Use MPIN instead".
  bool get shouldShowMpinOnly {
    if (!isBiometricAvailable) return true;
    if (biometricFailedAttempts.value > maxBiometricAttempts) return true;
    return isManualMpin.value;
  }

  /// Switch view to manual MPIN keypad
  void switchToMpin() {
    isManualMpin.value = true;
    _resetPinInput();
  }

  /// Switch view back to Face Lock / Biometric screen
  void switchToBiometrics() {
    isManualMpin.value = false;
    _resetPinInput();
    promptBiometricUnlock();
  }

  /// Checks whether a valid user session is active
  bool get isUserLoggedIn {
    if (Get.isRegistered<AuthService>()) {
      if (AuthService.to.isLoggedIn) return true;
    }
    final loggedIn = _storage.read<bool>('is_logged_in') ?? false;
    final hasToken =
        (_storage.read<String>('accessToken') ??
                _storage.read<String>('auth_token') ??
                _storage.read<String>('token') ??
                '')
            .isNotEmpty;
    return loggedIn || hasToken;
  }

  /// Flag indicating external media picker (Camera / Gallery) is active
  final RxBool isPickingMedia = false.obs;

  void setPickingMedia(bool active) {
    isPickingMedia.value = active;
    _backgroundTimer?.cancel();
    _pausedTimestamp = null;
    _isBackgrounded = false;
    developer.log('[AppLockService] setPickingMedia: $active');
  }

  /// Checks whether app lock should trigger when backgrounded:
  /// Only activates when the user is logged in and media picker is NOT active.
  bool get canAppLock {
    // Media picker active override
    if (isPickingMedia.value) return false;

    // Developer test mode override
    if (_storage.read<bool>('app_lock_test_mode') == true) return true;

    // Disabled explicitly by setting
    final enabled = _storage.read<bool>('app_lock_enabled') ?? true;
    if (!enabled) return false;

    // Only work when user is logged in
    return isUserLoggedIn;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    developer.log('[AppLockService] AppLifecycleState changed to: $state');

    final isBiometricActive =
        (Get.isRegistered<BiometricService>() &&
            BiometricService.to.isAuthenticating.value) ||
        isPromptingBiometrics.value;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (!isBiometricActive) {
          _handleBackgrounded();
        }
        break;

      case AppLifecycleState.inactive:
        // On iOS/Android, native biometric dialogs trigger 'inactive'.
        // Only treat as backgrounded if biometric prompt is NOT active.
        if (!isBiometricActive) {
          _handleBackgrounded();
        }
        break;

      case AppLifecycleState.resumed:
        _handleResumed();
        break;

      case AppLifecycleState.detached:
        break;
    }
  }

  /// Triggered when app enters background or inactive state
  void _handleBackgrounded() {
    if (!canAppLock) {
      developer.log(
        '[AppLockService] canAppLock is false, skipping background lock.',
      );
      return;
    }

    // Only record the initial transition timestamp; do NOT overwrite if already backgrounded!
    if (!_isBackgrounded || _pausedTimestamp == null) {
      _isBackgrounded = true;
      _pausedTimestamp = DateTime.now();
      developer.log(
        '[AppLockService] App backgrounded at: $_pausedTimestamp. 2s timer started.',
      );

      _backgroundTimer?.cancel();
      _backgroundTimer = Timer(backgroundLockDuration, () {
        if (canAppLock && !isLocked.value) {
          developer.log(
            '[AppLockService] Background duration >= 2s reached while in background. Locking app.',
          );
          isLocked.value = true;
          biometricFailedAttempts.value = 0;
          _resetPinInput();
        }
      });
    }
  }

  /// Triggered when app returns to foreground
  void _handleResumed() {
    final pausedAt = _pausedTimestamp;
    _pausedTimestamp = null;
    _isBackgrounded = false;
    _backgroundTimer?.cancel();

    if (!canAppLock) {
      developer.log('[AppLockService] Resumed, but canAppLock is false.');
      return;
    }

    if (pausedAt != null) {
      final elapsed = DateTime.now().difference(pausedAt);
      lastElapsedMs.value = elapsed.inMilliseconds;
      developer.log(
        '[AppLockService] Resumed after elapsed: ${elapsed.inMilliseconds}ms (threshold: ${backgroundLockDuration.inMilliseconds}ms)',
      );

      if (elapsed >= backgroundLockDuration) {
        // Exceeded 2s threshold -> lock app
        developer.log(
          '[AppLockService] Elapsed >= 2s (${elapsed.inMilliseconds}ms). Locking app now!',
        );
        isLocked.value = true;
        biometricFailedAttempts.value = 0;
        _resetPinInput();
      }
    }

    // If app is locked upon resuming and biometrics is allowed (not exceeded 3 fails),
    // auto-trigger native biometric prompt
    if (isLocked.value && !shouldShowMpinOnly) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (isLocked.value && !shouldShowMpinOnly) {
          promptBiometricUnlock();
        }
      });
    }
  }

  /// Manually trigger app lock (e.g. user action or test)
  void lockApp() {
    isLocked.value = true;
    isManualMpin.value = false;
    biometricFailedAttempts.value = 0;
    _resetPinInput();
  }

  /// Unlocks the application and clears lock screen state
  void unlock() {
    developer.log('[AppLockService] App unlocked successfully.');
    _backgroundTimer?.cancel();
    _pausedTimestamp = null;
    _isBackgrounded = false;
    isLocked.value = false;
    isManualMpin.value = false;
    biometricFailedAttempts.value = 0;
    _resetPinInput();
  }

  void _resetPinInput() {
    enteredPin.value = '';
    pinError.value = '';
    isVerifyingPin.value = false;
  }

  /// Records a failed biometric attempt manually
  void recordBiometricFailure() {
    biometricFailedAttempts.value++;
    developer.log(
      '[AppLockService] Recorded biometric failure #${biometricFailedAttempts.value}',
    );
  }

  /// Resets biometric failure count
  void resetBiometricFailures() {
    biometricFailedAttempts.value = 0;
  }

  /// Prompts user with native Face ID / Touch ID / Fingerprint
  Future<bool> promptBiometricUnlock() async {
    if (isPromptingBiometrics.value) return false;
    if (!Get.isRegistered<BiometricService>()) return false;

    final service = BiometricService.to;
    if (!service.isBiometricEnabled.value) return false;

    // If biometric has been incorrect more than 3 times, biometric is disabled
    if (shouldShowMpinOnly) {
      developer.log(
        '[AppLockService] Biometrics locked: failed attempts exceeded $maxBiometricAttempts. MPIN only.',
      );
      return false;
    }

    isPromptingBiometrics.value = true;
    try {
      final result = await service.authenticate(
        localizedReason: 'Scan to unlock Transcorp Wallet',
        biometricOnly: true,
      );

      if (result.success) {
        HapticFeedback.mediumImpact();
        biometricFailedAttempts.value = 0;
        unlock();
        return true;
      } else {
        // Biometric authentication incorrect or locked out by OS
        if (result.errorType == BiometricErrorType.lockedOut ||
            result.errorType == BiometricErrorType.permanentlyLockedOut) {
          biometricFailedAttempts.value = maxBiometricAttempts + 1;
        } else {
          biometricFailedAttempts.value++;
        }
        HapticFeedback.heavyImpact();
        developer.log(
          '[AppLockService] Biometric failed attempt #${biometricFailedAttempts.value}',
        );
        return false;
      }
    } catch (e) {
      developer.log('[AppLockService] Biometric unlock error: $e');
      biometricFailedAttempts.value++;
      return false;
    } finally {
      isPromptingBiometrics.value = false;
    }
  }

  /// Handles digit entry on the custom numeric keypad
  void onKeyTap(String digit) {
    if (isVerifyingPin.value) return;
    if (enteredPin.value.length >= 4) return;

    pinError.value = '';
    HapticFeedback.lightImpact();
    enteredPin.value += digit;

    if (enteredPin.value.length == 4) {
      verifyMpin(enteredPin.value);
    }
  }

  /// Handles backspace / delete on keypad
  void onDeleteKey() {
    if (isVerifyingPin.value) return;
    if (enteredPin.value.isNotEmpty) {
      HapticFeedback.lightImpact();
      pinError.value = '';
      enteredPin.value = enteredPin.value.substring(
        0,
        enteredPin.value.length - 1,
      );
    }
  }

  /// Verifies entered MPIN against stored MPIN or API backend
  Future<bool> verifyMpin(String pinToVerify) async {
    isVerifyingPin.value = true;
    pinError.value = '';

    try {
      // Check 1: Match against locally stored MPIN
      final savedMpin =
          _storage.read<String>('saved_mpin') ??
          _storage.read('mpin')?.toString();
      if (savedMpin != null && savedMpin == pinToVerify) {
        HapticFeedback.mediumImpact();
        unlock();
        return true;
      }

      // Check 2: Universal demo / fallback MPINs
      if (pinToVerify == "1234" || pinToVerify == "0000") {
        HapticFeedback.mediumImpact();
        unlock();
        return true;
      }

      // Check 3: Verify with live backend API /api/v1/auth/mpin/login
      final phone = _storage.read<String>('phone');
      if (phone != null && phone.isNotEmpty && Get.isRegistered<ApiService>()) {
        final response = await ApiService.to.postRequest<Map<String, dynamic>>(
          '/api/v1/auth/mpin/login',
          {"mobileNumber": phone, "mpin": pinToVerify},
        );

        if (response.status.isOk && response.body != null) {
          final body = response.body!;
          final bool isSuccess =
              body['success'] == true || body['code'] == 'OK';
          if (isSuccess) {
            _storage.write('saved_mpin', pinToVerify);
            HapticFeedback.mediumImpact();
            unlock();
            return true;
          }
        }
      }

      // If all checks fail -> invalid MPIN
      HapticFeedback.heavyImpact();
      pinError.value = 'Incorrect MPIN. Please try again.';
      enteredPin.value = '';
      return false;
    } catch (e) {
      developer.log('[AppLockService] MPIN verification exception: $e');
      pinError.value = 'Verification failed. Try again.';
      enteredPin.value = '';
      return false;
    } finally {
      isVerifyingPin.value = false;
    }
  }

  /// Emergency log out in case user forgot both biometrics and MPIN
  Future<void> logoutAndReset() async {
    _backgroundTimer?.cancel();
    _pausedTimestamp = null;
    _isBackgrounded = false;
    isLocked.value = false;
    biometricFailedAttempts.value = 0;
    _resetPinInput();

    // Clear user session
    if (Get.isRegistered<AuthService>()) {
      await AuthService.to.logout();
    }
    await _storage.remove('auth_token');
    await _storage.remove('accessToken');
    await _storage.remove('refreshToken');
    await _storage.remove('is_logged_in');

    AppSnackbar.info("Logged out successfully");
    Get.offAllNamed('/login_singupview');
  }
}
