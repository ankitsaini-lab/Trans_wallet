import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:transwallet/products/login_singupscreen/login_singupscreen_Controller.dart';
import 'package:transwallet/products/Dashboard screen/dashboardscreen_Controller.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/products/Profile screen/change_pin/forgot_pin_view.dart';

enum ExternalFlowType {
  none,
  payment, // PayU Checkout / Payment Gateway
  vkyc, // VKYC WebView, camera/video, redirect/callback
  mediaPicker, // Camera / Gallery picker
  customWebview, // Approved secure WebView
  externalBrowser, // External browser URL flow
  forgotPin, // Forgot MPIN flow
}

/// Service that monitors application lifecycle and locks the app
/// after being backgrounded for at least 2 seconds.
class AppLockService extends GetxService with WidgetsBindingObserver {
  static AppLockService get to => Get.find<AppLockService>();

  final GetStorage _storage = GetStorage();

  /// Lock state observable
  final RxBool isLocked = false.obs;

  /// Observable indicating user is resetting MPIN from the lock screen
  final RxBool isResettingPinFromLock = false.obs;

  /// Input MPIN entered on lock screen
  final RxString enteredPin = ''.obs;

  /// Error message on lock screen (dynamic from API response)
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

  /// Returns whether App Lock is enabled (App Lock is always ON for logged-in users)
  bool get isAppLockEnabled => isUserLoggedIn;

  /// Toggles App Lock setting (App Lock is always ON for logged in users)
  void setAppLockEnabled(bool enabled) {
    developer.log(
      '[AppLockService] App Lock is permanently enabled for logged in users.',
    );
  }

  DateTime? _pausedTimestamp;
  Timer? _backgroundTimer;
  Timer? _errorClearTimer;
  bool _isBackgrounded = false;
  bool _isTrulyBackgrounded = false;

  /// Debug observable tracking the last measured background duration in ms
  final RxInt lastElapsedMs = 0.obs;

  DateTime? get pausedTimestamp => _pausedTimestamp;
  bool get isBackgrounded => _isBackgrounded;

  /// Centralized set of active external secure flow types
  final RxSet<ExternalFlowType> activeExternalFlows = <ExternalFlowType>{}.obs;

  /// Completely resets all lock states, timers, and flow states upon logout or session expiry
  void resetForLogout() {
    _backgroundTimer?.cancel();
    _errorClearTimer?.cancel();
    _pausedTimestamp = null;
    _isBackgrounded = false;
    _isTrulyBackgrounded = false;
    isLocked.value = false;
    isManualMpin.value = false;
    biometricFailedAttempts.value = 0;
    _isColdStart = false;
    clearPin();
    clearMpinLockout();
    clearAllExternalFlows();
  }

  Future<AppLockService> init() async {
    // Purge any stale lockout keys from storage so every entry calls live API
    clearMpinLockout();
    WidgetsBinding.instance.addObserver(this);
    if (canAppLock && isUserLoggedIn) {
      developer.log(
        '[AppLockService] Initialized from cold start for logged in user.',
      );
      _isColdStart = true;
    } else {
      _isColdStart = false;
    }
    return this;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundTimer?.cancel();
    _errorClearTimer?.cancel();
    super.onClose();
  }

  /// Start an external secure flow (Payment, VKYC, MediaPicker, etc.)
  void startExternalFlow(ExternalFlowType flow) {
    if (flow == ExternalFlowType.none) return;
    activeExternalFlows.add(flow);
    _backgroundTimer?.cancel();
    _pausedTimestamp = null;
    _isBackgrounded = false;
    _isTrulyBackgrounded = false;
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
    _isTrulyBackgrounded = false;
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
    _isTrulyBackgrounded = false;
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

  /// Checks whether biometric authentication is turned on from the profile menu
  bool get isBiometricEnabledFromProfile => false;

  /// Checks whether biometric authentication is available and enabled on device
  bool get isBiometricAvailable => false;

  /// Checks whether biometric hardware is physically supported and enrolled on device
  bool get isBiometricHardwareSupported => false;

  /// User manually requested to switch to MPIN screen
  final RxBool isManualMpin = true.obs;

  /// Returns true when MPIN should be shown exclusively:
  bool get shouldShowMpinOnly => true;

  /// Switch view to manual MPIN keypad
  void switchToMpin() {
    _resetPinInput();
  }

  /// Switch view back to Face Lock / Biometric screen
  void switchToBiometrics() {}

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

    // App Lock is always ON for logged-in users
    if (!isUserLoggedIn) return false;

    // Media picker, payment flow, VKYC flow, or any other external secure flow active
    if (isExternalFlowActive()) return false;

    return true;
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
          _isTrulyBackgrounded = true;
          _handleBackgrounded();
        }
        break;

      case AppLifecycleState.inactive:
        // On iOS and Android, 'inactive' fires for transient system UI interruptions
        // such as opening the mobile status bar / notification shade / quick settings,
        // Control Center swipe, volume adjustments, or incoming call previews.
        // The app is still visible in foreground and has NOT been backgrounded or hidden.
        // Do NOT set background timestamps, start timers, or lock the app for status bar interactions!
        developer.log(
          '[AppLockService] App inactive (status bar / notification shade / overlay). Skipping lock.',
        );
        break;

      case AppLifecycleState.resumed:
        _handleResumed();
        break;

      case AppLifecycleState.detached:
        break;
    }
  }

  /// Triggered when app enters background (paused or hidden)
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
        '[AppLockService] App backgrounded at: $_pausedTimestamp. ${backgroundLockDuration.inSeconds}s timer started.',
      );

      _backgroundTimer?.cancel();
      _backgroundTimer = Timer(backgroundLockDuration, () {
        if (canAppLock && !isLocked.value && _isTrulyBackgrounded) {
          developer.log(
            '[AppLockService] Background duration >= ${backgroundLockDuration.inSeconds}s reached while in background. Locking app.',
          );
          isLocked.value = true;
          isManualMpin.value = false;
          biometricFailedAttempts.value = 0;
          _resetPinInput();
        }
      });
    }
  }

  /// Triggered when app returns to foreground
  void _handleResumed() {
    final pausedAt = _pausedTimestamp;
    final wasTrulyBackgrounded = _isTrulyBackgrounded;

    _pausedTimestamp = null;
    _isBackgrounded = false;
    _isTrulyBackgrounded = false;
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

    // If the app was not truly backgrounded (e.g. only inactive from pulling down the mobile status bar),
    // do NOT lock the app.
    if (!wasTrulyBackgrounded || pausedAt == null) {
      developer.log(
        '[AppLockService] Resumed without being truly backgrounded (e.g. status bar was opened). Skipping lock.',
      );
      return;
    }

    final elapsed = DateTime.now().difference(pausedAt);
    lastElapsedMs.value = elapsed.inMilliseconds;
    developer.log(
      '[AppLockService] Resumed after elapsed: ${elapsed.inMilliseconds}ms (threshold: ${backgroundLockDuration.inMilliseconds}ms)',
    );

    if (elapsed >= backgroundLockDuration) {
      // Exceeded threshold -> lock app
      developer.log(
        '[AppLockService] Elapsed >= ${backgroundLockDuration.inSeconds}s (${elapsed.inMilliseconds}ms). Locking app now!',
      );
      isLocked.value = true;
      isManualMpin.value = true;
      biometricFailedAttempts.value = 0;
      _resetPinInput();
    }
  }

  /// Manually trigger app lock (e.g. user action or test)
  void lockApp() {
    isLocked.value = true;
    isManualMpin.value = true;
    biometricFailedAttempts.value = 0;
    _resetPinInput();
  }

  bool _isColdStart = true;
  bool get isColdStart => _isColdStart;

  void clearColdStart() {
    _isColdStart = false;
  }

  /// Locks the app immediately upon cold-start navigation to protected screens
  void lockForColdStart() {
    if (!canAppLock) return;
    developer.log(
      '[AppLockService] Cold start lock triggered for logged-in user.',
    );
    _isColdStart = false;
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
    _isTrulyBackgrounded = false;
    isLocked.value = false;
    isManualMpin.value = false;
    biometricFailedAttempts.value = 0;
    _isColdStart = false;
    _resetPinInput();

    // If pending biometric/app lock setup prompt is waiting after login, trigger after unlock
    if (Get.isRegistered<DashboardscreenController>()) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!isLocked.value && Get.isRegistered<DashboardscreenController>()) {
          Get.find<DashboardscreenController>().checkAppLockPrompt();
        }
      });
    }
  }

  void _resetPinInput() {
    _errorClearTimer?.cancel();
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

  /// Consecutive incorrect manual MPIN entries
  final RxInt mpinFailedAttempts = 0.obs;

  /// Checks whether MPIN is currently under a temporary lockout.
  /// Always returns false so every MPIN entry calls the live backend API.
  bool get isMpinTemporarilyLocked => false;

  /// User full name from live profile / login API response
  String get dynamicUserName {
    final name =
        _storage.read<String>('name') ??
        _storage.read<String>('firstName') ??
        _storage.read<String>('remembered_name') ??
        '';
    return name.trim();
  }

  /// Registered phone number from live profile / login API response
  String get dynamicUserPhone {
    final phone =
        _storage.read<String>('phone') ??
        _storage.read<String>('mobileNumber') ??
        _storage.read<String>('remembered_phone') ??
        '';
    return phone.trim();
  }

  /// Dynamic profile picture URL from API response
  String get dynamicProfilePicUrl {
    final url = _storage.read<String>('profilePictureUrl') ?? '';
    return url.trim();
  }

  /// Formatted masked phone number (e.g., +91 98•••• 1234)
  String get maskedPhone {
    final p = dynamicUserPhone.replaceAll(RegExp(r'\D'), '');
    if (p.length >= 10) {
      final last4 = p.substring(p.length - 4);
      final first2 = p.substring(p.length - 10, p.length - 8);
      return '+91 $first2•••• $last4';
    }
    return dynamicUserPhone;
  }

  /// Dynamic message explaining remaining lockout time from API response
  String get mpinLockoutMessage => pinError.value;

  /// Records temporary MPIN lockout without writing to local storage so every entry calls API
  void recordMpinLockout(
    String message, {
    dynamic lockData,
    Duration defaultDuration = const Duration(minutes: 15),
  }) {
    pinError.value = message;
    developer.log(
      '[AppLockService] API indicated MPIN lockout: $message (not stored locally)',
    );
  }

  /// Clears active MPIN lockout
  void clearMpinLockout() {
    _storage.remove('mpin_locked_until');
    _storage.remove('mpin_lock_message');
    _storage.remove('is_temporarily_blocked');
    mpinFailedAttempts.value = 0;
  }

  /// Biometrics has been disabled throughout the application
  Future<bool> promptBiometricUnlock() async {
    return false;
  }

  /// Handles digit entry on the custom numeric keypad
  void onKeyTap(String digit) {
    if (isVerifyingPin.value) return;

    _errorClearTimer?.cancel();

    // If an error was showing, tapping any digit clears previous input and starts fresh
    if (pinError.value.isNotEmpty) {
      pinError.value = '';
      enteredPin.value = '';
    }

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
    _errorClearTimer?.cancel();
    if (isVerifyingPin.value) {
      isVerifyingPin.value = false;
    }

    HapticFeedback.lightImpact();
    pinError.value = '';

    if (enteredPin.value.isNotEmpty) {
      enteredPin.value = enteredPin.value.substring(
        0,
        enteredPin.value.length - 1,
      );
    }
  }

  /// Clears the entire entered PIN and any error
  void clearPin() {
    _errorClearTimer?.cancel();
    isVerifyingPin.value = false;
    pinError.value = '';
    enteredPin.value = '';
    HapticFeedback.mediumImpact();
  }

  /// Opens the Forgot MPIN screen directly within the lock overlay without routing through the underlying screen
  void openForgotPinScreen() {
    _resetPinInput();
    startExternalFlow(ExternalFlowType.forgotPin);
    isResettingPinFromLock.value = true;
  }

  /// Handles successful MPIN reset from the lock screen
  void onForgotPinSuccessFromLock() {
    clearMpinLockout();
    _resetPinInput();
    isResettingPinFromLock.value = false;
    finishExternalFlow(ExternalFlowType.forgotPin);
    isLocked.value = true;
    isManualMpin.value = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      AppSnackbar.success(
        "MPIN reset successfully. Enter your new MPIN to unlock.",
      );
    });
  }

  /// Handles cancellation or back navigation from Forgot MPIN screen
  void onForgotPinCancelFromLock() {
    clearMpinLockout();
    _resetPinInput();
    isResettingPinFromLock.value = false;
    finishExternalFlow(ExternalFlowType.forgotPin);
    isLocked.value = true;
    isManualMpin.value = true;
  }

  /// Verifies entered MPIN against stored MPIN or API backend
  Future<bool> verifyMpin(String pinToVerify) async {
    _errorClearTimer?.cancel();

    isVerifyingPin.value = true;
    pinError.value = '';

    try {
      // Prioritize live backend API verification
      if (Get.isRegistered<ApiService>()) {
        final result = await ApiService.to.verifyMpin(pinToVerify);
        if (result.isSuccess) {
          HapticFeedback.mediumImpact();
          clearMpinLockout();
          unlock();
          return true;
        } else {
          HapticFeedback.heavyImpact();
          // Always use dynamic message from API response
          final String dynamicMsg = result.message.isNotEmpty
              ? result.message
              : 'Invalid MPIN. Please try again.';

          pinError.value = dynamicMsg;
          enteredPin.value = pinToVerify;

          _errorClearTimer?.cancel();
          _errorClearTimer = Timer(const Duration(milliseconds: 1500), () {
            if (enteredPin.value == pinToVerify && pinError.value.isNotEmpty) {
              enteredPin.value = '';
              pinError.value = '';
            }
          });
          return false;
        }
      }

      // Offline fallback: Match against locally stored MPIN
      final savedMpin =
          _storage.read<String>('saved_mpin') ??
          _storage.read('mpin')?.toString();
      if (savedMpin != null && savedMpin == pinToVerify) {
        HapticFeedback.mediumImpact();
        clearMpinLockout();
        unlock();
        return true;
      }

      // If all checks fail -> dynamic error message
      HapticFeedback.heavyImpact();
      pinError.value = 'Invalid MPIN. Please try again.';
      enteredPin.value = pinToVerify;

      _errorClearTimer?.cancel();
      _errorClearTimer = Timer(const Duration(milliseconds: 1500), () {
        if (enteredPin.value == pinToVerify && pinError.value.isNotEmpty) {
          enteredPin.value = '';
          pinError.value = '';
        }
      });
      return false;
    } catch (e) {
      developer.log('[AppLockService] MPIN verification exception: $e');
      pinError.value = e.toString().contains('SocketException')
          ? 'Network error. Please check your internet connection.'
          : e.toString();
      enteredPin.value = pinToVerify;

      _errorClearTimer?.cancel();
      _errorClearTimer = Timer(const Duration(milliseconds: 1500), () {
        if (enteredPin.value == pinToVerify && pinError.value.isNotEmpty) {
          enteredPin.value = '';
          pinError.value = '';
        }
      });
      return false;
    } finally {
      isVerifyingPin.value = false;
    }
  }

  /// Emergency log out in case user forgot both biometrics and MPIN or taps Log Out on lock screen
  Future<void> logoutAndReset() async {
    if (Get.isRegistered<AuthService>() && AuthService.to.isLoggingOut) {
      return;
    }

    developer.log('[AppLockService] logoutAndReset initiated');

    _backgroundTimer?.cancel();
    _pausedTimestamp = null;
    _isBackgrounded = false;
    _isTrulyBackgrounded = false;
    biometricFailedAttempts.value = 0;
    _resetPinInput();

    if (Get.isRegistered<AuthService>()) {
      await AuthService.to.logout(navigateToLogin: true);
    } else {
      Get.offAllNamed('/login_singupview');
    }

    isLocked.value = false;
    isResettingPinFromLock.value = false;
    setAppLockEnabled(false);
    resetForLogout();

    AppSnackbar.info("Logged out successfully");
  }

  /// Displays a dialog prompting the user to enable Biometric & App Lock after logging in
  void showEnableAppLockDialog(BuildContext context) {
    return;
  }
}
