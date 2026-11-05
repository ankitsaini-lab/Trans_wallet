import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:transwallet/products/login_singupscreen/login_singupscreen_Controller.dart';
import 'package:transwallet/products/Profile screen/profilescreen_Controller.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/custombutton.dart';

enum ExternalFlowType {
  none,
  payment, // PayU Checkout / Payment Gateway
  vkyc, // VKYC WebView, camera/video, redirect/callback
  mediaPicker, // Camera / Gallery picker
  customWebview, // Approved secure WebView
  externalBrowser, // External browser URL flow
}

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

  /// Returns configured App Lock timeout in seconds (Default: 5 seconds)
  int get appLockTimeoutSeconds =>
      _storage.read<int>('app_lock_timeout_seconds') ?? 5;

  /// Background duration threshold before locking (Default: 5 seconds)
  Duration get backgroundLockDuration =>
      Duration(seconds: appLockTimeoutSeconds);

  /// Configures the lock timeout (0 = Immediate, 30 = 30s, 60 = 1m, 300 = 5m)
  void setAppLockTimeout(int seconds) {
    _storage.write('app_lock_timeout_seconds', seconds);
    developer.log('[AppLockService] Set app lock timeout to $seconds seconds');
  }

  /// Returns whether App Lock is enabled (Defaults to false)
  bool get isAppLockEnabled => _storage.read<bool>('app_lock_enabled') ?? false;

  /// Toggles App Lock setting
  void setAppLockEnabled(bool enabled) {
    _storage.write('app_lock_enabled', enabled);
    if (!enabled) {
      isLocked.value = false;
      _backgroundTimer?.cancel();
      _pausedTimestamp = null;
      _isBackgrounded = false;
      enteredPin.value = '';
      pinError.value = '';
    }
    developer.log('[AppLockService] Set app lock enabled to $enabled');
  }

  DateTime? _pausedTimestamp;
  Timer? _backgroundTimer;
  bool _isBackgrounded = false;

  /// Debug observable tracking the last measured background duration in ms
  final RxInt lastElapsedMs = 0.obs;

  DateTime? get pausedTimestamp => _pausedTimestamp;
  bool get isBackgrounded => _isBackgrounded;

  /// Centralized set of active external secure flow types
  final RxSet<ExternalFlowType> activeExternalFlows = <ExternalFlowType>{}.obs;

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

  /// Start an external secure flow (Payment, VKYC, MediaPicker, etc.)
  void startExternalFlow(ExternalFlowType flow) {
    if (flow == ExternalFlowType.none) return;
    activeExternalFlows.add(flow);
    _backgroundTimer?.cancel();
    _pausedTimestamp = null;
    _isBackgrounded = false;
    developer.log(
      '[AppLockService] External secure flow STARTED: $flow (Active flows: ${activeExternalFlows.toList()})',
    );
  }

  /// Finish an external secure flow
  void finishExternalFlow(ExternalFlowType flow) {
    if (flow == ExternalFlowType.none) return;
    activeExternalFlows.remove(flow);
    // CRITICAL: Any background time that occurred during the external secure flow
    // was authorized and must NOT trigger an immediate app lock upon returning.
    _pausedTimestamp = null;
    _backgroundTimer?.cancel();
    _isBackgrounded = false;
    developer.log(
      '[AppLockService] External secure flow FINISHED: $flow (Remaining active flows: ${activeExternalFlows.toList()})',
    );
  }

  /// Clear all active external secure flows
  void clearAllExternalFlows() {
    activeExternalFlows.clear();
    _pausedTimestamp = null;
    _backgroundTimer?.cancel();
    _isBackgrounded = false;
    developer.log('[AppLockService] Cleared all active external secure flows.');
  }

  /// Checks whether an external secure flow is currently active
  bool isExternalFlowActive([ExternalFlowType? flow]) {
    if (_storage.read<bool>('is_picking_media') == true) {
      if (flow == null || flow == ExternalFlowType.mediaPicker) return true;
    }
    if (flow != null) return activeExternalFlows.contains(flow);
    return activeExternalFlows.isNotEmpty;
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
    _storage.write('is_picking_media', active);
    if (active) {
      startExternalFlow(ExternalFlowType.mediaPicker);
    } else {
      finishExternalFlow(ExternalFlowType.mediaPicker);
    }
    developer.log('[AppLockService] setPickingMedia: $active');
  }

  /// Flag indicating payment flow / PG SDK is active
  final RxBool isPaymentFlowActive = false.obs;

  void setPaymentFlowActive(bool active) {
    isPaymentFlowActive.value = active;
    if (active) {
      startExternalFlow(ExternalFlowType.payment);
    } else {
      finishExternalFlow(ExternalFlowType.payment);
    }
    developer.log('[AppLockService] setPaymentFlowActive: $active');
  }

  /// Flag indicating VKYC flow is active
  void setVkycFlowActive(bool active) {
    if (active) {
      startExternalFlow(ExternalFlowType.vkyc);
    } else {
      finishExternalFlow(ExternalFlowType.vkyc);
    }
    developer.log('[AppLockService] setVkycFlowActive: $active');
  }

  /// Checks whether app lock should trigger when backgrounded:
  /// Only activates when the user is logged in and no external secure flow is active.
  bool get canAppLock {
    // Developer test mode: bypass all guards so lock triggers on any screen
    if (_storage.read<bool>('app_lock_test_mode') == true) {
      return true;
    }

    // Disabled explicitly by setting (Defaults to false)
    final enabled = isAppLockEnabled;
    if (!enabled) return false;

    // Media picker, payment flow, VKYC flow, or any other external secure flow active
    if (isExternalFlowActive()) return false;

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
        // On iOS, 'inactive' fires for transient interruptions (notification center
        // pull-down, Control Center swipe, incoming calls) that never reach 'paused'.
        // Starting the lock timer here would cause false-locks during those gestures.
        // We only record the timestamp without starting the timer; the 'paused' /
        // 'hidden' cases below start the actual timer when the app is truly backgrounded.
        // Native biometric dialogs also trigger 'inactive' — skip entirely when active.
        if (!isBiometricActive && canAppLock) {
          if (!_isBackgrounded || _pausedTimestamp == null) {
            _isBackgrounded = true;
            _pausedTimestamp = DateTime.now();
            developer.log(
              '[AppLockService] App inactive at: $_pausedTimestamp. Timestamp recorded (no timer yet).',
            );
          }
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
      if (activeExternalFlows.contains(ExternalFlowType.externalBrowser)) {
        developer.log(
          '[AppLockService] Resumed from externalBrowser. Re-enabling lock protection shortly.',
        );
        Future.delayed(const Duration(milliseconds: 1500), () {
          finishExternalFlow(ExternalFlowType.externalBrowser);
        });
      }
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
      // Prioritize live backend API verification
      if (Get.isRegistered<ApiService>()) {
        final result = await ApiService.to.verifyMpin(pinToVerify);
        if (result.isSuccess) {
          HapticFeedback.mediumImpact();
          unlock();
          return true;
        } else if (result.message.isNotEmpty &&
            !result.message.toLowerCase().contains('connection') &&
            !result.message.toLowerCase().contains('network')) {
          HapticFeedback.heavyImpact();
          pinError.value = result.message;
          enteredPin.value = '';
          return false;
        }
      }

      // Offline fallback: Match against locally stored MPIN
      final savedMpin =
          _storage.read<String>('saved_mpin') ??
          _storage.read('mpin')?.toString();
      if (savedMpin != null && savedMpin == pinToVerify) {
        HapticFeedback.mediumImpact();
        unlock();
        return true;
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

    // Disable App Lock upon logout and flag to prompt on next login
    setAppLockEnabled(false);
    await _storage.write('app_lock_enabled', false);
    await _storage.write('pending_app_lock_prompt', true);

    // Clear user session
    if (Get.isRegistered<AuthService>()) {
      await AuthService.to.logout();
    }
    await _storage.remove('auth_token');
    await _storage.remove('accessToken');
    await _storage.remove('refreshToken');
    await _storage.remove('is_logged_in');

    if (Get.isRegistered<LoginSingupscreenController>()) {
      Get.find<LoginSingupscreenController>().closeOtpPopupOnly();
    }

    AppSnackbar.info("Logged out successfully");
    Get.offAllNamed('/login_singupview');
  }

  /// Displays a dialog prompting the user to enable App Lock after logging in
  void showEnableAppLockDialog(BuildContext context) {
    if (isAppLockEnabled) return;
    if (Get.isDialogOpen ?? false) return;

    Get.dialog(
      Builder(
        builder: (dialogCtx) {
          void dismissDialog() {
            try {
              if (Navigator.of(dialogCtx, rootNavigator: true).canPop()) {
                Navigator.of(dialogCtx, rootNavigator: true).pop();
              } else if (Get.isDialogOpen ?? false) {
                Get.until((route) => !Get.isDialogOpen!);
              }
            } catch (e) {
              developer.log('[AppLockService] Error dismissing dialog: $e');
              if (Get.isDialogOpen ?? false) {
                Get.back(closeOverlays: true);
              }
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: primaryRed.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: primaryRed,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Enable App Lock?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Keep your Transcorp Wallet secure. When enabled, your app locks automatically when minimized, protecting your balances and transactions.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildFeatureHighlight(
                        icon: Icons.shield_outlined,
                        text: "Auto-lock when the app is minimized",
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureHighlight(
                        icon: Icons.fingerprint_rounded,
                        text: "Fast unlock with Biometrics or MPIN",
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureHighlight(
                        icon: Icons.visibility_off_outlined,
                        text: "Protects sensitive cards and payment data",
                      ),
                      const SizedBox(height: 22),
                      CustomButton(
                        text: "Enable App Lock",
                        btncolor: primaryRed,
                        borderRadius: 14,
                          textsize: context.responsive(14),
                        onPressed: () {
                          setAppLockEnabled(true);
                          clearAllExternalFlows();
                          _storage.write('app_lock_enabled', true);
                          _storage.write('pending_app_lock_prompt', false);
                          if (Get.isRegistered<ProfilescreenController>()) {
                            Get.find<ProfilescreenController>()
                                    .appLockEnabled
                                    .value =
                                true;
                          }
                          dismissDialog();
                          Future.delayed(
                            const Duration(milliseconds: 350),
                            () => AppSnackbar.success(
                              "App Lock has been enabled.",
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setAppLockEnabled(false);
                          _storage.write('app_lock_enabled', false);
                          _storage.write('pending_app_lock_prompt', false);
                          if (Get.isRegistered<ProfilescreenController>()) {
                            Get.find<ProfilescreenController>()
                                    .appLockEnabled
                                    .value =
                                false;
                          }
                          dismissDialog();
                        },
                        child: Text(
                          "Not Now",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.black54,
                      size: 22,
                    ),
                    onPressed: () {
                      _storage.write('pending_app_lock_prompt', false);
                      dismissDialog();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildFeatureHighlight({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
